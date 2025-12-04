import Foundation

struct Flashcard: Identifiable, Codable {
    let id: String
    var userId: String
    var front: String
    var back: String
    var chapterId: String? // Optional link to a specific chapter
    
    // Spaced Repetition fields
    var interval: Int = 0 // Days until next review
    var repetition: Int = 0
    var easeFactor: Double = 2.5
    var nextReviewDate: Date = Date()
    
    var isDue: Bool {
        return Date() >= nextReviewDate
    }
}
