import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
// NOTE: Ensure TimerAttributes and TimerIntents are available to this target

struct StudyTimerWidget: Widget {
    let kind: String = "StudyTimerWidget"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // MARK: - Lock Screen / Banner UI
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: context.state.isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
                        .foregroundStyle(context.state.isBreak ? .green : .blue)
                        .font(.title2)
                    
                    Text(context.state.isBreak ? "Break Time" : "Focus Session")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if context.state.isPaused {
                        Text(formatTime(context.state.timeRemainingOnPause))
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(.yellow)
                    } else {
                        Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(context.state.isBreak ? .green : .blue)
                    }
                }
                
                // Controls & Progress
                if context.state.isPaused {
                     // Paused UI
                     HStack {
                         Text("Paused")
                             .font(.caption)
                             .foregroundStyle(.secondary)
                         Spacer()
                         
                         // Resume Button
                         Button(intent: ResumeTimerIntent()) {
                             Image(systemName: "play.circle.fill")
                                 .font(.title)
                                 .foregroundStyle(.green)
                         }
                         .buttonStyle(.plain)
                         
                          // Reset Button
                         Button(intent: ResetTimerIntent()) {
                             Image(systemName: "stop.circle.fill")
                                 .font(.title)
                                 .foregroundStyle(.red)
                         }
                         .buttonStyle(.plain)
                     }
                     .padding(.top, 4)
                } else {
                     // Running UI
                    HStack {
                        // Progress Bar (Only when running)
                        ProgressView(timerInterval: Date()...context.state.endDate,
                                     countsDown: true,
                                     label: { EmptyView() },
                                     currentValueLabel: { EmptyView() })
                            .tint(context.state.isBreak ? .green : .blue)
                        
                        // Interaction Buttons
                        Button(intent: PauseTimerIntent()) {
                            Image(systemName: "pause.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                        
                        Button(intent: ResetTimerIntent()) {
                           Image(systemName: "stop.circle.fill")
                               .font(.title2)
                               .foregroundStyle(.red)
                       }
                       .buttonStyle(.plain)
                       .padding(.leading, 4)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            // MARK: - Dynamic Island UI
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
                            .foregroundStyle(context.state.isBreak ? .green : .blue)
                        Text(context.state.isBreak ? "Break" : "Focus")
                            .font(.caption)
                            .bold()
                    }
                    .padding(.leading)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text(formatTime(context.state.timeRemainingOnPause))
                            .monospacedDigit()
                            .foregroundStyle(.yellow)
                            .padding(.trailing)
                    } else {
                        Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                            .monospacedDigit()
                            .foregroundStyle(context.state.isBreak ? .green : .blue)
                            .padding(.trailing)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if context.state.isPaused {
                            Button(intent: ResumeTimerIntent()) {
                                Label("Resume", systemImage: "play.fill")
                            }
                            .tint(.green)
                        } else {
                             Button(intent: PauseTimerIntent()) {
                                Label("Pause", systemImage: "pause.fill")
                            }
                            .tint(.yellow)
                        }
                        
                        Button(intent: ResetTimerIntent()) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .tint(.red)
                    }
                    .padding()
                }
                
            } compactLeading: {
                Image(systemName: context.state.isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
                    .foregroundStyle(context.state.isPaused ? .yellow : (context.state.isBreak ? .green : .blue))
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(.yellow)
                } else {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundStyle(context.state.isBreak ? .green : .blue)
                }
            } minimal: {
                 Image(systemName: context.state.isBreak ? "cup.and.saucer.fill" : "brain.head.profile")
                    .foregroundStyle(context.state.isPaused ? .yellow : (context.state.isBreak ? .green : .blue))
            }
        }
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
