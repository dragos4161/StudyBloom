import Foundation
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchUsers()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchUsers() {
        isLoading = true
        errorMessage = nil
        
        listener = db.collection("users").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.errorMessage = "No users found"
                return
            }
            
            self.users = documents.compactMap { document -> User? in
                var user = try? document.data(as: User.self)
                user?.id = document.documentID
                return user
            }
        }
    }
    
    func createOrUpdateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is required"])
        }
        
        let userRef = db.collection("users").document(userId)
        
        do {
            // Check if user already exists
            let document = try await userRef.getDocument()
            
            if document.exists {
                // User exists - update only the updatedAt timestamp
                try await userRef.updateData([
                    "updatedAt": Timestamp(date: Date())
                ])
                print("✅ Updated existing user: \(userId)")
            } else {
                // New user - create with all data including timestamps
                var newUser = user
                let now = Date()
                newUser.createdAt = now
                newUser.updatedAt = now
                
                try userRef.setData(from: newUser)
                print("✅ Created new user in Firestore: \(userId)")
            }
        } catch {
            print("❌ Error creating/updating user in Firestore: \(error.localizedDescription)")
            throw error
        }
    }
}
