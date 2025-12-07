import SwiftUI
import Combine

struct SocialView: View {
    @StateObject private var socialService = SocialService.shared
    @EnvironmentObject var badgeManager: BadgeManager
    
    @State private var selectedTab: SocialTab = .friends
    @State private var searchQuery = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching = false
    @State private var selectedProfile: UserProfile?
    
    enum SocialTab: String, CaseIterable {
        case friends = "Friends"
        case requests = "Requests"
        case discover = "Discover"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Tab", selection: $selectedTab) {
                    ForEach(SocialTab.allCases, id: \.self) { tab in
                        if tab == .requests && badgeManager.friendRequestCount > 0 {
                            Text("\(tab.rawValue) (\(badgeManager.friendRequestCount))").tag(tab)
                        } else {
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                switch selectedTab {
                case .friends:
                    friendsListView
                case .requests:
                    requestsListView
                case .discover:
                    discoverView
                }
            }
            .navigationTitle("Social")
            .onAppear {
                Task {
                    try? await loadData()
                }
            }
        .sheet(item: $selectedProfile) { profile in
            FriendProfileView(profile: profile)
        }
        }
    }
    
    // MARK: - Friends List
    
    private var friendsListView: some View {
        Group {
            if socialService.friends.isEmpty {
                emptyFriendsView
            } else {
                List(socialService.friends) { friend in
                    Button {
                        selectedProfile = friend
                    } label: {
                        FriendRowView(friend: friend)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Search for users in the Discover tab")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Friend Requests
    
    private var requestsListView: some View {
        Group {
            if socialService.pendingRequests.isEmpty {
                emptyRequestsView
            } else {
                List(socialService.pendingRequests) { request in
                    FriendRequestRowView(request: request) {
                        Task {
                            try? await socialService.acceptFriendRequest(request.id ?? "")
                            await loadData()
                        }
                    } onDecline: {
                        Task {
                            try? await socialService.declineFriendRequest(request.id ?? "")
                            await loadData()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            // Mark as read when viewing
            badgeManager.markFriendRequestsAsRead()
        }
    }
    
    private var emptyRequestsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.open")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Pending Requests")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Friend requests will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Discover
    
    private var discoverView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search by username...", text: $searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: searchQuery) { _, newValue in
                        Task {
                            await performSearch(query: newValue)
                        }
                    }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            
            // Search Results
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchQuery.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Find Study Buddies")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Search for users by their username")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("No Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Try a different username")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(searchResults) { user in
                    Button {
                        selectedProfile = user
                    } label: {
                        UserSearchRowView(user: user)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadData() async {
        do {
            let friends = try await socialService.fetchFriends()
            let requests = try await socialService.fetchPendingRequests()
            
            await MainActor.run {
                socialService.friends = friends
                socialService.pendingRequests = requests
            }
        } catch {
            print("Error loading social data: \(error)")
        }
    }
    
    private func performSearch(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            let results = try await socialService.searchUsers(query: query)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            print("Search error: \(error)")
            await MainActor.run {
                isSearching = false
            }
        }
    }
}

// MARK: - Friend Row View

struct FriendRowView: View {
    let friend: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image Placeholder
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(friend.displayName.prefix(1))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                Text("@\(friend.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Study Stats
                HStack(spacing: 12) {
                    Label("\(friend.studyStreak) day streak", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Label(formatTime(friend.totalStudyTime), systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        return hours > 0 ? "\(hours)h" : "\(Int(seconds) / 60)m"
    }
}

// MARK: - Friend Request Row View

struct FriendRequestRowView: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(request.senderName.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.senderName)
                        .font(.headline)
                    
                    Text("@\(request.senderUsername)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(timeAgo(from: request.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    onAccept()
                } label: {
                    Label("Accept", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.borderless)
                
                Button {
                    onDecline()
                } label: {
                    Label("Decline", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))h ago"
        } else {
            return "\(Int(seconds / 86400))d ago"
        }
    }
}

// MARK: - User Search Row View

struct UserSearchRowView: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 45, height: 45)
                .overlay {
                    Text(user.displayName.prefix(1))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
