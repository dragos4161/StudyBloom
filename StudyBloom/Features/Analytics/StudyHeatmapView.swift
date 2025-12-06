import SwiftUI

struct StudyHeatmapView: View {
    let statistics: StudyStatistics
    @StateObject private var analyticsService = AnalyticsService.shared
    
    @State private var heatmapData: [Date: Int] = [:]
    @State private var selectedDate: Date?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let daysToShow = 90
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("90-Day Study Heatmap")
                .font(.headline)
            
            // Weekday Labels
            HStack(spacing: 4) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Heatmap Grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dateRange, id: \.self) { date in
                    heatmapCell(for: date)
                }
            }
            
            // Legend
            heatmapLegend
            
            // Selected Date Info
            if let selected = selectedDate, let pages = heatmapData[selected] {
                selectedDateCard(date: selected, pages: pages)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .onAppear {
            loadHeatmapData()
        }
    }
    
    // MARK: - Heatmap Cell
    
    private func heatmapCell(for date: Date) -> some View {
        let pages = heatmapData[date] ?? 0
        let intensity = calculateIntensity(pages: pages)
        let isSelected = selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
        
        return RoundedRectangle(cornerRadius: 3)
            .fill(colorForIntensity(intensity))
            .frame(height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
            )
            .onTapGesture {
                selectedDate = date
            }
    }
    
    // MARK: - Legend
    
    private var heatmapLegend: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ForEach(0...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForIntensity(Double(level) / 4))
                    .frame(width: 12, height: 12)
            }
            
            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Selected Date Card
    
    private func selectedDateCard(date: Date, pages: Int) -> some View {
        VStack(spacing: 8) {
            Text(formatDate(date))
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                Label("\(pages) pages", systemImage: "book.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                if let dailyStat = statistics.dailyStats.first(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }) {
                    if dailyStat.pomodoroSessions > 0 {
                        Label("\(dailyStat.pomodoroSessions) pomodoros", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<daysToShow).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }
    
    private func loadHeatmapData() {
        heatmapData = analyticsService.getStudyHeatmap(from: statistics, days: daysToShow)
    }
    
    private func calculateIntensity(pages: Int) -> Double {
        guard pages > 0 else { return 0 }
        
        // Calculate max pages from all daily stats
        let maxPages = statistics.dailyStats.map { $0.pagesStudied }.max() ?? 1
        
        guard maxPages > 0 else { return 0 }
        
        // Normalize to 0-1 range
        return min(Double(pages) / Double(maxPages), 1.0)
    }
    
    private func colorForIntensity(_ intensity: Double) -> Color {
        if intensity == 0 {
            return Color(.systemGray6)
        } else if intensity < 0.25 {
            return Color.blue.opacity(0.3)
        } else if intensity < 0.5 {
            return Color.blue.opacity(0.5)
        } else if intensity < 0.75 {
            return Color.blue.opacity(0.7)
        } else {
            return Color.blue
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
