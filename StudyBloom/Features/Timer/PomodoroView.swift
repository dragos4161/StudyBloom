import SwiftUI

struct PomodoroView: View {
    @ObservedObject private var timerService = TimerService.shared
    @StateObject private var audioService = AmbientAudioService.shared
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("focusSound") private var focusSound: AmbientAudioService.AmbientSound = .rain
    @AppStorage("breakSound") private var breakSound: AmbientAudioService.AmbientSound = .stream
    
    // Formatting
    private var timeString: String {
        let minutes = Int(timerService.timeRemaining) / 60
        let seconds = Int(timerService.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: Double {
        guard timerService.totalTime > 0 else { return 0 }
        return 1.0 - (timerService.timeRemaining / timerService.totalTime)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header - Using ZStack for better alignment
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title) // Slightly larger
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    
                    Text(timerService.isBreak ? "Break Time" : "Focus Session")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 30) // Increased top padding for better visibility
                
                // Timer Visualization
                ZStack {
                    // Calming Animation (Only visible when running)
                    if timerService.state == .running {
                        CalmingAnimationView()
                            .transition(.opacity.animation(.easeInOut))
                    }
                    
                    // Ring
                    TimerRingView(
                        progress: progress,
                        color: timerService.isBreak ? .green : .blue
                    )
                    .frame(width: 300, height: 300)
                    
                    // Time Text
                    Text(timeString)
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .monospacedDigit()
                }
                .padding(.vertical, 20)
                
                // Controls
                VStack(spacing: 20) {
                    // Mode Selector (Only when idle)
                    if timerService.state == .idle {
                        Picker("Mode", selection: $timerService.mode) {
                            ForEach(TimerService.TimerMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 40)
                    }
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            if timerService.state == .running {
                                timerService.pauseTimer()
                            } else {
                                if timerService.state == .idle {
                                    timerService.startTimer()
                                } else {
                                    timerService.resumeTimer()
                                }
                            }
                        }) {
                            Image(systemName: timerService.state == .running ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(timerService.isBreak ? .green : .blue)
                            .shadow(radius: 5)
                            .symbolEffect(.bounce, value: timerService.state)
                        }
                        
                        if timerService.state != .idle {
                            Button(action: { timerService.resetTimer() }) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                
                // Sound Configuration
                VStack(spacing: 20) {
                    // Focus Sound Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus Sound")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(AmbientAudioService.AmbientSound.allCases) { sound in
                                    AmbientSoundButton(
                                        sound: sound,
                                        isSelected: focusSound == sound,
                                        action: { 
                                            focusSound = sound
                                            // Preview if idle, or update if running matching phase
                                            if timerService.state == .idle || (timerService.state == .running && !timerService.isBreak) {
                                                audioService.play(sound: sound)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Break Sound Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Sound")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(AmbientAudioService.AmbientSound.allCases) { sound in
                                    AmbientSoundButton(
                                        sound: sound,
                                        isSelected: breakSound == sound,
                                        action: { 
                                            breakSound = sound
                                            // Preview if idle, or update if running matching phase
                                            if timerService.state == .idle || (timerService.state == .running && timerService.isBreak) {
                                                audioService.play(sound: sound)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .onChange(of: timerService.state) { newState in
           handleStateChange(newState)
        }
        .onChange(of: timerService.isBreak) { isBreak in
            handleBreakChange(isBreak)
        }
        .onDisappear {
            // Stop sound when view disappears if not running background mode logic (simple version)
            // But we want it to keep playing if backgrounded? 
            // The request says "when paused... sound should stop".
            // If we just close the sheet, it might imply "stop".
            // But usually Pomodoro runs in background. 
            // Let's rely on TimerService state.
        }
    }
    
    private func handleStateChange(_ state: TimerService.TimerState) {
        switch state {
        case .running:
            let soundToPlay = timerService.isBreak ? breakSound : focusSound
            audioService.play(sound: soundToPlay)
        case .paused:
            audioService.pause()
        case .idle:
            audioService.stop()
        }
    }
    
    private func handleBreakChange(_ isBreak: Bool) {
        // Transition happened
        
        // 1. Play Alarm
        audioService.playAlarm()
        
        // 2. Switch sound if running
        if timerService.state == .running {
            let soundToPlay = isBreak ? breakSound : focusSound
            audioService.play(sound: soundToPlay)
        } else {
             // If we went to idle (e.g. break finished -> idle), logic in handleStateChange(.idle) stops sound.
             // But we still want the alarm. 
             // If timerService finishes break, it sets isBreak=false and state=idle.
             // Both onChange fire. Order matters.
             // Alarm relies on being transient.
        }
    }
}

struct AmbientSoundButton: View {
    let sound: AmbientAudioService.AmbientSound
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: sound.iconName)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .blue : .gray)
                }
                
                Text(sound.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .blue : .gray)
            }
        }
    }
}

#Preview {
    PomodoroView()
}
