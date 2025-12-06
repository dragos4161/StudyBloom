import Foundation


struct StudyTask: Identifiable {
    let id = UUID()
    let date: Date
    let chapterId: String
    let chapterTitle: String
    let pagesToRead: Int
    let startPage: Int
    let endPage: Int
    let colorHex: String
}

class StudyPlanner {
    static func calculateSchedule(
        chapters: [Chapter],
        plan: StudyPlan,
        logs: [DailyLog]
    ) -> [Date: [StudyTask]] {
        var schedule: [Date: [StudyTask]] = [:]
        
        // Sort chapters by order
        let sortedChapters = chapters.sorted { $0.orderIndex < $1.orderIndex }
        
        // Determine start date (today or plan start)
        // We usually want to plan from "today" onwards, respecting past logs
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        
        // Calculate remaining pages for each chapter
        // We need to account for what has already been studied
        // However, the prompt implies "pagesStudied" is the source of truth for progress.
        // So we plan for (totalPages - pagesStudied).
        
        var chapterQueue: [(chapter: Chapter, remaining: Int)] = sortedChapters.compactMap { chapter in
            let remaining = chapter.totalPages - chapter.pagesStudied
            return remaining > 0 ? (chapter, remaining) : nil
        }
        
        // If no chapters left, return empty
        if chapterQueue.isEmpty { return [:] }
        
        // Iterate days
        // Safety break to prevent infinite loop
        var daysProcessed = 0
        while !chapterQueue.isEmpty && daysProcessed < 365 {
            // Check if free day
            // plan.freeDays contains weekday integers (1=Sun, ..., 7=Sat)
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Check if this specific date is marked as free in logs (override)
            let isLogFree = logs.contains { calendar.isDate($0.date, inSameDayAs: currentDate) && $0.isFreeDay }
            let isPlanFree = plan.freeDays.contains(weekday)
            
            if isLogFree || isPlanFree {
                // Skip this day
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                daysProcessed += 1
                continue
            }
            
            // CHECK: If scheduling for Today, check if we already finished a chapter today.
            // If so, we skip Today effectively (currentDate ++).
            if calendar.isDateInToday(currentDate) {
                 let todayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: currentDate) && !$0.isFreeDay }
                 if let log = todayLogs.first, let finishedChapter = chapters.first(where: { $0.id == log.chapterId }), finishedChapter.pagesStudied >= finishedChapter.totalPages {
                     // We finished a chapter today! Don't schedule more.
                     currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                     daysProcessed += 1
                     continue
                 }
            }
            
            // Allocate pages
            var dailyCapacity = plan.dailyPageGoal
            var tasksForDay: [StudyTask] = []
            
            while dailyCapacity > 0 && !chapterQueue.isEmpty {
                var currentChapterInfo = chapterQueue[0]
                let pagesToTake = min(dailyCapacity, currentChapterInfo.remaining)
                
                // Calculate page range (approximate for display)
                let startPage = currentChapterInfo.chapter.pagesStudied + (currentChapterInfo.chapter.totalPages - currentChapterInfo.chapter.pagesStudied - currentChapterInfo.remaining) + 1
                let endPage = startPage + pagesToTake - 1
                
                let task = StudyTask(
                    date: currentDate,
                    chapterId: currentChapterInfo.chapter.id,
                    chapterTitle: currentChapterInfo.chapter.title,
                    pagesToRead: pagesToTake,
                    startPage: startPage,
                    endPage: endPage,
                    colorHex: currentChapterInfo.chapter.colorHex
                )
                tasksForDay.append(task)
                
                // Update tracking
                dailyCapacity -= pagesToTake
                chapterQueue[0].remaining -= pagesToTake
                
                // Remove chapter if done
                if chapterQueue[0].remaining <= 0 {
                    chapterQueue.removeFirst()
                }
                
                // Enforce one chapter per day: Break after assigning one task
                break
            }
            
            if !tasksForDay.isEmpty {
                schedule[currentDate] = tasksForDay
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            daysProcessed += 1
        }
        
        return schedule
    }
}
