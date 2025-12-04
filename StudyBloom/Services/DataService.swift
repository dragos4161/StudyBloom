import Foundation
import Combine
import FirebaseFirestore

class DataService: ObservableObject {
    @Published var chapters: [Chapter] = []
    @Published var studyPlan: StudyPlan?
    @Published var dailyLogs: [DailyLog] = []
    @Published var flashcards: [Flashcard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var chaptersListener: ListenerRegistration?
    private var studyPlanListener: ListenerRegistration?
    private var dailyLogsListener: ListenerRegistration?
    private var flashcardsListener: ListenerRegistration?
    var currentUserId: String?
    
    deinit {
        removeListeners()
    }
    
    // MARK: - Initialization
    
    func initializeForUser(userId: String) {
        guard userId != currentUserId else { return }
        
        // Remove old listeners if switching users
        removeListeners()
        currentUserId = userId
        
        // Start fetching data for new user
        fetchChapters(userId: userId)
        fetchStudyPlan(userId: userId)
        fetchDailyLogs(userId: userId)
        fetchFlashcards(userId: userId)
    }
    
    func removeListeners() {
        chaptersListener?.remove()
        studyPlanListener?.remove()
        dailyLogsListener?.remove()
        flashcardsListener?.remove()
        
        chaptersListener = nil
        studyPlanListener = nil
        dailyLogsListener = nil
        flashcardsListener = nil
        currentUserId = nil
        
        // Clear data
        chapters = []
        studyPlan = nil
        dailyLogs = []
        flashcards = []
    }
    
    // MARK: - Chapters
    
    func fetchChapters(userId: String) {
        isLoading = true
        errorMessage = nil
        
        chaptersListener = db.collection("users").document(userId).collection("chapters")
            .order(by: "orderIndex")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("❌ Error fetching chapters: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.chapters = []
                    return
                }
                
                self.chapters = documents.compactMap { document -> Chapter? in
                    var chapter = try? document.data(as: Chapter.self)
                    chapter?.id = document.documentID
                    return chapter
                }
                
                print("✅ Fetched \(self.chapters.count) chapters")
            }
    }
    
    func addChapter(_ chapter: Chapter) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        var newChapter = chapter
        newChapter.userId = userId
        newChapter.createdAt = Date()
        newChapter.updatedAt = Date()
        
        let docRef = db.collection("users").document(userId).collection("chapters").document(newChapter.id)
        
        do {
            try docRef.setData(from: newChapter)
            print("✅ Added chapter: \(newChapter.title)")
        } catch {
            print("❌ Error adding chapter: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateChapter(_ chapter: Chapter) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        var updatedChapter = chapter
        updatedChapter.updatedAt = Date()
        
        let docRef = db.collection("users").document(userId).collection("chapters").document(chapter.id)
        
        do {
            try docRef.setData(from: updatedChapter, merge: true)
            print("✅ Updated chapter: \(chapter.title)")
        } catch {
            print("❌ Error updating chapter: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteChapter(_ chapter: Chapter) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let docRef = db.collection("users").document(userId).collection("chapters").document(chapter.id)
        
        do {
            try await docRef.delete()
            print("✅ Deleted chapter: \(chapter.title)")
        } catch {
            print("❌ Error deleting chapter: \(error.localizedDescription)")
            throw error
        }
    }
    
    func reorderChapters(_ chapters: [Chapter]) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let batch = db.batch()
        
        for (index, chapter) in chapters.enumerated() {
            var updatedChapter = chapter
            updatedChapter.orderIndex = index
            updatedChapter.updatedAt = Date()
            
            let docRef = db.collection("users").document(userId).collection("chapters").document(chapter.id)
            
            do {
                try batch.setData(from: updatedChapter, forDocument: docRef, merge: true)
            } catch {
                print("❌ Error encoding chapter for batch: \(error.localizedDescription)")
                throw error
            }
        }
        
        do {
            try await batch.commit()
            print("✅ Reordered \(chapters.count) chapters")
        } catch {
            print("❌ Error reordering chapters: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Study Plan
    
    func fetchStudyPlan(userId: String) {
        isLoading = true
        errorMessage = nil
        
        studyPlanListener = db.collection("users").document(userId).collection("studyPlan")
            .document("default")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("❌ Error fetching study plan: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    self.studyPlan = try? snapshot.data(as: StudyPlan.self)
                    print("✅ Fetched study plan")
                } else {
                    // Create default plan if none exists
                    Task {
                        try? await self.createDefaultPlan(userId: userId)
                    }
                }
            }
    }
    
    func saveStudyPlan(_ plan: StudyPlan) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        var updatedPlan = plan
        updatedPlan.userId = userId
        updatedPlan.updatedAt = Date()
        
        if updatedPlan.createdAt == nil {
            updatedPlan.createdAt = Date()
        }
        
        let docRef = db.collection("users").document(userId).collection("studyPlan").document("default")
        
        do {
            try docRef.setData(from: updatedPlan, merge: true)
            print("✅ Saved study plan")
        } catch {
            print("❌ Error saving study plan: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createDefaultPlan(userId: String) async throws {
        let defaultPlan = StudyPlan(userId: userId, dailyPageGoal: 10, startDate: Date(), freeDays: [])
        
        let docRef = db.collection("users").document(userId).collection("studyPlan").document("default")
        
        do {
            try docRef.setData(from: defaultPlan)
            print("✅ Created default study plan")
        } catch {
            print("❌ Error creating default plan: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Daily Logs
    
    func fetchDailyLogs(userId: String) {
        isLoading = true
        errorMessage = nil
        
        dailyLogsListener = db.collection("users").document(userId).collection("dailyLogs")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("❌ Error fetching daily logs: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.dailyLogs = []
                    return
                }
                
                self.dailyLogs = documents.compactMap { document -> DailyLog? in
                    var log = try? document.data(as: DailyLog.self)
                    log?.id = document.documentID
                    return log
                }
                
                print("✅ Fetched \(self.dailyLogs.count) daily logs")
            }
    }
    
    func addDailyLog(_ log: DailyLog) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        var newLog = log
        newLog.userId = userId
        newLog.createdAt = Date()
        
        let logId = newLog.id ?? UUID().uuidString
        newLog.id = logId
        
        let docRef = db.collection("users").document(userId).collection("dailyLogs").document(logId)
        
        do {
            try docRef.setData(from: newLog)
            print("✅ Added daily log")
            
            // Notify NotificationManager about study activity
            DispatchQueue.main.async {
                NotificationManager.shared.userDidStudy(pages: newLog.pagesLearned)
            }
        } catch {
            print("❌ Error adding daily log: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateDailyLog(_ log: DailyLog) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        guard let logId = log.id else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Log ID is required"])
        }
        
        let docRef = db.collection("users").document(userId).collection("dailyLogs").document(logId)
        
        do {
            try docRef.setData(from: log, merge: true)
            print("✅ Updated daily log")
            
            // Notify NotificationManager about study activity
            DispatchQueue.main.async {
                NotificationManager.shared.userDidStudy(pages: log.pagesLearned)
            }
        } catch {
            print("❌ Error updating daily log: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteDailyLog(_ log: DailyLog) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        guard let logId = log.id else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Log ID is required"])
        }
        
        let docRef = db.collection("users").document(userId).collection("dailyLogs").document(logId)
        
        do {
            try await docRef.delete()
            print("✅ Deleted daily log")
        } catch {
            print("❌ Error deleting daily log: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    // MARK: - Flashcards
    
    func fetchFlashcards(userId: String) {
        isLoading = true
        errorMessage = nil
        
        flashcardsListener = db.collection("users").document(userId).collection("flashcards")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("❌ Error fetching flashcards: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.flashcards = []
                    return
                }
                
                self.flashcards = documents.compactMap { document -> Flashcard? in
                    var flashcard = try? document.data(as: Flashcard.self)
                    // Ensure ID is set if missing in data but present in documentID
                    // Note: Flashcard struct has 'let id', so we rely on it being in the data or decoding correctly.
                    // If we need to inject ID, Flashcard struct might need 'var id' or custom decoding.
                    // Assuming Flashcard is Codable and id is part of it.
                    return flashcard
                }
                
                print("✅ Fetched \(self.flashcards.count) flashcards")
            }
    }
    
    func addFlashcard(_ flashcard: Flashcard) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let docRef = db.collection("users").document(userId).collection("flashcards").document(flashcard.id)
        
        do {
            try docRef.setData(from: flashcard)
            print("✅ Added flashcard: \(flashcard.front)")
        } catch {
            print("❌ Error adding flashcard: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateFlashcard(_ flashcard: Flashcard) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let docRef = db.collection("users").document(userId).collection("flashcards").document(flashcard.id)
        
        do {
            try docRef.setData(from: flashcard, merge: true)
            print("✅ Updated flashcard: \(flashcard.front)")
        } catch {
            print("❌ Error updating flashcard: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteFlashcard(_ flashcard: Flashcard) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let docRef = db.collection("users").document(userId).collection("flashcards").document(flashcard.id)
        
        do {
            try await docRef.delete()
            print("✅ Deleted flashcard")
        } catch {
            print("❌ Error deleting flashcard: \(error.localizedDescription)")
            throw error
        }
    }
}
