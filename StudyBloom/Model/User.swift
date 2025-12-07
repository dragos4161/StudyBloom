import Foundation

struct User: Identifiable, Codable {
    var id: String?
    var name: String
    var username: String?
    var email: String
    var educationLevel: String?
    var learningFocus: String?
    var studyStreak: Int = 0
    var totalStudyTime: TimeInterval = 0
    var privacySettings: PrivacySettings = PrivacySettings()
    var createdAt: Date?
    var updatedAt: Date?
}
