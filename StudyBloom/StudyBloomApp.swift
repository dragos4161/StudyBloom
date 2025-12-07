//
//  Rezy_BuddyApp.swift
//  Rezy Buddy
//
//  Created by Dragos Dima on 22.11.2025.
//

import SwiftUI
import FirebaseCore

@main
struct StudyBloomApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var authService = AuthService()
    @StateObject private var dataService = DataService()
    @StateObject private var badgeManager = BadgeManager.shared
    
    init() {
        FirebaseApp.configure()
        
        // Connect TimerService to AnalyticsService
        // This ensures tracking only works in the main app, avoiding Widget compile errors
        TimerService.shared.onSessionCompleted = { duration in
            Task {
                try? await AnalyticsService.shared.logStudySession(pages: 0, duration: duration)
                try? await AnalyticsService.shared.logPomodoroSession()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isCheckingAuth {
                // Show splash screen while Firebase checks auth state
                SplashScreenView()
            } else if hasCompletedOnboarding {
                if authService.isAuthenticated {
                    HomeView()
                } else {
                    // User completed onboarding but signed out - show login
                    LoginView()
                }
            } else {
                // Show onboarding first (includes sign-in on last page)
                OnboardingView()
            }
        }
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
        .environmentObject(authService)
        .environmentObject(dataService)
        .environmentObject(badgeManager)
        .onChange(of: authService.user?.id) { _, userId in
            if let userId = userId {
                dataService.initializeForUser(userId: userId)
            } else {
                dataService.removeListeners()
            }
        }
    }
}
