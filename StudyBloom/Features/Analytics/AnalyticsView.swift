import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var statistics: StudyStatistics?
    @State private var isLoading = true
    @State private var selectedPeriod: Period = .week
    
    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let stats = statistics {
                    // Streak Card
                    streakCard(stats: stats)
                    
                    // Quick Stats
                    quickStatsGrid(stats: stats)
                    
                    // Period Selector
                    periodSelector
                    
                    // Weekly Trends Chart
                    weeklyTrendsCard(stats: stats)
                    
                    // Study Heatmap
                    StudyHeatmapView(statistics: stats)
                        .padding(.horizontal)
                } else {
                    emptyStateView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .task {
            await loadStatistics()
        }
        .refreshable {
            await loadStatistics()
        }
    }
    
    // MARK: - Streak Card
    
    private func streakCard(stats: StudyStatistics) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Current Streak", systemImage: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(stats.currentStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(stats.currentStreak == 1 ? "day" : "days")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Label("Best Streak", systemImage: "trophy.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(stats.longestStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.yellow)
                    
                    Text(stats.longestStreak == 1 ? "day" : "days")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            if stats.currentStreak > 0 {
                Text("🔥 Keep it going! Study today to maintain your streak")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Stats Grid
    
    private func quickStatsGrid(stats: StudyStatistics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            QuickStatCard(
                icon: "book.fill",
                value: "\(stats.totalPagesStudied)",
                label: "Pages Studied",
                color: .blue
            )
            
            QuickStatCard(
                icon: "clock.fill",
                value: formatTotalTime(stats.totalStudyTime),
                label: "Study Time",
                color: .green
            )
            
            QuickStatCard(
                icon: "timer",
                value: "\(stats.pomodoroSessionsCompleted)",
                label: "Pomodoros",
                color: .purple
            )
            
            QuickStatCard(
                icon: "rectangle.on.rectangle.fill",
                value: "\(stats.flashcardsReviewed)",
                label: "Cards Reviewed",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Trends Card
    
    private func weeklyTrendsCard(stats: StudyStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Trends")
                .font(.headline)
            
            let weeklyStats = analyticsService.calculateWeeklyTrends(from: stats)
            let displayStats = getDisplayStats(weeklyStats)
            
            if displayStats.isEmpty {
                Text("No data for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(displayStats) { week in
                        BarMark(
                            x: .value("Week", weekString(week.weekStart)),
                            y: .value("Pages", week.totalPages)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Analytics Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start studying to see your statistics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func loadStatistics() async {
        isLoading = true
        
        do {
            let stats = try await analyticsService.fetchStatistics()
            await MainActor.run {
                self.statistics = stats
                self.analyticsService.statistics = stats
                isLoading = false
            }
        } catch {
            print("Error loading statistics: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func getDisplayStats(_ weeklyStats: [WeeklyStat]) -> [WeeklyStat] {
        switch selectedPeriod {
        case .week:
            return Array(weeklyStats.prefix(1))
        case .month:
            return Array(weeklyStats.prefix(4))
        case .all:
            return Array(weeklyStats.prefix(12))
        }
    }
    
    private func weekString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTotalTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(Int(seconds) / 60)m"
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
