import SwiftUI
import SwiftData

struct StudyDashboardView: View {
    @Query(sort: \Chapter.orderIndex) private var chapters: [Chapter]
    @Query private var plans: [StudyPlan]
    @Query private var logs: [DailyLog]
    @Environment(\.modelContext) var modelContext
    
    @State private var schedule: [Date: [StudyTask]] = [:]
    @State private var selectedDate: Date = Date()
    @State private var isShowingSettings = false
    @State private var selectedLogTarget: LogTarget?
    
    struct LogTarget: Identifiable {
        let id = UUID()
        let date: Date
        let chapter: Chapter
    }
    
    var currentPlan: StudyPlan? {
        plans.first
    }
    
    var todayTasks: [StudyTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return schedule[today] ?? []
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header / Today's Goal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Goal")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if todayTasks.isEmpty {
                            if isFreeDay(date: Date()) {
                                FreeDayCard()
                            } else if chapters.isEmpty {
                                EmptyStateCard(message: "Add chapters to start planning.")
                            } else if isFinished() {
                                FinishedCard()
                            } else {
                                // Maybe just no tasks for today due to some other reason?
                                Text("No tasks scheduled.")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(todayTasks) { task in
                                TaskCard(task: task) {
                                    handleLog(date: Date(), task: task)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Schedule")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        CalendarGridView(
                            schedule: schedule,
                            selectedDate: $selectedDate,
                            isFreeDay: isFreeDay,
                            toggleFreeDay: toggleFreeDay,
                            onLog: { date in
                                handleLog(date: date)
                            },
                            logs: logs,
                            chapters: chapters
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Study Bloom")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                PlanSettingsView()
                    .onDisappear {
                        recalculateSchedule()
                    }
            }
            .sheet(item: $selectedLogTarget) { target in
                LogProgressView(chapter: target.chapter) { newPages in
                    let delta = newPages - target.chapter.pagesStudied
                    target.chapter.pagesStudied = newPages
                    
                    if delta > 0 {
                        let log = DailyLog(date: target.date, pagesLearned: delta, chapterId: target.chapter.id)
                        modelContext.insert(log)
                    }
                    
                    // Trigger schedule recalculation
                    recalculateSchedule()
                }
            }
            .onAppear {
                recalculateSchedule()
            }
            .onChange(of: logs) { _, _ in
                recalculateSchedule()
            }
            .onChange(of: chapters) { _, _ in
                recalculateSchedule()
            }
        }
    }
    
    private func recalculateSchedule() {
        guard let plan = currentPlan else { return }
        schedule = StudyPlanner.calculateSchedule(chapters: chapters, plan: plan, logs: logs)
    }
    
    private func isFreeDay(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Check plan settings
        if let plan = currentPlan, plan.freeDays.contains(weekday) {
            return true
        }
        
        // Check logs for manual free day
        if logs.contains(where: { calendar.isDate($0.date, inSameDayAs: date) && $0.isFreeDay }) {
            return true
        }
        
        return false
    }
    
    private func isFinished() -> Bool {
        return chapters.allSatisfy { $0.pagesStudied >= $0.totalPages }
    }
    
    private func toggleFreeDay(_ date: Date) {
        let calendar = Calendar.current
        
        // Check if there is already a log for this day
        if let existingLog = logs.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // If it's a free day log, remove it (or toggle off if we want to keep history, but removing is cleaner for "unmarking")
            // If it's a progress log, we probably shouldn't just overwrite it without warning, but for now let's assume "Mark as Free" overrides.
            // Actually, let's just update the isFreeDay flag if it exists, or delete if it was ONLY a free day marker.
            
            if existingLog.isFreeDay {
                modelContext.delete(existingLog)
            } else {
                existingLog.isFreeDay = true
            }
        } else {
            // Create a new log just to mark it as free
            let newLog = DailyLog(date: date, pagesLearned: 0, chapterId: "", isFreeDay: true)
            modelContext.insert(newLog)
        }
        
        // Recalculate will happen via onChange of logs
    }
    
    private func handleLog(date: Date, task: StudyTask? = nil) {
        let calendar = Calendar.current
        
        // 1. If task is provided (e.g. from Today's Goal), use it.
        if let task = task, let chapter = chapters.first(where: { $0.id == task.chapterId }) {
            selectedLogTarget = LogTarget(date: date, chapter: chapter)
            return
        }
        
        // 2. If there's a task scheduled for this date, use it.
        let dayStart = calendar.startOfDay(for: date)
        if let tasks = schedule[dayStart], let firstTask = tasks.first, let chapter = chapters.first(where: { $0.id == firstTask.chapterId }) {
            selectedLogTarget = LogTarget(date: date, chapter: chapter)
            return
        }
        
        // 3. Otherwise, default to the first unfinished chapter.
        if let firstUnfinished = chapters.first(where: { $0.pagesStudied < $0.totalPages }) {
            selectedLogTarget = LogTarget(date: date, chapter: firstUnfinished)
        }
    }
}

struct TaskCard: View {
    let task: StudyTask
    // We use a binding or closure to notify parent of selection
    var onLog: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.chapterTitle)
                    .font(.headline)
                Spacer()
                Text("\(task.pagesToRead) pages")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Capsule())
            }
            
            Text("Pages \(task.startPage) - \(task.endPage)")
                .font(.caption)
                .opacity(0.8)
            
            Button(action: onLog) {
                Text("Log Progress")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .foregroundColor(Color(hex: task.colorHex) ?? .black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(hex: task.colorHex) ?? .gray)
        .foregroundColor(.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FreeDayCard: View {
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text("Free Day!")
                    .font(.headline)
                Text("Relax and recharge.")
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyStateCard: View {
    let message: String
    var body: some View {
        Text(message)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FinishedCard: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("All caught up!")
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CalendarGridView: View {
    let schedule: [Date: [StudyTask]]
    @Binding var selectedDate: Date
    let isFreeDay: (Date) -> Bool
    let toggleFreeDay: (Date) -> Void
    let onLog: (Date) -> Void
    // New dependencies for past logs
    let logs: [DailyLog]
    let chapters: [Chapter]
    
    @State private var currentMonth: Date = Date()
    
    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    // Generate dates for displayed month
    var days: [Date] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        // Get range of days in month
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Month navigation header
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 8)
            
            // Calendar Grid with Swipe
            LazyVGrid(columns: columns, spacing: 8) {
                // Weekday headers
                let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdays[index])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                
                // Days
                if let firstDay = days.first {
                    let weekday = calendar.component(.weekday, from: firstDay)
                    let offset = weekday - 1
                    ForEach(0..<offset, id: \.self) { _ in
                        Spacer()
                    }
                }
                
                ForEach(days, id: \.self) { date in
                    let tasks = schedule[date] ?? []
                    let isToday = calendar.isDateInToday(date)
                    let isFree = isFreeDay(date)
                    
                    // Check for past logs
                    let logForDay = logs.first { calendar.isDate($0.date, inSameDayAs: date) && !$0.isFreeDay }
                    let chapterColor: String? = {
                        if let log = logForDay, let chapter = chapters.first(where: { $0.id == log.chapterId }) {
                            return chapter.colorHex
                        }
                        if let firstTask = tasks.first {
                            return firstTask.colorHex
                        }
                        return nil
                    }()
                    
                    ZStack {
                        if isFree {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                )
                        } else if let color = chapterColor {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: color) ?? .gray)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        }
                        
                        Text("\(calendar.component(.day, from: date))")
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(isToday ? .white : ((tasks.isEmpty && logForDay == nil) && !isFree ? .primary : .white))
                            .shadow(radius: (tasks.isEmpty && logForDay == nil) && !isFree ? 0 : 1)
                    }
                    .frame(height: 40)
                    .onTapGesture {
                        selectedDate = date
                    }
                    .contextMenu {
                        Button {
                            onLog(date)
                        } label: {
                            Label("Log Progress", systemImage: "pencil")
                        }
                        
                        Button {
                            toggleFreeDay(date)
                        } label: {
                            Label(isFree ? "Remove Free Day" : "Mark as Free Day", systemImage: isFree ? "calendar.badge.minus" : "sparkles")
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            // Swipe Left -> Next Month
                            withAnimation {
                                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            }
                        } else if value.translation.width > 50 {
                            // Swipe Right -> Previous Month
                            withAnimation {
                                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }
                        }
                    }
            )
        }
    }
}
