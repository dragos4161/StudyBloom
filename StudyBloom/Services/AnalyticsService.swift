import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private let db = Firestore.firestore()
    @Published var statistics: StudyStatistics?
    
    private init() {}
    
    // MARK: - Statistics Fetching
    
    func fetchStatistics() async throws -> StudyStatistics {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AnalyticsService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let doc = try await db.collection("statistics").document(userId).getDocument()
        
        if let stats = try? doc.data(as: StudyStatistics.self) {
            return stats
        } else {
            // Create new statistics
            let newStats = StudyStatistics(userId:userId)
            try db.collection("statistics").document(userId).setData(from: newStats)
            return newStats
        }
    }
    
    // MARK: - Logging Activities
    
    func logStudySession(pages: Int, duration: TimeInterval) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var stats = try await fetchStatistics()
        
        // Update totals
        stats.totalPagesStudied += pages
        stats.totalStudyTime += duration
        
        // Update daily stat
        let today = Calendar.current.startOfDay(for: Date())
        if let index = stats.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            stats.dailyStats[index].pagesStudied += pages
            stats.dailyStats[index].studyTime += duration
        } else {
            let newDailyStat = DailyStat(date: today, pagesStudied: pages, studyTime: duration)
            stats.dailyStats.append(newDailyStat)
        }
        
        // Update streak
        updateStreak(stats: &stats)
        
        stats.lastUpdated = Date()
        
        // Save to Firebase
        try db.collection("statistics").document(userId).setData(from: stats)
    }
    
    func logPomodoroSession() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var stats = try await fetchStatistics()
        stats.pomodoroSessionsCompleted += 1
        
        // Update daily stat
        let today = Calendar.current.startOfDay(for: Date())
        if let index = stats.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            stats.dailyStats[index].pomodoroSessions += 1
        } else {
            let newDailyStat = DailyStat(date: today, pomodoroSessions: 1)
            stats.dailyStats.append(newDailyStat)
        }
        
        stats.lastUpdated = Date()
        try db.collection("statistics").document(userId).setData(from: stats)
    }
    
    func logFlashcardReview(count: Int) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var stats = try await fetchStatistics()
        stats.flashcardsReviewed += count
        
        // Update daily stat
        let today = Calendar.current.startOfDay(for: Date())
        if let index = stats.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            stats.dailyStats[index].flashcardsReviewed += count
        } else {
            let newDailyStat = DailyStat(date: today, flashcardsReviewed: count)
            stats.dailyStats.append(newDailyStat)
        }
        
        stats.lastUpdated = Date()
        try db.collection("statistics").document(userId).setData(from: stats)
    }
    
    // MARK: - Streak Calculation
    
    private func updateStreak(stats: inout StudyStatistics) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Check if user studied yesterday
        let studiedYesterday = stats.dailyStats.contains { stat in
            calendar.isDate(stat.date, inSameDayAs: yesterday) && stat.pagesStudied > 0
        }
        
        // Check if user studied today
        let studiedToday = stats.dailyStats.contains { stat in
            calendar.isDate(stat.date, inSameDayAs: today) && stat.pagesStudied > 0
        }
        
        if studiedToday {
            if studiedYesterday || stats.currentStreak == 0 {
                stats.currentStreak += 1
            }
        } else {
            stats.currentStreak = 0
        }
        
        // Update longest streak
        if stats.currentStreak > stats.longestStreak {
            stats.longestStreak = stats.currentStreak
        }
    }
    
    // MARK: - Analytics Calculations
    
    func calculateWeeklyTrends(from stats: StudyStatistics) -> [WeeklyStat] {
        let calendar = Calendar.current
        var weeklyStats: [Date: WeeklyStat] = [:]
        
        for dailyStat in stats.dailyStats {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dailyStat.date))!
            
            if var weekStat = weeklyStats[weekStart] {
                weekStat.totalPages += dailyStat.pagesStudied
                weekStat.totalTime += dailyStat.studyTime
                weekStat.daysStudied += (dailyStat.pagesStudied > 0 ? 1 : 0)
                weekStat.averagePerDay = Double(weekStat.totalPages) / Double(weekStat.daysStudied)
                weeklyStats[weekStart] = weekStat
            } else {
                weeklyStats[weekStart] = WeeklyStat(
                    weekStart: weekStart,
                    totalPages: dailyStat.pagesStudied,
                    totalTime: dailyStat.studyTime,
                    averagePerDay: Double(dailyStat.pagesStudied),
                    daysStudied: dailyStat.pagesStudied > 0 ? 1 : 0
                )
            }
        }
        
        return weeklyStats.values.sorted { $0.weekStart > $1.weekStart }
    }
    
    func getStudyHeatmap(from stats: StudyStatistics, days: Int = 90) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var heatmap: [Date: Int] = [:]
        
        // Initialize last 90 days with 0
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                heatmap[date] = 0
            }
        }
        
        // Fill in actual data
        for dailyStat in stats.dailyStats {
            let date = calendar.startOfDay(for: dailyStat.date)
            if let _ = heatmap[date] {
                heatmap[date] = dailyStat.pagesStudied
            }
        }
        
        return heatmap
    }
    
    func getAverageStudyTime(from stats: StudyStatistics) -> TimeInterval {
        guard !stats.dailyStats.isEmpty else { return 0 }
        
        let totalTime = stats.dailyStats.reduce(0) { $0 + $1.studyTime }
        let daysWithStudy = stats.dailyStats.filter { $0.studyTime > 0 }.count
        
        return daysWithStudy > 0 ? totalTime / Double(daysWithStudy) : 0
    }
}
