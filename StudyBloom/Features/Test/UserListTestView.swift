import SwiftUI

struct UserListTestView: View {
    @StateObject private var firebaseService = FirebaseService()
    
    var body: some View {
        NavigationView {
            ZStack {
                if firebaseService.isLoading {
                    ProgressView("Loading users...")
                } else if let error = firebaseService.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            firebaseService.fetchUsers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if firebaseService.users.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No users found")
                            .font(.headline)
                        Text("Add users to the 'users' collection in Firestore")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(firebaseService.users) { user in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Firebase Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    UserListTestView()
}
