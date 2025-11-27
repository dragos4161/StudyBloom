//
//  Rezy_BuddyApp.swift
//  Rezy Buddy
//
//  Created by Dragos Dima on 22.11.2025.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct StudyBloomApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeViewWithTestButton()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [Chapter.self, StudyPlan.self, DailyLog.self])
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
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
