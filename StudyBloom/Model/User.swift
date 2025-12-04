import Foundation

struct User: Identifiable, Codable {
    var id: String?
    var name: String
    var email: String
    var educationLevel: String?
    var learningFocus: String?
    var createdAt: Date?
    var updatedAt: Date?
}
