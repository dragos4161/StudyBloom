import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var educationLevel: String = "College"
    @State private var learningFocus: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let educationLevels = ["Middle School", "High School", "College", "Med School / Residency", "Other"]
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                    .textContentType(.name)
            }
            
            Section(header: Text("Education")) {
                Picker("Level", selection: $educationLevel) {
                    ForEach(educationLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                
                TextField("Learning Focus (e.g. Anatomy)", text: $learningFocus)
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
                educationLevel = user.educationLevel ?? "College"
                learningFocus = user.learningFocus ?? ""
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
                try await authService.updateUserProfile(
                    name: name,
                    educationLevel: educationLevel,
                    learningFocus: learningFocus
                )
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
