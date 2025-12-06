import Foundation
import FirebaseFirestore

struct FriendRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var senderUsername: String
    var receiverId: String
    var status: RequestStatus
    var timestamp: Date
    
    init(
        id: String? = nil,
        senderId: String,
        senderName: String,
        senderUsername: String,
        receiverId: String,
        status: RequestStatus = .pending,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.senderUsername = senderUsername
        self.receiverId = receiverId
        self.status = status
        self.timestamp = timestamp
    }
}

enum RequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct Friendship: Codable, Identifiable {
    @DocumentID var id: String?
    var user1Id: String
    var user2Id: String
    var becameFriendsAt: Date
    
    init(
        id: String? = nil,
        user1Id: String,
        user2Id: String,
        becameFriendsAt: Date = Date()
    ) {
        self.id = id
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.becameFriendsAt = becameFriendsAt
    }
    
    // Helper to check if a specific user is part of this friendship
    func contains(userId: String) -> Bool {
        return user1Id == userId || user2Id == userId
    }
    
    // Get the other user's ID in this friendship
    func otherUser(from userId: String) -> String? {
        if user1Id == userId {
            return user2Id
        } else if user2Id == userId {
            return user1Id
        }
        return nil
    }
}
