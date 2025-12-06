import Foundation
import AVFoundation
import Combine

class AmbientAudioService: ObservableObject {
    static let shared = AmbientAudioService()
    
    private var engine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var isPlaying = false
    
    @Published var selectedSound: AmbientSound = .none
    
    enum AmbientSound: String, CaseIterable, Identifiable {
        case none = "Off"
        case rain = "Rain"
        case stream = "Stream"
        case forest = "Forest" 
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .none: return "speaker.slash"
            case .rain: return "cloud.rain"
            case .stream: return "water.waves"
            case .forest: return "leaf"
            }
        }
    }
    
    init() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        // Connect player to main mixer
        let mainMixer = engine.mainMixerNode
        engine.connect(playerNode, to: mainMixer, format: nil) 
        
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func play(sound: AmbientSound) {
        if isPlaying {
            stop()
        }
        
        guard sound != .none else {
            selectedSound = .none
            return
        }
        
        selectedSound = sound
        
        if let buffer = generateNoiseBuffer(type: sound) {
            engine.disconnectNodeInput(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: buffer.format)
            
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            
            do {
                if !engine.isRunning {
                    try engine.start()
                }
                playerNode.play()
                isPlaying = true
            } catch {
                print("Failed to start engine: \(error)")
            }
        }
    }
    
    func stop() {
        playerNode.stop()
        engine.stop()
        isPlaying = false
    }
    
    private func generateNoiseBuffer(type: AmbientSound) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let duration: Double = 5.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let channel0 = buffer.floatChannelData?[0],
              let channel1 = buffer.floatChannelData?[1] else { return nil }
        
        var lastOut: Float = 0
        
        for i in 0..<Int(frameCount) {
            let white = Float.random(in: -1...1)
            var sample: Float = 0
            
            switch type {
            case .rain:
                // Heavy Brown Noise for Rain
                // Simple integration (Brown)
                let brown = (lastOut + (0.02 * white)) / 1.02
                lastOut = brown
                sample = brown * 5.0 // Gain boost
                
            case .stream:
                // Lighter Brown/Pink Noise for Stream
                let brown = (lastOut + (0.05 * white)) / 1.05 // Less damping = higher pitch
                lastOut = brown
                sample = brown * 3.0
                
            case .forest:
                 // Wind (Pink-ish) + Periodic chirps?
                 // For MVP procedural, we'll keep it as "Wind" (filtered noise)
                 // This is a simple low-passed white noise
                 let brown = (lastOut + (0.1 * white)) / 1.1
                 lastOut = brown
                 sample = brown * 2.0
                 
            case .none:
                sample = 0
            }
            
            // Normalize roughly
            sample = max(-1.0, min(1.0, sample * 0.5))
            
            channel0[i] = sample
            channel1[i] = sample
        }
        
        return buffer
    }
}
