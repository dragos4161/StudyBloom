import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class SocialService: ObservableObject {
    static let shared = SocialService()
    
    private let db = Firestore.firestore()
    @Published var pendingRequests: [FriendRequest] = []
    @Published var friends: [UserProfile] = []
    
    private var requestsListener: ListenerRegistration?
    private var friendsListener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to userId: String, recipientName: String, recipientUsername: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SocialService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get current user's profile
        let currentUserProfile = try await fetchUserProfile(userId: currentUserId)
        
        // Check if request already exists
        let existingRequests = try await db.collection("friendRequests")
            .whereField("senderId", isEqualTo: currentUserId)
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !existingRequests.documents.isEmpty {
            throw NSError(domain: "SocialService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"])
        }
        
        let request = FriendRequest(
            senderId: currentUserId,
            senderName: currentUserProfile.displayName,
            senderUsername: currentUserProfile.username,
            receiverId: userId
        )
        
        try db.collection("friendRequests").addDocument(from: request)
    }
    
    func acceptFriendRequest(_ requestId: String) async throws {
        let requestRef = db.collection("friendRequests").document(requestId)
        let requestDoc = try await requestRef.getDocument()
        
        guard let request = try? requestDoc.data(as: FriendRequest.self) else {
            throw NSError(domain: "SocialService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Request not found"])
        }
        
        // Update request status
        try await requestRef.updateData(["status": "accepted"])
        
        // Create friendship
        let friendship = Friendship(
            user1Id: request.senderId,
            user2Id: request.receiverId
        )
        try db.collection("friendships").addDocument(from: friendship)
        
        // Send notification to sender
        NotificationManager.shared.notifyFriendshipAccepted(userName: request.senderName)
    }
    
    func declineFriendRequest(_ requestId: String) async throws {
        try await db.collection("friendRequests")
            .document(requestId)
            .updateData(["status": "declined"])
    }
    
    func fetchPendingRequests() async throws -> [FriendRequest] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        let snapshot = try await db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: FriendRequest.self) }
    }
    
    func fetchPendingRequestsCount() async throws -> Int {
        guard let userId = Auth.auth().currentUser?.uid else { return 0 }
        
        let snapshot = try await db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    // MARK: - Friends Management
    
    func fetchFriends() async throws -> [UserProfile] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        // Get all friendships
        let snapshot1 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: userId)
            .getDocuments()
        
        let snapshot2 = try await db.collection("friendships")
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments()
        
        let friendships = (snapshot1.documents + snapshot2.documents)
            .compactMap { try? $0.data(as: Friendship.self) }
        
        // Get friend IDs
        let friendIds = friendships.compactMap { $0.otherUser(from: userId) }
        
        // Fetch friend profiles
        var friends: [UserProfile] = []
        for friendId in friendIds {
            if let profile = try? await fetchUserProfile(userId: friendId) {
                friends.append(profile)
            }
        }
        
        return friends
    }
    
    func removeFriend(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Find friendship
        let snapshot1 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: currentUserId)
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments()
        
        let snapshot2 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: userId)
            .whereField("user2Id", isEqualTo: currentUserId)
            .getDocuments()
        
        let friendships = snapshot1.documents + snapshot2.documents
        
        for doc in friendships {
            try await doc.reference.delete()
        }
    }
    
    func searchUsers(query: String) async throws -> [UserProfile] {
        guard query.count >= 2 else { return [] }
        
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("username", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let profile = try? doc.data(as: UserProfile.self) else {
            throw NSError(domain: "SocialService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return profile
    }
    
    // MARK: - Friendship Status
    
    enum FriendStatus {
        case notFriends
        case friend
        case requestSent
        case requestReceived
        case selfProfile
    }
    
    func checkFriendshipStatus(with userId: String) async throws -> FriendStatus {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return .notFriends }
        
        if currentUserId == userId {
            return .selfProfile
        }
        
        // 1. Check if already friends
        // We can check our local friends list since it's populated
        if friends.contains(where: { $0.id == userId }) {
            return .friend
        }
        
        // If local list isn't populated or to be sure, check Firestore
        let friendshipQuery = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: currentUserId)
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments()
            
        let friendshipQuery2 = try await db.collection("friendships")
            .whereField("user1Id", isEqualTo: userId)
            .whereField("user2Id", isEqualTo: currentUserId)
            .getDocuments()
            
        if !friendshipQuery.documents.isEmpty || !friendshipQuery2.documents.isEmpty {
            return .friend
        }
        
        // 2. Check if request sent by me
        let sentRequest = try await db.collection("friendRequests")
            .whereField("senderId", isEqualTo: currentUserId)
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
            
        if !sentRequest.documents.isEmpty {
            return .requestSent
        }
        
        // 3. Check if request received from them
        let receivedRequest = try await db.collection("friendRequests")
            .whereField("senderId", isEqualTo: userId)
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
            
        if !receivedRequest.documents.isEmpty {
            return .requestReceived
        }
        
        return .notFriends
    }
    
    // MARK: - Flashcard Sharing
    
    func shareFlashcardDeck(_ deck: SharedDeck) async throws {
        try db.collection("sharedDecks").addDocument(from: deck)
    }
    
    func fetchSharedDecks(from userId: String) async throws -> [SharedDeck] {
        let snapshot = try await db.collection("sharedDecks")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: SharedDeck.self) }
    }
    
    func fetchPublicDecks() async throws -> [SharedDeck] {
        let snapshot = try await db.collection("sharedDecks")
            .whereField("visibility", isEqualTo: "public")
            .order(by: "downloads", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: SharedDeck.self) }
    }
    
    func importSharedDeck(_ deckId: String) async throws -> [Flashcard] {
        let doc = try await db.collection("sharedDecks").document(deckId).getDocument()
        guard let deck = try? doc.data(as: SharedDeck.self) else {
            throw NSError(domain: "SocialService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Deck not found"])
        }
        
        // Increment download count
        try await doc.reference.updateData(["downloads": deck.downloads + 1])
        
        return deck.flashcards
    }
    
    // MARK: - Real-time Listeners
    
    func startListeningForFriendRequests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        requestsListener = db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.pendingRequests = documents.compactMap { try? $0.data(as: FriendRequest.self) }
                
                // Update badge
                Task {
                    await BadgeManager.shared.updateFriendRequestBadge()
                }
            }
    }
    
    func stopListeners() {
        requestsListener?.remove()
        friendsListener?.remove()
    }
}
