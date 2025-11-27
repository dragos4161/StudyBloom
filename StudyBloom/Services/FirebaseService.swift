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
}
