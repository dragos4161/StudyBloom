import Foundation
import AVFoundation
import AudioToolbox
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
    
    func play(sound: AmbientSound, volume: Float = 1.0) {
        if isPlaying {
            // If already playing the same sound, just return (or update volume if needed)
            if selectedSound == sound {
                playerNode.volume = volume
                return
            }
            stop()
        }
        
        guard sound != .none else {
            selectedSound = .none
            return
        }
        
        selectedSound = sound
        playerNode.volume = volume
        
        if let buffer = generateNoiseBuffer(type: sound) {
            // Ensure engine is running
            if !engine.isRunning {
                try? engine.start()
            }
            
            // Connect and schedule
            engine.connect(playerNode, to: engine.mainMixerNode, format: buffer.format)
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            playerNode.play()
            isPlaying = true
        }
    }
    
    func pause() {
        if isPlaying {
            playerNode.pause()
            isPlaying = false
        }
    }
    
    func resume() {
        if !isPlaying && selectedSound != .none {
            if !engine.isRunning {
                try? engine.start()
            }
            playerNode.play()
            isPlaying = true
        }
    }
    
    func stop() {
        playerNode.stop()
        isPlaying = false
    }
    
    func playAlarm() {
        // System Sound 1005 is a standard alarm sound
        // 1304 is a "tweet" sound, often used for messages
        // 1016 is "Bell"
        // Let's use 1005 for now
        AudioServicesPlaySystemSound(1005)
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
