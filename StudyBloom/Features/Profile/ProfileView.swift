import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text(authService.user?.name ?? "Student Name")
                                .font(.headline)
                            Text(authService.user?.email ?? "student@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink("Edit Profile") {
                        EditProfileView()
                    }
                }
                
                Section(header: Text("Settings")) {
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                Section {
                    Button("Sign Out") {
                        authService.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
