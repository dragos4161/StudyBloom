import Foundation
import UIKit

@MainActor
class BadgeManager: ObservableObject {
    static let shared = BadgeManager()
    
    @Published var friendRequestCount: Int = 0
    @Published var sharedDeckCount: Int = 0
    @Published var totalUnread: Int = 0
    
    private init() {}
    
    func updateFriendRequestBadge() async {
        // Fetch pending friend requests count from Firebase
        let count = (try? await SocialService.shared.fetchPendingRequestsCount()) ?? 0
        
        friendRequestCount = count
        updateTotalBadge()
    }
    
    func updateSharedDeckBadge(count: Int) {
        sharedDeckCount = count
        updateTotalBadge()
    }
    
    func markFriendRequestsAsRead() {
        friendRequestCount = 0
        updateTotalBadge()
    }
    
    func markSharedDecksAsRead() {
        sharedDeckCount = 0
        updateTotalBadge()
    }
    
    private func updateTotalBadge() {
        totalUnread = friendRequestCount + sharedDeckCount
        
        // Update app icon badge
        UIApplication.shared.applicationIconBadgeNumber = totalUnread
    }
    
    func clearAllBadges() {
        friendRequestCount = 0
        sharedDeckCount = 0
        totalUnread = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
