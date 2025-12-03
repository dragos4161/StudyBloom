import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var authService: AuthService
    
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
            
            OnboardingSignInPage(
                onSignInComplete: {
                    hasCompletedOnboarding = true
                }
            )
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                hasCompletedOnboarding = true
            }
        }
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

struct OnboardingSignInPage: View {
    @EnvironmentObject var authService: AuthService
    var onSignInComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())
            
            Text("Get Started")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Sign in to save your progress and sync across devices.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if authService.isLoading {
                ProgressView()
                    .padding()
            } else {
                Button(action: {
                    authService.startSignInWithApple()
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.headline)
                        Text("Sign in with Apple")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
}
