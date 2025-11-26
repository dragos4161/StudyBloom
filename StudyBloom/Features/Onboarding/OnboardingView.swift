import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage(
                imageName: "book.fill",
                title: "Welcome to Study Bloom",
                description: "Your personal companion for mastering your residency exams.",
                color: .blue
            )
            .tag(0)
            
            OnboardingPage(
                imageName: "calendar",
                title: "Plan Your Study",
                description: "Create a study plan that fits your schedule and track your progress daily.",
                color: .purple
            )
            .tag(1)
            
            OnboardingInputPage(
                userName: $userName,
                userEmail: $userEmail,
                onFinish: {
                    hasCompletedOnboarding = true
                }
            )
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct OnboardingPage: View {
    let imageName: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(color)
                .padding()
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingInputPage: View {
    @Binding var userName: String
    @Binding var userEmail: String
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Let's get to know you")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TextField("Your Name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.name)
                
                TextField("Email Address", text: $userEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal)
            
            Button(action: onFinish) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(userName.isEmpty || userEmail.isEmpty)
            .opacity(userName.isEmpty || userEmail.isEmpty ? 0.6 : 1.0)
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
