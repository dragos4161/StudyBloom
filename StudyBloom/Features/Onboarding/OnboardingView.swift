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
            
            OnboardingProfilePage(
                educationLevel: $educationLevel,
                learningFocus: $learningFocus
            )
            .tag(2)
            
            OnboardingSignInPage(
                educationLevel: educationLevel,
                learningFocus: learningFocus,
                onSignInComplete: {
                    hasCompletedOnboarding = true
                }
            )
            .tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                hasCompletedOnboarding = true
            }
        }
    }
    
    @State private var educationLevel: String = "College"
    @State private var learningFocus: String = ""
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

struct OnboardingProfilePage: View {
    @Binding var educationLevel: String
    @Binding var learningFocus: String
    
    let educationLevels = ["Middle School", "High School", "College", "Med School / Residency", "Other"]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "graduationcap.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
            
            Text("Tell us about you")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Education Level")
                        .font(.headline)
                    Picker("Education Level", selection: $educationLevel) {
                        ForEach(educationLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                VStack(alignment: .leading) {
                    Text("Learning Focus")
                        .font(.headline)
                    TextField("e.g., Anatomy, History, Math...", text: $learningFocus)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingSignInPage: View {
    @EnvironmentObject var authService: AuthService
    var educationLevel: String
    var learningFocus: String
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
                    // Note: We need a way to pass the profile info to AuthService after sign in.
                    // Since startSignInWithApple is async/delegate based, we might need to store this info temporarily in AuthService or update it after sign in.
                    // For now, we'll rely on the user updating their profile if needed, or we can update AuthService to hold this temporary state.
                    // Ideally, we'd update the user profile immediately after sign in success.
                    // Let's assume we can update it in the .onChange in OnboardingView or similar.
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
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Update profile with onboarding data
                Task {
                    try? await authService.updateUserProfile(
                        name: authService.user?.name ?? "Student",
                        educationLevel: educationLevel,
                        learningFocus: learningFocus
                    )
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
}
