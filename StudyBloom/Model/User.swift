import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    var displayName: String?
    var joinedDate: Date
    
    // Add other profile fields as needed
}
