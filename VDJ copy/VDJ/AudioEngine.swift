//
//  AudioEngine.swift
//  VDJ
//
//  Enhanced Audio Engine with Real-time Analysis
//

import Foundation
import AVFoundation
import Accelerate

class AudioEngine: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var mixer = AVAudioMixerNode()
    private var fftSetup: FFTSetup?
    private var fftBuffer: [Float] = []
    private let fftSize = 1024
    
    @Published var frequencyData: [Float] = Array(repeating: 0, count: 512)
    @Published var amplitude: Float = 0
    @Published var bassLevel: Float = 0
    @Published var midLevel: Float = 0
    @Published var trebleLevel: Float = 0
    @Published var beatDetected: Bool = false
    @Published var bpm: Float = 0
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7 {
        didSet {
            mixer.outputVolume = volume
        }
    }
    
    private var beatDetector = BeatDetector()
    private var analysisTimer: Timer?
    private var audioFile: AVAudioFile?
    
    init() {
        setupAudioEngine()
        setupFFT()
        startAnalysis()
    }
    
    deinit {
        stop()
        analysisTimer?.invalidate()
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(mixer)
        
        audioEngine.connect(playerNode, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
        
        // Install tap for real-time analysis
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        mixer.installTap(onBus: 0, bufferSize: UInt32(fftSize), format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func setupFFT() {
        fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(fftSize))), FFTRadix(kFFTRadix2))
        fftBuffer = Array(repeating: 0, count: fftSize)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData,
              let setup = fftSetup else { return }
        
        let frameCount = Int(buffer.frameLength)
        let leftChannel = channelData[0]
        
        // Copy audio data to FFT buffer
        for i in 0..<min(frameCount, fftSize) {
            fftBuffer[i] = leftChannel[i]
        }
        
        // Perform FFT
        var real = [Float](repeating: 0, count: fftSize/2)
        var imaginary = [Float](repeating: 0, count: fftSize/2)
        
        real.withUnsafeMutableBufferPointer { realPtr in
            imaginary.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                
                fftBuffer.withUnsafeMutableBufferPointer { bufferPointer in
                    guard let bufferBase = bufferPointer.baseAddress else { return }
                    
                    vDSP_ctoz(UnsafePointer<DSPComplex>(OpaquePointer(bufferBase)), 2,
                             &splitComplex, 1, vDSP_Length(fftSize/2))
                    
                    vDSP_fft_zrip(setup, &splitComplex, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))
                    
                    // Calculate magnitude spectrum
                    var magnitudes = [Float](repeating: 0, count: fftSize/2)
                    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize/2))
                    
                    DispatchQueue.main.async {
                        self.updateFrequencyData(magnitudes)
                    }
                }
            }
        }
        
        // Beat detection
        let currentAmplitude = calculateRMS(leftChannel, frameCount: frameCount)
        beatDetector.processSample(amplitude: currentAmplitude)
        
        DispatchQueue.main.async {
            self.amplitude = currentAmplitude
            self.beatDetected = self.beatDetector.beatDetected
            self.bpm = self.beatDetector.currentBPM
        }
    }
    
    private func updateFrequencyData(_ magnitudes: [Float]) {
        // Smooth the frequency data and extract frequency bands
        let smoothingFactor: Float = 0.3
        
        for i in 0..<min(magnitudes.count, frequencyData.count) {
            frequencyData[i] = frequencyData[i] * (1 - smoothingFactor) + 
                              sqrt(magnitudes[i]) * smoothingFactor
        }
        
        // Extract frequency bands
        let bassRange = 0..<50
        let midRange = 50..<200
        let trebleRange = 200..<frequencyData.count
        
        bassLevel = frequencyData[bassRange].reduce(0, +) / Float(bassRange.count)
        midLevel = frequencyData[midRange].reduce(0, +) / Float(midRange.count)
        trebleLevel = frequencyData[trebleRange].reduce(0, +) / Float(trebleRange.count)
    }
    
    private func calculateRMS(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(frameCount))
        return rms
    }
    
    private func startAnalysis() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }
    }
    
    private func updatePlaybackTime() {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              let audioFile = audioFile else { return }
        
        let sampleRate = audioFile.processingFormat.sampleRate
        currentTime = Double(playerTime.sampleTime) / sampleRate
        duration = Double(audioFile.length) / sampleRate
    }
    
    func loadAudioFile(url: URL) {
        do {
            audioFile = try AVAudioFile(forReading: url)
            guard let audioFile = audioFile else { return }
            
            playerNode.scheduleFile(audioFile, at: nil)
            duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
    
    func play() {
        guard !isPlaying else { return }
        playerNode.play()
        isPlaying = true
    }
    
    func pause() {
        playerNode.pause()
        isPlaying = false
    }
    
    func stop() {
        playerNode.stop()
        isPlaying = false
        currentTime = 0
    }
    
    func seek(to time: TimeInterval) {
        guard let audioFile = audioFile else { return }
        
        let sampleRate = audioFile.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(time * sampleRate)
        
        playerNode.stop()
        playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: AVAudioFrameCount(audioFile.length - startFrame), at: nil)
        
        if isPlaying {
            playerNode.play()
        }
    }
}

// MARK: - Beat Detection
class BeatDetector {
    private var energyHistory: [Float] = []
    private let historySize = 43 // ~1 second at 43 FPS
    private var lastBeatTime: TimeInterval = 0
    private let minBeatInterval: TimeInterval = 0.3
    private var beatTimes: [TimeInterval] = []
    
    var beatDetected: Bool = false
    var currentBPM: Float = 0
    
    func processSample(amplitude: Float) {
        let energy = amplitude * amplitude
        energyHistory.append(energy)
        
        if energyHistory.count > historySize {
            energyHistory.removeFirst()
        }
        
        // Simple beat detection algorithm
        if energyHistory.count >= historySize {
            let averageEnergy = energyHistory.reduce(0, +) / Float(energyHistory.count)
            let variance = energyHistory.map { pow($0 - averageEnergy, 2) }.reduce(0, +) / Float(energyHistory.count)
            let threshold = averageEnergy + sqrt(variance) * 1.5
            
            let currentTime = CACurrentMediaTime()
            
            if energy > threshold && (currentTime - lastBeatTime) > minBeatInterval {
                beatDetected = true
                lastBeatTime = currentTime
                
                // Update BPM calculation
                beatTimes.append(currentTime)
                if beatTimes.count > 8 {
                    beatTimes.removeFirst()
                }
                
                if beatTimes.count >= 2 {
                    let intervals = zip(beatTimes.dropFirst(), beatTimes).map { $0.0 - $0.1 }
                    let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
                    currentBPM = Float(60.0 / averageInterval)
                }
            } else {
                beatDetected = false
            }
        }
    }
}
