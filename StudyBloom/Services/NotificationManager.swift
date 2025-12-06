import Foundation
import UserNotifications
import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                requestPermission()
            } else {
                cancelAllNotifications()
            }
        }
    }
    
    private init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleMorningMotivation()
                    self.scheduleEveningReminder() // Default assumption: User hasn't studied yet
                } else {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Scheduling Logic
    
    private func scheduleMorningMotivation() {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! ☀️"
        content.body = "Ready to grow your knowledge today? Check your study plan!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morningMotivation", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleEveningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Keep your streak! ⏳"
        content.body = "The day is almost over. Log your progress to stay on track."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 18 // 6 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "eveningReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Dynamic Updates
    
    func userDidStudy(pages: Int) {
        guard notificationsEnabled else { return }
        
        // 1. Cancel the "You haven't studied" reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eveningReminder"])
        
        // 2. Schedule a "Great Job" notification for later (9 PM)
        let content = UNMutableNotificationContent()
        content.title = "Great work today! 📚"
        content.body = "You studied \(pages) pages. Rest up and let that knowledge sink in."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false) // One-time for today
        let request = UNNotificationRequest(identifier: "eveningAchievement", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Social Notifications
    
    func notifyFriendRequest(from userName: String) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Friend Request"
        content.body = "\(userName) wants to be friends!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "friend_request_\(UUID())",
            content: content,
            trigger: nil // Deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
        
        // Update badge
        Task {
            await BadgeManager.shared.updateFriendRequestBadge()
        }
    }
    
    func notifyFriendshipAccepted(userName: String) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Friend Request Accepted"
        content.body = "\(userName) accepted your friend request!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "friend_accepted_\(UUID())",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    func notifyDeckShared(deckName: String, from userName: String) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Shared Deck"
        content.body = "\(userName) shared \"\(deckName)\" with you!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "deck_shared_\(UUID())",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
