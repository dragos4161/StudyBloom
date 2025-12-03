import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                    .textContentType(.name)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .onAppear {
            if let user = authService.user {
                name = user.name
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.updateUserName(name)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView()
            .environmentObject(AuthService())
    }
}
