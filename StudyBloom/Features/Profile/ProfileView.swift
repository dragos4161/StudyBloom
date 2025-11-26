import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    
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
                            Text(userName.isEmpty ? "Student Name" : userName)
                                .font(.headline)
                            Text(userEmail.isEmpty ? "student@example.com" : userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink("Edit Profile") {
                        Text("Edit Profile View")
                    }
                }
                
                Section(header: Text("Settings")) {
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: .constant(false))
                }
                
                Section {
                    Button("Sign Out") {
                        // Sign out action
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
}
