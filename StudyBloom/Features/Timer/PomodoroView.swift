import SwiftUI

struct PomodoroView: View {
    @ObservedObject private var timerService = TimerService.shared
    @StateObject private var audioService = AmbientAudioService.shared
    @Environment(\.dismiss) var dismiss
    
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
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(timerService.isBreak ? "Break Time" : "Focus Session")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    // Hidden balance
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
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
                
                // Ambient Sound Selector
                VStack(spacing: 12) {
                    Text("Ambient Sound")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(AmbientAudioService.AmbientSound.allCases) { sound in
                                AmbientSoundButton(
                                    sound: sound,
                                    isSelected: audioService.selectedSound == sound,
                                    action: { audioService.play(sound: sound) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
        .onDisappear {
            if timerService.state != .running {
                audioService.stop()
            }
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
