import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import CryptoKit

class AuthService: NSObject, ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private var currentNonce: String?
    private let firebaseService = FirebaseService()
    
    override init() {
        super.init()
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                self.user = User(
                    id: firebaseUser.uid,
                    name: firebaseUser.displayName ?? "User",
                    email: firebaseUser.email ?? ""
                )
                self.isAuthenticated = true
            } else {
                self.user = nil
                self.isAuthenticated = false
            }
        }
    }
    
    func startSignInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    func updateUserProfile(name: String, educationLevel: String?, learningFocus: String?) async throws {
        guard var currentUser = user else { return }
        currentUser.name = name
        currentUser.educationLevel = educationLevel
        currentUser.learningFocus = learningFocus
        
        // Update local state
        self.user = currentUser
        
        // Update Firebase Profile (Display Name only)
        if let firebaseUser = Auth.auth().currentUser {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
        }
        
        // Update Firestore
        try await firebaseService.createOrUpdateUser(currentUser)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // Extract name if available (only on first sign in)
            var fullNameString: String?
            if let fullName = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                fullNameString = formatter.string(from: fullName)
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            
            isLoading = true
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("❌ Firebase Authentication Error:")
                    print("Error Code: \(error._code)")
                    print("Error Domain: \((error as NSError).domain)")
                    print("Description: \(error.localizedDescription)")
                    print("Full Error: \(error)")
                    return
                }
                
                print("✅ User signed in with Apple successfully!")
                
                if let firebaseUser = authResult?.user {
                    // Determine the display name to use
                    // Priority: 1. Name from Apple Credential (first sign in), 2. Existing Firebase Display Name, 3. Default "Student"
                    // We use "Student" as a better default than "User"
                    let displayName = fullNameString ?? firebaseUser.displayName ?? "Student"
                    
                    // Update Firebase User Profile if we have a new name and it differs
                    if let newName = fullNameString, newName != firebaseUser.displayName {
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        changeRequest.displayName = newName
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error updating firebase profile: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    // Create user model for Firestore
                    let user = User(
                        id: firebaseUser.uid,
                        name: displayName,
                        email: firebaseUser.email ?? ""
                    )
                    
                    // Update local user state immediately
                    self.user = user
                    self.isAuthenticated = true
                    
                    Task {
                        do {
                            try await self.firebaseService.createOrUpdateUser(user)
                        } catch {
                            print("❌ Failed to create/update user in Firestore: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In Error:")
        print("Description: \(error.localizedDescription)")
        print("Full Error: \(error)")
        isLoading = false
    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}
