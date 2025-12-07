import Foundation

struct User: Identifiable, Codable {
    var id: String?
    var name: String
    var username: String?
    var email: String
    var educationLevel: String?
    var learningFocus: String?
    var studyStreak: Int?
    var totalStudyTime: TimeInterval?
    var privacySettings: PrivacySettings?
    var createdAt: Date?
    var updatedAt: Date?
}
