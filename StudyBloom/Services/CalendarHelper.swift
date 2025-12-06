import Foundation
import SwiftUI

enum DayProgressState {
    case notStarted      // Day is in the future
    case notScheduled    // No task scheduled for this day
    case freeDay         // Marked as free day
    case noActivity      // Was scheduled but nothing logged (Deprecated mostly, usually we use missed)
    case missed          // Past/Today, Scheduled, No Logs (Red Dot)
    case partialProgress // Some pages logged but goal not met
    case goalAchieved    // Daily goal met or exceeded
}

struct DayInfo: Identifiable {
    let id = UUID()
    let date: Date
    let state: DayProgressState
    let scheduledTask: StudyTask?
    let logs: [DailyLog]
    let totalPagesLogged: Int
    let dailyGoal: Int
    let chapterColor: String?
    let chapterTitle: String?
    
    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(totalPagesLogged) / Double(dailyGoal), 1.0)
    }
}

class CalendarHelper {
    static func getDayInfo(
        for date: Date,
        schedule: [Date: [StudyTask]],
        logs: [DailyLog],
        chapters: [Chapter],
        plan: StudyPlan?
    ) -> DayInfo {
        let calendar = Calendar.current
        
        // 1. Get logs for this day
        let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let totalPagesLogged = dayLogs.reduce(0) { $0 + $1.pagesLearned }
        
        // 2. Get task for this day
        let daysTasks = schedule.first(where: { calendar.isDate($0.key, inSameDayAs: date) })?.value ?? []
        let task = daysTasks.first // Assuming one task per day for now
        
        // 3. Determine Chapter Color and Title
        // Priority: Logged Chapter -> Scheduled Chapter
        var color: String? = nil
        var title: String? = nil
        
        if let firstLog = dayLogs.first(where: { !$0.isFreeDay }),
           let logChapter = chapters.first(where: { $0.id == firstLog.chapterId }) {
            color = logChapter.colorHex
            title = logChapter.title
        } else if let task = task {
            color = task.colorHex
            title = task.chapterTitle
        }
        
        // 4. Determine State
        let isFreeDayLog = dayLogs.contains(where: { $0.isFreeDay })
        let isPlanFreeDay = plan?.freeDays.contains(calendar.component(.weekday, from: date)) ?? false
        let isFree = isFreeDayLog || isPlanFreeDay
        
        let dailyGoal = plan?.dailyPageGoal ?? 10
        
        var state: DayProgressState = .notScheduled
        
        if isFree {
            state = .freeDay
        } else if calendar.compare(date, to: calendar.startOfDay(for: Date()), toGranularity: .day) == .orderedDescending {
            // Future
            state = task != nil ? .notStarted : .notScheduled
        } else {
            // Past or Today
            if totalPagesLogged >= dailyGoal {
                state = .goalAchieved
            } else if totalPagesLogged > 0 {
                state = .partialProgress
            } else {
                state = task != nil ? .missed : .notScheduled
            }
        }
        
        // Special case: If it was not scheduled but user logged something (extra study)
        if state == .notScheduled && totalPagesLogged > 0 {
            state = totalPagesLogged >= dailyGoal ? .goalAchieved : .partialProgress
        }
        
        return DayInfo(
            date: date,
            state: state,
            scheduledTask: task,
            logs: dayLogs,
            totalPagesLogged: totalPagesLogged,
            dailyGoal: dailyGoal,
            chapterColor: color,
            chapterTitle: title
        )
    }
}
