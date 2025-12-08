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
            // Self-healing: Sync to profile to ensure friends see up-to-date stats
            // This fixes the issue where existing stats weren't reflected in the public profile
            syncToUserProfile(userId: userId, stats: stats)
            return stats
        } else {
            // Create new statistics
            let newStats = StudyStatistics(userId:userId)
            try db.collection("statistics").document(userId).setData(from: newStats)
            // Sync new stats too
            syncToUserProfile(userId: userId, stats: newStats)
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
        // Save to Firebase
        try db.collection("statistics").document(userId).setData(from: stats)
        
        // Sync to public profile
        syncToUserProfile(userId: userId, stats: stats)
    }
    
    // Combined method to avoid race conditions when finishing a timer
    func logPomodoroCompletion(duration: TimeInterval) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var stats = try await fetchStatistics()
        
        // Update Time
        stats.totalStudyTime += duration
        
        // Update Pomodoro Count
        stats.pomodoroSessionsCompleted += 1
        
        // Update Daily Stats for both
        let today = Calendar.current.startOfDay(for: Date())
        if let index = stats.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            stats.dailyStats[index].studyTime += duration
            stats.dailyStats[index].pomodoroSessions += 1
        } else {
            // New daily entry
            var newDailyStat = DailyStat(date: today, pagesStudied: 0, studyTime: duration)
            newDailyStat.pomodoroSessions = 1
            stats.dailyStats.append(newDailyStat)
        }
        
        // Update Streak (based on study activity)
        updateStreak(stats: &stats)
        
        stats.lastUpdated = Date()
        try db.collection("statistics").document(userId).setData(from: stats)
        
        // Sync to public profile
        syncToUserProfile(userId: userId, stats: stats)
    }
    
    func logPomodoroSession() async throws {
        // Keeps existing implementation for manual logging if needed,
        // but logPomodoroCompletion is preferred for timer finishes.
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
        
        // Sync to public profile
        syncToUserProfile(userId: userId, stats: stats)
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
        
        // Sync to public profile
        syncToUserProfile(userId: userId, stats: stats)
    }
    
    // MARK: - Streak Calculation
    
    private func updateStreak(stats: inout StudyStatistics) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort daily stats by date descending
        let sortedStats = stats.dailyStats.sorted { $0.date > $1.date }
        
        var currentStreak = 0
        var lastDate: Date?
        
        for stat in sortedStats {
            // Check if this day has any activity (pages, time, or sessions)
            if stat.pagesStudied > 0 || stat.studyTime > 0 || stat.pomodoroSessions > 0 || stat.flashcardsReviewed > 0 {
                let statDate = calendar.startOfDay(for: stat.date)
                
                if let last = lastDate {
                    // Check if consecutive (1 day difference)
                    let diff = calendar.dateComponents([.day], from: statDate, to: last).day ?? 0
                    
                    if diff == 1 {
                        currentStreak += 1
                        lastDate = statDate
                    } else if diff == 0 {
                        // Same day, ignore (already counted)
                        continue
                    } else {
                        // Gap found, streak ends
                        break
                    }
                } else {
                    // First valid day found (either today or most recent active day)
                    // Check if it's today or yesterday to trigger current streak
                    // If the most recent activity was 2 days ago, streak is 0.
                    let diffFromToday = calendar.dateComponents([.day], from: statDate, to: today).day ?? 0
                    
                    if diffFromToday <= 1 {
                        currentStreak = 1
                        lastDate = statDate
                    } else {
                        // Most recent activity is too old
                        currentStreak = 0
                        break
                    }
                }
            }
        }
        
        stats.currentStreak = currentStreak
        
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
    
    // MARK: - Profile Sync
    
    /// Syncs key statistics to the public user profile so friends can see them
    private func syncToUserProfile(userId: String, stats: StudyStatistics) {
        let profileData: [String: Any] = [
            "studyStreak": stats.currentStreak,
            "totalStudyTime": stats.totalStudyTime,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Fire and forget update
        // Use setData with merge: true to avoid errors if document missing and for robustness
        db.collection("users").document(userId).setData(profileData, merge: true) { error in
            if let error = error {
                print("Error syncing stats to user profile: \(error)")
            }
        }
    }
}
