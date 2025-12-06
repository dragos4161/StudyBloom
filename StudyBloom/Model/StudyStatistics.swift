import Foundation
import FirebaseFirestore

struct StudyStatistics: Codable {
    var userId: String
    var dailyStats: [DailyStat]
    var weeklyStats: [WeeklyStat]
    var totalPagesStudied: Int
    var totalStudyTime: TimeInterval
    var currentStreak: Int
    var longestStreak: Int
    var pomodoroSessionsCompleted: Int
    var flashcardsReviewed: Int
    var lastUpdated: Date
    
    init(
        userId: String,
        dailyStats: [DailyStat] = [],
        weeklyStats: [WeeklyStat] = [],
        totalPagesStudied: Int = 0,
        totalStudyTime: TimeInterval = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        pomodoroSessionsCompleted: Int = 0,
        flashcardsReviewed: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.userId = userId
        self.dailyStats = dailyStats
        self.weeklyStats = weeklyStats
        self.totalPagesStudied = totalPagesStudied
        self.totalStudyTime = totalStudyTime
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.pomodoroSessionsCompleted = pomodoroSessionsCompleted
        self.flashcardsReviewed = flashcardsReviewed
        self.lastUpdated = lastUpdated
    }
}

struct DailyStat: Codable, Identifiable {
    var id: String { dateString }
    var date: Date
    var pagesStudied: Int
    var studyTime: TimeInterval
    var pomodoroSessions: Int
    var flashcardsReviewed: Int
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    init(
        date: Date = Date(),
        pagesStudied: Int = 0,
        studyTime: TimeInterval = 0,
        pomodoroSessions: Int = 0,
        flashcardsReviewed: Int = 0
    ) {
        self.date = date
        self.pagesStudied = pagesStudied
        self.studyTime = studyTime
        self.pomodoroSessions = pomodoroSessions
        self.flashcardsReviewed = flashcardsReviewed
    }
}

struct WeeklyStat: Codable, Identifiable {
    var id: String { weekString }
    var weekStart: Date
    var totalPages: Int
    var totalTime: TimeInterval
    var averagePerDay: Double
    var daysStudied: Int
    
    var weekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-'W'ww"
        return formatter.string(from: weekStart)
    }
    
    init(
        weekStart: Date,
        totalPages: Int = 0,
        totalTime: TimeInterval = 0,
        averagePerDay: Double = 0.0,
        daysStudied: Int = 0
    ) {
        self.weekStart = weekStart
        self.totalPages = totalPages
        self.totalTime = totalTime
        self.averagePerDay = averagePerDay
        self.daysStudied = daysStudied
    }
}
