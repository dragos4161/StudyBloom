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
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                if hasCompletedOnboarding {
                    HomeViewWithTestButton()
                } else {
                    OnboardingView()
                }
            } else {
                LoginView()
            }
        }
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
        .environmentObject(authService)
        .environmentObject(dataService)
        .onChange(of: authService.user?.id) { _, userId in
            if let userId = userId {
                dataService.initializeForUser(userId: userId)
            } else {
                dataService.removeListeners()
            }
        }
    }
}

// Temporary wrapper to add test button
struct HomeViewWithTestButton: View {
    @State private var showTestView = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HomeView()
            
            Button(action: { showTestView = true }) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
            .sheet(isPresented: $showTestView) {
                UserListTestView()
            }
        }
    }
}
