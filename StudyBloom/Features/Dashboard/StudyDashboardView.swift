import SwiftUI

struct StudyDashboardView: View {
    @EnvironmentObject var dataService: DataService
    
    private var chapters: [Chapter] { dataService.chapters }
    private var currentPlan: StudyPlan? { dataService.studyPlan }
    private var logs: [DailyLog] { dataService.dailyLogs }
    
    @State private var schedule: [Date: [StudyTask]] = [:]
    @State private var selectedDate: Date = Date()
    @State private var isShowingTimer = false
    
    @State private var isShowingSettings = false
    @State private var selectedLogTarget: LogTarget?
    @State private var selectedDayInfo: DayInfo?
    
    struct LogTarget: Identifiable {
        let id = UUID()
        let date: Date
        let chapter: Chapter
    }

    var todayTasks: [StudyTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return schedule[today] ?? []
    }
    
    // Main content view - extracted to help compiler
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private var mainContentView: some View {
        ScrollView {
            if sizeClass == .compact {
                // iPhone Layout (Vertical Stack)
                VStack(spacing: 24) {
                    TodayGoalView(
                        todayTasks: todayTasks,
                        chapters: chapters,
                        isFreeDay: { isFreeDay(date: $0) },
                        isFinished: isFinished,
                        hasLoggedToday: { 
                            let calendar = Calendar.current
                            return logs.contains { calendar.isDateInToday($0.date) && !$0.isFreeDay }
                        },
                        handleLog: { date, task in handleLog(date: date, task: task) }
                    )
                    
                    ScheduleView(
                        schedule: schedule,
                        selectedDate: $selectedDate,
                        isFreeDay: { isFreeDay(date: $0) },
                        toggleFreeDay: toggleFreeDay,
                        onLog: { date in handleLog(date: date) },
                        logs: logs,
                        chapters: chapters,
                        onSelectDay: { dayInfo in
                            selectedDayInfo = dayInfo
                        },
                        plan: currentPlan
                    )
                }
                .padding(.vertical)
            } else {
                // iPad Layout (Horizontal Split)
                HStack(alignment: .top, spacing: 32) {
                    // Left Column: Today's Goal & Insights
                    VStack(spacing: 24) {
                        TodayGoalView(
                            todayTasks: todayTasks,
                            chapters: chapters,
                            isFreeDay: { isFreeDay(date: $0) },
                            isFinished: isFinished,
                            hasLoggedToday: { 
                                let calendar = Calendar.current
                                return logs.contains { calendar.isDateInToday($0.date) && !$0.isFreeDay }
                            },
                            handleLog: { date, task in handleLog(date: date, task: task) }
                        )
                        
                        // Future: Add Insights or Stats here
                        Spacer()
                    }
                    .frame(maxWidth: 400) // Fixed width for sidebar-like feel
                    
                    // Right Column: Calendar
                    ScheduleView(
                        schedule: schedule,
                        selectedDate: $selectedDate,
                        isFreeDay: { isFreeDay(date: $0) },
                        toggleFreeDay: toggleFreeDay,
                        onLog: { date in handleLog(date: date) },
                        logs: logs,
                        chapters: chapters,
                        onSelectDay: { dayInfo in
                            selectedDayInfo = dayInfo
                        },
                        plan: currentPlan
                    )
                }
                .padding()
            }
        }
    }
    
    var body: some View {
        mainContentView
            .navigationTitle("Study Bloom")
            .toolbar { toolbarContent }
            .sheet(isPresented: $isShowingSettings) { settingsSheet }
            .sheet(item: $selectedLogTarget) { target in logSheet(target: target) }
            .sheet(item: $selectedDayInfo) { dayInfo in
                DayDetailView(
                    // ... existing closure content ...
                    dayInfo: dayInfo,
                    onAddLog: {
                        selectedDayInfo = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let task = dayInfo.scheduledTask,
                               let chapter = chapters.first(where: { $0.id == task.chapterId }) {
                                selectedLogTarget = LogTarget(date: dayInfo.date, chapter: chapter)
                            } else if let chapterTitle = dayInfo.chapterTitle,
                                      let chapter = chapters.first(where: { $0.title == chapterTitle }) {
                                selectedLogTarget = LogTarget(date: dayInfo.date, chapter: chapter)
                            } else if let firstUnfinished = chapters.first(where: { $0.pagesStudied < $0.totalPages }) {
                                selectedLogTarget = LogTarget(date: dayInfo.date, chapter: firstUnfinished)
                            }
                        }
                    },
                    onToggleFreeDay: {
                        toggleFreeDay(dayInfo.date)
                        selectedDayInfo = nil
                    },
                    onDeleteLog: { log in
                        deleteLog(log)
                        selectedDayInfo = nil 
                    }
                )
            }
            .fullScreenCover(isPresented: $isShowingTimer) {
                PomodoroView()
            }
            .onAppear { recalculateSchedule() }
            .onChange(of: logs) { _, _ in recalculateSchedule() }
            .onChange(of: chapters) { _, _ in recalculateSchedule() }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            NavigationLink(destination: AnalyticsView()) {
                Image(systemName: "chart.bar.xaxis")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Button(action: { isShowingTimer = true }) {
                    Image(systemName: "timer")
                }
                
                Button(action: { isShowingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
    
    // Settings sheet - extracted to help compiler
    private var settingsSheet: some View {
        PlanSettingsView()
            .onDisappear {
                recalculateSchedule()
            }
    }
    
    // Log sheet - extracted to help compiler
    private func logSheet(target: LogTarget) -> some View {
        LogProgressView(chapter: target.chapter) { newPages in
            handleProgressUpdate(target: target, newPages: newPages)
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
        Task {
            do {
                if let existingLog = logs.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    if existingLog.isFreeDay {
                        try await dataService.deleteDailyLog(existingLog)
                    } else {
                        var updatedLog = existingLog
                        updatedLog.isFreeDay = true
                        try await dataService.updateDailyLog(updatedLog)
                    }
                } else {
                    guard let userId = dataService.currentUserId else { return }
                    let newLog = DailyLog(userId: userId, date: date, pagesLearned: 0, chapterId: "", isFreeDay: true)
                    try await dataService.addDailyLog(newLog)
                }
            } catch {
                print("Error toggling free day: \(error.localizedDescription)")
            }
        }
        
        // Recalculate will happen via onChange of logs
    }
    
    private func deleteLog(_ log: DailyLog) {
        Task {
            do {
                // 1. Revert progress if it wasn't a free day marking
                if !log.isFreeDay {
                    if var chapter = chapters.first(where: { $0.id == log.chapterId }) {
                        chapter.pagesStudied = max(0, chapter.pagesStudied - log.pagesLearned)
                        try await dataService.updateChapter(chapter)
                    }
                }
                
                // 2. Delete the log
                try await dataService.deleteDailyLog(log)
            } catch {
                print("Error deleting log: \(error.localizedDescription)")
            }
        }
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
    
    private func handleProgressUpdate(target: LogTarget, newPages: Int) {
        var updatedChapter = target.chapter
        let delta = newPages - updatedChapter.pagesStudied
        updatedChapter.pagesStudied = newPages
        
        Task {
            do {
                try await dataService.updateChapter(updatedChapter)
                
                if delta > 0 {
                    let log = DailyLog(userId: updatedChapter.userId, date: target.date, pagesLearned: delta, chapterId: updatedChapter.id)
                    try await dataService.addDailyLog(log)
                }
            } catch {
                print("Error updating progress: \(error.localizedDescription)")
            }
        }
        
        // Trigger schedule recalculation
        recalculateSchedule()
    }

    }


struct TodayGoalView: View {
    let todayTasks: [StudyTask]
    let chapters: [Chapter]
    let isFreeDay: (Date) -> Bool
    let isFinished: () -> Bool
    let hasLoggedToday: () -> Bool
    let handleLog: (Date, StudyTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Goal")
                .font(.title2)
                .fontWeight(.bold)
            
            if todayTasks.isEmpty {
                if isFreeDay(Date()) {
                    FreeDayCard()
                } else if chapters.isEmpty {
                    EmptyStateCard(message: "Add chapters to start planning.")
                } else if isFinished() {
                    FinishedCard()
                } else if hasLoggedToday() {
                    DailyGoalFinishedCard()
                } else {
                    Text("No tasks scheduled.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(todayTasks) { task in
                    TaskCard(task: task) {
                        handleLog(Date(), task)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ScheduleView: View {
    let schedule: [Date: [StudyTask]]
    @Binding var selectedDate: Date
    let isFreeDay: (Date) -> Bool
    let toggleFreeDay: (Date) -> Void
    let onLog: (Date) -> Void
    let logs: [DailyLog]
    let chapters: [Chapter]
    // New props to pass to CalendarGridView and handle selection
    let onSelectDay: (DayInfo) -> Void
    let plan: StudyPlan?
    
    var body: some View {
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
                logs: logs,
                chapters: chapters,
                plan: plan,
                onSelectDay: onSelectDay
            )
        }
        .padding(.horizontal)
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
    let logs: [DailyLog]
    let chapters: [Chapter]
    let plan: StudyPlan?
    let onSelectDay: (DayInfo) -> Void
    
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
            // Weekday headers - Separated to avoid ID conflict and static layout
            LazyVGrid(columns: columns, spacing: 8) {
                let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdays[index])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Calendar Grid with Swipe
            LazyVGrid(columns: columns, spacing: 8) {
                // Days
                if let firstDay = days.first {
                    let weekday = calendar.component(.weekday, from: firstDay)
                    // Convert to Monday-start offset: Mon(2)->0, ... Sun(1)->6
                    let offset = (weekday + 5) % 7
                    ForEach(0..<offset, id: \.self) { _ in
                        Spacer()
                    }
                }
                
                ForEach(days, id: \.self) { date in
                    let dayInfo = CalendarHelper.getDayInfo(
                        for: date,
                        schedule: schedule,
                        logs: logs,
                        chapters: chapters,
                        plan: plan
                    )
                    
                    CalendarDayCell(
                        dayInfo: dayInfo,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                    )
                    .onTapGesture {
                        selectedDate = date
                        onSelectDay(dayInfo)
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

struct DailyGoalFinishedCard: View {
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text("Daily Goal Met!")
                    .font(.headline)
                Text("Great job! Continue tomorrow.")
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
