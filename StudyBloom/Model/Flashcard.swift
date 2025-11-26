import Foundation

struct Flashcard: Identifiable, Codable {
    let id: String
    let userId: String
    let front: String
    let back: String
    
    // Spaced Repetition fields
    var interval: Int = 0 // Days until next review
    var repetition: Int = 0
    var easeFactor: Double = 2.5
    var nextReviewDate: Date = Date()
    
    var isDue: Bool {
        return Date() >= nextReviewDate
    }
}
