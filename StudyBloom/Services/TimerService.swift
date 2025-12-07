import Foundation
import UserNotifications
import ActivityKit
import Combine

class TimerService: ObservableObject {
    static let shared = TimerService()
    
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var totalTime: TimeInterval = 25 * 60
    @Published var state: TimerState = .idle
    @Published var isBreak: Bool = false
    @Published var mode: TimerMode = .standard {
        didSet {
            // Only convert mode if not running to avoid interrupting
            if state == .idle {
                resetTimer()
            }
        }
    }
    
    // User Presets
    enum TimerMode: String, CaseIterable, Identifiable {
        case standard = "Standard (25/5)"
        case extended = "Extended (50/10)"
        
        var id: String { rawValue }
        
        var focusDuration: TimeInterval {
            switch self {
            case .standard: return 25 * 60
            case .extended: return 50 * 60
            }
        }
        
        var breakDuration: TimeInterval {
            switch self {
            case .standard: return 5 * 60
            case .extended: return 10 * 60
            }
        }
    }
    
    private var timer: Timer?
    private var endDate: Date?
    
    // Live Activity
    private var activity: Activity<TimerAttributes>?
    
    enum TimerState {
        case idle
        case running
        case paused
    }
    
    // Singleton Init
    init() {
        requestNotificationPermissions()
        // Initialize with standard settings
        resetTimer()
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func startTimer(duration: TimeInterval? = nil) {
        if let duration = duration {
            totalTime = duration
            timeRemaining = duration
        }
        
        // Date-based approach for background resilience
        let newEndDate = Date().addingTimeInterval(timeRemaining)
        endDate = newEndDate
        state = .running
        
        scheduleNotification()
        
        // Activity Logic
        if activity == nil {
            startActivity(endDate: newEndDate)
        } else {
            updateActivity()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func pauseTimer() {
        guard state == .running else { return }
        timer?.invalidate()
        state = .paused
        cancelNotification()
        
        // Update Activity to show Paused state
        updateActivity()
    }
    
    func resumeTimer() {
        guard state == .paused else { return }
        startTimer(duration: timeRemaining) // Resume with remaining
    }
    
    func resetTimer(shouldEndActivity: Bool = true) {
        timer?.invalidate()
        state = .idle
        // Set duration based on current Mode and Phase (Break/Focus)
        let newDuration = isBreak ? mode.breakDuration : mode.focusDuration
        timeRemaining = newDuration
        totalTime = newDuration
        cancelNotification()
        if shouldEndActivity {
            endActivity()
        }
    }
    
    // Manual toggle if user wants to skip
    func togglePhase() {
        isBreak.toggle()
        resetTimer()
    }
    
    private func updateTimer() {
        guard let endDate = endDate else { return }
        
        let remaining = endDate.timeIntervalSinceNow
        
        if remaining <= 0 {
            finishTimer()
        } else {
            timeRemaining = remaining
        }
    }
    
    // Closure for decoupling AnalyticsService (since this service is shared with Widget target)
    var onSessionCompleted: ((TimeInterval) -> Void)?
    
    private func finishTimer() {
        timer?.invalidate()
        state = .idle
        timeRemaining = 0
        
        // Auto-transition logic
        if !isBreak {
            // Focus ended -> Start Break
            // DON'T end activity here - let it transition to break
            isBreak = true
            resetTimer(shouldEndActivity: false) // Don't end activity, just reset time
            
            // Start the break timer immediately
            startTimer() 
            // Activity will be updated by startTimer()
            
            // Log study session to analytics via closure
            let sessionDuration = mode.focusDuration
            onSessionCompleted?(sessionDuration)
            
        } else {
            // Break ended -> Go to Focus (but don't auto-start)
            endActivity() // Only end activity when full cycle complete
            isBreak = false
            resetTimer() // Sets focus time (ends activity by default)
            AmbientAudioService.shared.stop() // Stop noise when full cycle done
        }
    }
    
    // MARK: - Notifications
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = isBreak ? "Break Over!" : "Focus Session Complete!"
        content.body = isBreak ? "Ready to focus again?" : "Time for a break! Starting now..."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoro_timer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pomodoro_timer"])
    }
    
    // MARK: - Live Activity
    private func startActivity(endDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = TimerAttributes(timerName: "Pomodoro")
        // Initial state
        let contentState = TimerAttributes.ContentState(
            endDate: endDate,
            isBreak: isBreak,
            totalDuration: totalTime,
            isPaused: false,
            timeRemainingOnPause: 0
        )
        
        do {
            let activity = try Activity<TimerAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            self.activity = activity
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func updateActivity() {
        Task {
            guard let activity = activity else { return }
            
            let isPaused = (state == .paused)
            // If paused, end date is irrelevant for countdown, we show static time. 
            // If running, calculate real end date.
            let currentEndDate = (state == .running) ? (endDate ?? Date()) : Date()
            
            let contentState = TimerAttributes.ContentState(
                endDate: currentEndDate,
                isBreak: isBreak,
                totalDuration: totalTime,
                isPaused: isPaused,
                timeRemainingOnPause: timeRemaining
            )
            
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }
    
    private func endActivity() {
        Task {
            guard let activity = activity else { return }
            // End immediately
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
