import ActivityKit
import Foundation

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state
        var endDate: Date
        var isBreak: Bool
        var totalDuration: TimeInterval
        // Pause Support
        var isPaused: Bool = false
        var timeRemainingOnPause: TimeInterval = 0
    }

    // Static data
    var timerName: String
}
