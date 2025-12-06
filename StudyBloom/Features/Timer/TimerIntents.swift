import AppIntents
import Foundation

// NOTE: Add this file to BOTH App Target and Widget Extension Target

struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    
    public init() {}
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TimerService.shared.pauseTimer()
        }
        return .result()
    }
}

struct ResumeTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    
    public init() {}
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TimerService.shared.resumeTimer()
        }
        return .result()
    }
}

struct ResetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    
    public init() {}
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TimerService.shared.resetTimer()
        }
        return .result()
    }
}
