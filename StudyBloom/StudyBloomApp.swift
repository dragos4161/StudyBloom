//
//  Rezy_BuddyApp.swift
//  Rezy Buddy
//
//  Created by Dragos Dima on 22.11.2025.
//

import SwiftUI

import SwiftData

@main
struct StudyBloomApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [Chapter.self, StudyPlan.self, DailyLog.self])
    }
}
