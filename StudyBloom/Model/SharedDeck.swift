import Foundation
import FirebaseFirestore

struct SharedDeck: Codable, Identifiable {
    @DocumentID var id: String?
    var ownerId: String
    var ownerName: String
    var ownerUsername: String
    var title: String
    var description: String
    var flashcards: [Flashcard]
    var visibility: DeckVisibility
    var sharedWith: [String] // User IDs
    var createdAt: Date
    var updatedAt: Date
    var downloads: Int
    var rating: Double
    
    init(
        id: String? = nil,
        ownerId: String,
        ownerName: String,
        ownerUsername: String,
        title: String,
        description: String = "",
        flashcards: [Flashcard] = [],
        visibility: DeckVisibility = .private,
        sharedWith: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        downloads: Int = 0,
        rating: Double = 0.0
    ) {
        self.id = id
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.ownerUsername = ownerUsername
        self.title = title
        self.description = description
        self.flashcards = flashcards
        self.visibility = visibility
        self.sharedWith = sharedWith
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.downloads = downloads
        self.rating = rating
    }
    
    // Check if a user can access this deck
    func canAccess(userId: String, isFriend: Bool) -> Bool {
        // Owner can always access
        if userId == ownerId {
            return true
        }
        
        // Public decks are accessible to everyone
        if visibility == .public {
            return true
        }
        
        // Friends-only decks
        if visibility == .friends && isFriend {
            return true
        }
        
        // Explicitly shared with user (Specific)
        if visibility == .specific && sharedWith.contains(userId) {
            return true
        }
        
        // Legacy/Fallback: checking sharedWith regardless of visibility type, 
        // though typically specific usage implies the .specific type.
        if sharedWith.contains(userId) {
            return true
        }
        
        return false
    }
}

enum DeckVisibility: String, Codable, CaseIterable {
    case `private`
    case friends
    case `public`
    case specific
}
