import SwiftUI

struct DayDetailView: View {
    let dayInfo: DayInfo
    @Environment(\.dismiss) var dismiss
    
    // Callbacks
    var onAddLog: () -> Void
    var onToggleFreeDay: () -> Void
    var onDeleteLog: (DailyLog) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. Header & Status
                    headerSection
                    
                    // 2. Scheduled Task
                    if let task = dayInfo.scheduledTask {
                        scheduledTaskCard(task: task)
                    } else if dayInfo.state == .freeDay {
                        freeDayCard
                    } else if dayInfo.state == .notScheduled {
                        Text("No study scheduled for this day.")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    
                    // 3. Progress Section
                    progressSection
                    
                    // 4. Action: Free Day
                    freeDayButton
                    
                    // 5. Log History
                    logHistorySection
                }
                .padding()
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial) // Standard sheet material
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayInfo.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.title3)
                    .fontWeight(.bold)
                
                switch dayInfo.state {
                case .goalAchieved:
                    Text("Goal Achieved")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                case .partialProgress:
                    Text("In Progress")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                case .freeDay:
                    Text("Free Day")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                default:
                    Text("No Activity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Status Icon on the right
            switch dayInfo.state {
            case .goalAchieved:
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                    .foregroundStyle(.green)
            case .partialProgress:
                Image(systemName: "chart.bar.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
            case .freeDay:
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.blue)
            default:
                EmptyView()
            }
        }
    }
    
    private var freeDayCard: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text("Relax & Recharge")
                    .font(.headline)
                Text("This day is marked as a free day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func scheduledTaskCard(task: StudyTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scheduled")
                .font(.subheadline)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(task.chapterTitle)
                        .font(.headline)
                    Text("Pages \(task.startPage) - \(task.endPage) • \(task.pagesToRead) pages")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Circle()
                    .fill(Color(hex: task.colorHex) ?? .gray)
                    .frame(width: 12, height: 12)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.subheadline)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Goal: \(dayInfo.dailyGoal) pages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(dayInfo.totalPagesLogged) pages completed")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Spacer()
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: dayInfo.progressPercentage)
                        .stroke(
                            dayInfo.progressPercentage >= 1.0 ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(dayInfo.progressPercentage * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
    
    private var logHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Log History")
                    .font(.subheadline)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Spacer()
                
                Button(action: onAddLog) {
                    Label("Add Log", systemImage: "plus")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            
            if dayInfo.logs.isEmpty {
                Text("No activity logged yet.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(dayInfo.logs) { log in
                    if !log.isFreeDay {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(log.pagesLearned) pages")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                Text(log.createdAt?.formatted(date: .omitted, time: .shortened) ?? "Manual Entry")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            Button(role: .destructive) {
                                onDeleteLog(log)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            }
        }
    
    
    // New separate button component
    private var freeDayButton: some View {
        Button(action: onToggleFreeDay) {
            HStack {
                Image(systemName: dayInfo.state == .freeDay ? "calendar.badge.minus" : "sparkles")
                Text(dayInfo.state == .freeDay ? "Remove Free Day" : "Mark as Free Day")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(dayInfo.state == .freeDay ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
            .foregroundStyle(dayInfo.state == .freeDay ? Color.primary : Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

}
