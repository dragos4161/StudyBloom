import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var username: String // Unique, searchable (e.g., @johndoe)
    var profileImageUrl: String?
    var studyStreak: Int
    var totalStudyTime: TimeInterval
    var privacySettings: PrivacySettings
    var createdAt: Date
    
    init(
        id: String? = nil,
        displayName: String,
        username: String,
        profileImageUrl: String? = nil,
        studyStreak: Int = 0,
        totalStudyTime: TimeInterval = 0,
        privacySettings: PrivacySettings = PrivacySettings(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.profileImageUrl = profileImageUrl
        self.studyStreak = studyStreak
        self.totalStudyTime = totalStudyTime
        self.privacySettings = privacySettings
        self.createdAt = createdAt
    }
}

struct PrivacySettings: Codable {
    var profileVisibility: Visibility
    var statsVisibility: Visibility
    var allowFriendRequests: Bool
    
    init(
        profileVisibility: Visibility = .friends,
        statsVisibility: Visibility = .friends,
        allowFriendRequests: Bool = true
    ) {
        self.profileVisibility = profileVisibility
        self.statsVisibility = statsVisibility
        self.allowFriendRequests = allowFriendRequests
    }
}

enum Visibility: String, Codable {
    case `private`
    case friends
    case `public`
}
