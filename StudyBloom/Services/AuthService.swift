import Foundation
import Combine
// import FirebaseAuth // Uncomment when Firebase is added

class AuthService: ObservableObject {
    @Published var user: User?
    
    func signIn() {
        // TODO: Implement Firebase Sign In
    }
    
    func signOut() {
        // TODO: Implement Firebase Sign Out
    }
}
