import SwiftUI
import AVKit
import AVFoundation
import MediaPlayer
import CoreImage
import CoreImage.CIFilterBuiltins
import MetalKit
import SceneKit

struct ContentView: View {
    @State private var selectedVisualization: VisualizationType = .coreImage
    @State private var selectedEffect: CoreImageEffect = .bloom
    @State private var selectedShader: MetalShader = .kaleidoscope
    @State private var selectedScene: SceneKitScene = .particles
    @State private var isPlaying = false
    @State private var trackProgress: CGFloat = 0.3
    @State private var volume: CGFloat = 0.7
    @State private var currentTrack: String = "Neon Dreams"
    @State private var currentArtist: String = "Electronic Vibes"
    @State private var currentTime: String = "3:45"
    @State private var totalTime: String = "5:20"
    @State private var showMediaPicker = false
    @State private var audioPlayer: AVAudioPlayer?
    
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var hapticManager: HapticFeedbackManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background animation based on frequency data
                VisualizerView(frequencyData: $audioEngine.frequencyData)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Title with BPM animation
                    Text("VDJ")
                        .font(.system(size: min(geometry.size.width * 0.1, 42), weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                        .shadow(color: .blue, radius: 10, x: 0, y: 0)
                        .scaleEffect(1 + 0.05 * CGFloat(audioEngine.beatDetected ? 1 : 0))
                        .animation(.easeInOut(duration: 0.1), value: audioEngine.beatDetected)
                        
                    // Visualization Area
                    ZStack {
                        switch selectedVisualization {
                        case .coreImage:
                            CoreImageView(effect: $selectedEffect)
                        case .metal:
                            MetalShaderView(shader: $selectedShader)
                        case .sceneKit:
                            SceneKitVisualization(scene: $selectedScene)
                        }
                        
                        // Overlay BPM and audio info
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("BPM: \(Int(audioEngine.bpm))")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                    
                                    AudioLevelsView(
                                        bassLevel: audioEngine.bassLevel,
                                        midLevel: audioEngine.midLevel,
                                        trebleLevel: audioEngine.trebleLevel
                                    )
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    .frame(height: min(geometry.size.height * 0.45, geometry.size.width * 0.8))
                    .cornerRadius(min(geometry.size.width * 0.05, 20))
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.top, 15)
                    .shadow(color: .blue.opacity(0.7), radius: 20, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: min(geometry.size.width * 0.05, 20))
                            .stroke(audioEngine.beatDetected ? Color.red : Color.clear, lineWidth: 3)
                            .animation(.easeInOut(duration: 0.1), value: audioEngine.beatDetected)
                    )
                
                    // Visualization Type Selector
                    Picker("Visualization", selection: $selectedVisualization) {
                        Text("Core Image").tag(VisualizationType.coreImage)
                        Text("Metal").tag(VisualizationType.metal)
                        Text("3D Scene").tag(VisualizationType.sceneKit)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.top, 15)
                    
                    // Effect Selectors
                    if selectedVisualization == .coreImage {
                    EffectPicker(effects: CoreImageEffect.allCases, selectedEffect: $selectedEffect, geometry: geometry)
                            .padding(.top, 10)
                            .environmentObject(hapticManager) // Ensure correct environment object
                    } else if selectedVisualization == .metal {
                        EffectPicker(effects: MetalShader.allCases, selectedEffect: $selectedShader, geometry: geometry)
                            .padding(.top, 10)
                            .environmentObject(hapticManager)
                    } else {
                        EffectPicker(effects: SceneKitScene.allCases, selectedEffect: $selectedScene, geometry: geometry)
                            .padding(.top, 10)
                            .environmentObject(hapticManager)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Player Controls
                    PlayerControlsView(
                        isPlaying: $isPlaying,
                        trackProgress: $trackProgress,
                        volume: $volume,
                        currentTrack: $currentTrack,
                        currentArtist: $currentArtist,
                        currentTime: $currentTime,
                        totalTime: $totalTime,
                        showMediaPicker: $showMediaPicker,
                        geometry: geometry
                    )
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
        .sheet(isPresented: $showMediaPicker) {
            MediaPickerView(audioPlayer: $audioPlayer, isPlaying: $isPlaying)
        }
        .onChange(of: audioEngine.beatDetected) { newValue in
            if newValue {
                hapticManager.beatHaptic()
            }
        }
    }
}

// MARK: - Visualization Types
enum VisualizationType: String, CaseIterable {
    case coreImage = "Core Image"
    case metal = "Metal"
    case sceneKit = "3D Scene"
}

// MARK: - Core Image Effects
enum CoreImageEffect: String, CaseIterable {
    case bloom = "Bloom"
    case crystallize = "Crystallize"
    case motionBlur = "Motion Blur"
    case kaleidoscope = "Kaleidoscope"
    case colorInvert = "Color Invert"
    case pointillize = "Pointillize"
}

// MARK: - Metal Shaders
enum MetalShader: String, CaseIterable {
    case kaleidoscope = "Kaleidoscope"
    case audioWave = "Audio Wave"
    case voronoi = "Voronoi"
    case plasma = "Plasma"
    case ripple = "Ripple"
}

// MARK: - SceneKit Scenes
enum SceneKitScene: String, CaseIterable {
    case particles = "Particles"
    case cubeField = "Cube Field"
    case audioReactive = "Audio Reactive"
    case tunnel = "Tunnel"
}

// MARK: - Effect Picker
struct EffectPicker<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let effects: [T]
    @Binding var selectedEffect: T
    let geometry: GeometryProxy
    @EnvironmentObject var hapticManager: HapticFeedbackManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: geometry.size.width * 0.03) {
                ForEach(effects, id: \.self) { effect in
                    Text(effect.rawValue)
                        .font(.system(size: min(geometry.size.width * 0.035, 14), weight: .medium))
                        .padding(.vertical, 8)
                        .padding(.horizontal, geometry.size.width * 0.035)
                        .background(selectedEffect == effect ? Color.blue : Color(white: 0.2))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .onTapGesture {
                            hapticManager.selectionHaptic()
                            withAnimation(.spring()) {
                                selectedEffect = effect
                            }
                        }
                }
            }
            .padding(.horizontal, geometry.size.width * 0.05)
        }
    }
}

// MARK: - Core Image Visualization
struct CoreImageView: UIViewRepresentable {
    @Binding var effect: CoreImageEffect
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tag = 100
        view.addSubview(imageView)
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Start generating images
        context.coordinator.startGenerating(for: imageView, effect: effect)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.effect = effect
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        var parent: CoreImageView
        var effect: CoreImageEffect
        var timer: Timer?
        
        init(_ parent: CoreImageView) {
            self.parent = parent
            self.effect = parent.effect
        }
        
        func startGenerating(for imageView: UIImageView, effect: CoreImageEffect) {
            timer?.invalidate() // Clean up existing timer
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let image = self.generateCoreImageEffect(effect: self.effect)
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
        
        deinit {
            timer?.invalidate()
        }
        
        func generateCoreImageEffect(effect: CoreImageEffect) -> UIImage? {
            let size = CGSize(width: 1000, height: 1000)
            let center = CGPoint(x: size.width/2, y: size.height/2)
            
            let ciImage: CIImage
            
            switch effect {
            case .bloom:
                let grad = CIFilter.linearGradient()
                grad.point0 = CGPoint(x: 0, y: size.height)  // Fixed: Use CGPoint
                grad.point1 = CGPoint(x: size.width, y: 0)   // Fixed: Use CGPoint
                grad.color0 = CIColor(red: 1, green: 0, blue: 0, alpha: 1)
                grad.color1 = CIColor(red: 0, green: 0, blue: 1, alpha: 1)
                let gradImage = grad.outputImage ?? CIImage()
                
                let bloom = CIFilter.bloom()
                bloom.inputImage = gradImage
                bloom.radius = 10 + 5 * Float(sin(Date().timeIntervalSince1970))
                bloom.intensity = 1
                ciImage = bloom.outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ?? gradImage
                
            case .crystallize:
                let baseImage = CIImage(color: CIColor(red: 0, green: 0.5, blue: 1, alpha: 1))
                    .cropped(to: CGRect(origin: .zero, size: size))
                let crystallize = CIFilter.crystallize()
                crystallize.inputImage = baseImage
                crystallize.radius = 15 + 10 * Float(sin(Date().timeIntervalSince1970 * 0.5))
                crystallize.center = center  // Fixed: Use CGPoint
                ciImage = crystallize.outputImage ?? baseImage
                
            case .motionBlur:
                let noise = CIFilter.randomGenerator().outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ?? CIImage()
                let motion = CIFilter.motionBlur()
                motion.inputImage = noise
                motion.radius = 20 + 15 * Float(sin(Date().timeIntervalSince1970 * 0.3))
                motion.angle = Float(Date().timeIntervalSince1970)
                ciImage = motion.outputImage ?? noise
                
            case .kaleidoscope:
                let pattern = generateColorfulPattern(size: size)
                let kaleido = CIFilter.kaleidoscope()
                kaleido.inputImage = pattern
                kaleido.count = 8 + Int(6 * sin(Date().timeIntervalSince1970 * 0.2))
                kaleido.center = center  // Fixed: Use CGPoint
                kaleido.angle = Float(Date().timeIntervalSince1970 * 0.5)
                ciImage = kaleido.outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ?? pattern
                
            case .colorInvert:
                let pattern = generateColorfulPattern(size: size)
                let invert = CIFilter.colorInvert()
                invert.inputImage = pattern
                ciImage = invert.outputImage ?? pattern
                
            case .pointillize:
                let pattern = generateColorfulPattern(size: size)
                let point = CIFilter.pointillize()
                point.inputImage = pattern
                point.radius = 20 + 15 * Float(cos(Date().timeIntervalSince1970 * 0.4))
                point.center = center  // Fixed: Use CGPoint
                ciImage = point.outputImage ?? pattern
            }
            
            // Convert to UIImage
            let context = CIContext(options: nil)
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }
        
        func generateColorfulPattern(size: CGSize) -> CIImage {
            let pattern = CIFilter.linearGradient()
            pattern.point0 = CGPoint(x: 0, y: 0)  // Fixed: Use CGPoint
            pattern.point1 = CGPoint(x: size.width, y: size.height)  // Fixed: Use CGPoint
            pattern.color0 = CIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1
            )
            pattern.color1 = CIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1
            )
            let patternImage = pattern.outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ?? CIImage()
            
            let noise = CIFilter.randomGenerator().outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ?? CIImage()
            
            let blend = CIFilter.multiplyBlendMode()
            blend.inputImage = noise
            blend.backgroundImage = patternImage
            return blend.outputImage ?? patternImage
        }
    }
}

// MARK: - Metal Visualization
struct MetalShaderView: UIViewRepresentable {
    @Binding var shader: MetalShader
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update when shader changes
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalShaderView
        var startTime: Date
        
        init(_ parent: MetalShaderView) {
            self.parent = parent
            self.startTime = Date()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let device = view.device,
                  let commandQueue = device.makeCommandQueue(),
                  let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            
            // Create a simple gradient texture
            let texture = createGradientTexture(for: view)
            
            // Apply shader effect and present
            _ = applyShaderEffect(to: texture, view: view)
            
            // Create render pass descriptor
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            // Create render encoder and present
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.endEncoding()
            }
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        func createGradientTexture(for view: MTKView) -> MTLTexture {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: Int(view.drawableSize.width),
                height: Int(view.drawableSize.height),
                mipmapped: false
            )
            textureDescriptor.usage = [.shaderRead, .shaderWrite]
            guard let texture = view.device?.makeTexture(descriptor: textureDescriptor) else {
                fatalError("Failed to create texture")
            }
            
            // Generate gradient
            let time = Float(Date().timeIntervalSince(startTime))
            for y in 0..<texture.height {
                for x in 0..<texture.width {
                    let r = Float(x) / Float(texture.width)
                    let g = Float(y) / Float(texture.height)
                    let b = (sin(time) + 1) / 2
                    
                    let color = [UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), 255]
                    let region = MTLRegion(origin: MTLOrigin(x: x, y: y, z: 0),
                                          size: MTLSize(width: 1, height: 1, depth: 1))
                    texture.replace(region: region, mipmapLevel: 0, withBytes: color, bytesPerRow: 4)
                }
            }
            
            return texture
        }
        
        func applyShaderEffect(to texture: MTLTexture, view: MTKView) -> MTLTexture {
            // In a real app, this would use Metal shaders
            return texture
        }
    }
}

// MARK: - SceneKit Visualization
struct SceneKitVisualization: UIViewRepresentable {
    @Binding var scene: SceneKitScene
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.isPlaying = true
        
        // Set up the scene
        updateScene(scnView: scnView, sceneType: scene)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        updateScene(scnView: uiView, sceneType: scene)
    }
    
    func updateScene(scnView: SCNView, sceneType: SceneKitScene) {
        let newScene = SCNScene()
        
        switch sceneType {
        case .particles:
            createParticleScene(scene: newScene)
        case .cubeField:
            createCubeFieldScene(scene: newScene)
        case .audioReactive:
            createAudioReactiveScene(scene: newScene)
        case .tunnel:
            createTunnelScene(scene: newScene)
        }
        
        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        newScene.rootNode.addChildNode(cameraNode)
        
        // Add lights
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        newScene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        newScene.rootNode.addChildNode(ambientLightNode)
        
        scnView.scene = newScene
        
        // Animate camera
        let moveAction = SCNAction.moveBy(x: 0, y: 0, z: -20, duration: 8)
        let moveBackAction = SCNAction.moveBy(x: 0, y: 0, z: 20, duration: 8)
        let sequence = SCNAction.sequence([moveAction, moveBackAction])
        cameraNode.runAction(SCNAction.repeatForever(sequence))
    }
    
    func createParticleScene(scene: SCNScene) {
        // Create particle system
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 100
        particleSystem.particleLifeSpan = 5
        particleSystem.particleSize = 0.1
        particleSystem.particleColor = .blue
        particleSystem.emittingDirection = SCNVector3(0, 0.5, 0)
        particleSystem.emitterShape = SCNSphere(radius: 2)
        particleSystem.particleVelocity = 1
        particleSystem.particleColorVariation = SCNVector4(0.5, 0.5, 0.5, 0)
        
        let particleNode = SCNNode()
        particleNode.position = SCNVector3(0, 0, 0)
        particleNode.addParticleSystem(particleSystem)
        scene.rootNode.addChildNode(particleNode)
        
        // Add a rotating sphere
        let sphere = SCNSphere(radius: 1.5)
        sphere.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
        sphere.firstMaterial?.emission.contents = UIColor.blue.withAlphaComponent(0.5)
        
        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)
        
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)
        sphereNode.runAction(SCNAction.repeatForever(rotation))
    }
    
    func createCubeFieldScene(scene: SCNScene) {
        let cubeCount = 100
        let spread: Float = 10.0
        
        for _ in 0..<cubeCount {
            let cube = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.05)
            cube.firstMaterial?.diffuse.contents = UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 0.8
            )
            
            let cubeNode = SCNNode(geometry: cube)
            cubeNode.position = SCNVector3(
                x: Float.random(in: -spread...spread),
                y: Float.random(in: -spread...spread),
                z: Float.random(in: -spread...spread)
            )
            
            scene.rootNode.addChildNode(cubeNode)
            
            // Add rotation animation
            let rotateAction = SCNAction.rotateBy(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                z: CGFloat.random(in: 0...1),
                duration: Double.random(in: 2...5)
            )
            cubeNode.runAction(SCNAction.repeatForever(rotateAction))
        }
    }
    
    func createAudioReactiveScene(scene: SCNScene) {
        let bars = 20
        let spacing: Float = 1.2
        
        for i in 0..<bars {
            let height = Float.random(in: 1...3)
            let box = SCNBox(width: 0.8, height: CGFloat(height), length: 0.8, chamferRadius: 0.1)
            
            let hue = CGFloat(i) / CGFloat(bars)
            box.firstMaterial?.diffuse.contents = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 0.9)
            
            let barNode = SCNNode(geometry: box)
            barNode.position = SCNVector3(
                x: Float(i) * spacing - Float(bars/2) * spacing,
                y: height/2,
                z: 0
            )
            
            scene.rootNode.addChildNode(barNode)
            
            // Add animation
            let moveUp = SCNAction.moveBy(x: 0, y: CGFloat(height * 0.5), z: 0, duration: 0.3)
            moveUp.timingMode = .easeOut
            let moveDown = SCNAction.moveBy(x: 0, y: CGFloat(-height * 0.5), z: 0, duration: 0.7)
            moveDown.timingMode = .easeIn
            let sequence = SCNAction.sequence([moveUp, moveDown])
            barNode.runAction(SCNAction.repeatForever(sequence))
        }
    }
    
    func createTunnelScene(scene: SCNScene) {
        // Create tunnel
        let tunnel = SCNTube(innerRadius: 3, outerRadius: 4, height: 50)
        tunnel.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
        tunnel.firstMaterial?.emission.contents = UIColor.blue
        
        let tunnelNode = SCNNode(geometry: tunnel)
        tunnelNode.position = SCNVector3(0, 0, -25)
        scene.rootNode.addChildNode(tunnelNode)
        
        // Add moving rings
        for i in 0..<10 {
            let ring = SCNTorus(ringRadius: 3.5, pipeRadius: 0.1)
            ring.firstMaterial?.diffuse.contents = UIColor(
                red: CGFloat(i)/10,
                green: 1 - CGFloat(i)/10,
                blue: 1,
                alpha: 1
            )
            
            let ringNode = SCNNode(geometry: ring)
            ringNode.position = SCNVector3(0, 0, -Float(i) * 5)
            scene.rootNode.addChildNode(ringNode)
            
            // Rotate rings
            let rotation = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: Double(i+1) * 2)
            ringNode.runAction(SCNAction.repeatForever(rotation))
            
            // Move along tunnel
            let moveAction = SCNAction.moveBy(x: 0, y: 0, z: 50, duration: Double(i+1) * 5)
            let resetAction = SCNAction.moveBy(x: 0, y: 0, z: -50, duration: 0)
            let sequence = SCNAction.sequence([moveAction, resetAction])
            ringNode.runAction(SCNAction.repeatForever(sequence))
        }
    }
}

// MARK: - Player Controls
struct PlayerControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var trackProgress: CGFloat
    @Binding var volume: CGFloat
    @Binding var currentTrack: String
    @Binding var currentArtist: String
    @Binding var currentTime: String
    @Binding var totalTime: String
    @Binding var showMediaPicker: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: geometry.size.height * 0.02) {
            // Track info
            VStack(spacing: 5) {
                Text(currentTrack)
                    .font(.system(size: min(geometry.size.width * 0.05, 20), weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(currentArtist) • \(currentTime) / \(totalTime)")
                    .font(.system(size: min(geometry.size.width * 0.035, 14)))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            // Progress bar
            GeometryReader { progressGeo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: max(4, geometry.size.height * 0.005))
                    
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                               startPoint: .leading, endPoint: .trailing))
                        .frame(width: progressGeo.size.width * trackProgress, height: max(4, geometry.size.height * 0.005))
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: max(16, geometry.size.width * 0.04), height: max(16, geometry.size.width * 0.04))
                        .offset(x: progressGeo.size.width * trackProgress - max(8, geometry.size.width * 0.02), y: 0)
                        .shadow(color: .blue, radius: 5, x: 0, y: 0)
                }
            }
            .frame(height: max(20, geometry.size.height * 0.025))
            .padding(.horizontal, geometry.size.width * 0.05)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let availableWidth = geometry.size.width * 0.9 // Account for horizontal padding
                        let progress = max(0, min(1, (value.location.x - geometry.size.width * 0.05) / availableWidth))
                        trackProgress = progress
                    }
            )
            
            // Controls
            HStack(spacing: min(geometry.size.width * 0.08, 40)) {
                // Volume control
                VStack(spacing: 5) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: min(geometry.size.width * 0.04, 16)))
                        .foregroundColor(.white)
                    Slider(value: $volume, in: 0...1)
                        .accentColor(.blue)
                        .frame(width: min(geometry.size.width * 0.2, 100))
                }
                
                // Main controls
                HStack(spacing: min(geometry.size.width * 0.08, 40)) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: min(geometry.size.width * 0.06, 24)))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        withAnimation {
                            isPlaying.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: min(geometry.size.width * 0.15, 70), height: min(geometry.size.width * 0.15, 70))
                                .shadow(color: .blue.opacity(0.7), radius: 10, x: 0, y: 0)
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: min(geometry.size.width * 0.06, 24)))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: min(geometry.size.width * 0.06, 24)))
                            .foregroundColor(.white)
                    }
                }
                
                // Library button
                Button(action: {
                    showMediaPicker = true
                }) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: min(geometry.size.width * 0.06, 24)))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Media Picker
struct MediaPickerView: UIViewControllerRepresentable {
    @Binding var audioPlayer: AVAudioPlayer?
    @Binding var isPlaying: Bool
    
    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: MediaPickerView
        
        init(_ parent: MediaPickerView) {
            self.parent = parent
        }
        
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            guard let mediaItem = mediaItemCollection.items.first,
                  let assetURL = mediaItem.assetURL else {
                return
            }
            
            do {
                let newPlayer = try AVAudioPlayer(contentsOf: assetURL)
                parent.audioPlayer = newPlayer
                parent.audioPlayer?.prepareToPlay()
                parent.isPlaying = true
                parent.audioPlayer?.play()
            } catch {
                print("Audio playback error: \(error.localizedDescription)")
            }
            
            mediaPicker.dismiss(animated: true)
        }
        
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
