import SwiftUI

struct FriendProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @StateObject private var socialService = SocialService.shared
    @State private var sharedDecks: [SharedDeck] = []
    @State private var isLoadingDecks = false
    @State private var showingRemoveAlert = false
    @State private var friendStatus: SocialService.FriendStatus = .notFriends
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Text(profile.displayName.prefix(1))
                                    .font(.system(size: 40))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        
                        Text(profile.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("@\(profile.username)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Study Stats (if visible)
                    if profile.privacySettings.statsVisibility != .private {
                        statsCardView
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Shared Decks
                    sharedDecksSection
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons
                    Group {
                        switch friendStatus {
                        case .notFriends:
                            Button {
                                sendFriendRequest()
                            } label: {
                                Label("Add Friend", systemImage: "person.badge.plus")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                            
                        case .requestSent:
                            Button {
                                // Already sent
                            } label: {
                                Label("Request Sent", systemImage: "clock.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.secondary)
                                    .cornerRadius(12)
                            }
                            .disabled(true)
                            
                        case .requestReceived:
                            HStack(spacing: 16) {
                                Button {
                                    acceptRequest()
                                } label: {
                                    Label("Accept", systemImage: "checkmark")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                
                                Button {
                                    declineRequest()
                                } label: {
                                    Label("Decline", systemImage: "xmark")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .foregroundStyle(.primary)
                                        .cornerRadius(12)
                                }
                            }
                            
                        case .friend:
                            Button(role: .destructive) {
                                showingRemoveAlert = true
                            } label: {
                                Label("Remove Friend", systemImage: "person.fill.xmark")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundStyle(.red)
                                    .cornerRadius(12)
                            }
                            
                        case .selfProfile:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
            .alert("Remove Friend?", isPresented: $showingRemoveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    Task {
                        try? await socialService.removeFriend(profile.id ?? "")
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to remove \(profile.displayName) from your friends?")
            }
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCardView: some View {
        VStack(spacing: 16) {
            Text("Study Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StatItemView(
                    icon: "flame.fill",
                    value: "\(profile.studyStreak)",
                    label: "Day Streak",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItemView(
                    icon: "clock.fill",
                    value: formatTime(profile.totalStudyTime),
                    label: "Total Time",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Shared Decks Section
    
    private var sharedDecksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared Flashcard Decks")
                .font(.headline)
                .padding(.horizontal)
            
            if isLoadingDecks {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if sharedDecks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.on.rectangle.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No Shared Decks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(sharedDecks) { deck in
                    SharedDeckCardView(deck: deck)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadData() async {
        isLoadingDecks = true
        
        // Check friendship status first
        if let userId = profile.id {
            do {
                let status = try await socialService.checkFriendshipStatus(with: userId)
                await MainActor.run {
                    self.friendStatus = status
                }
                
                // Only load shared decks if friends or public visibility logic allows (SocialService handles fetching, we filter later)
                // We use canAccess method to handle all visibility cases (Public, Friends, Specific)
                let decks = try await socialService.fetchSharedDecks(from: userId)
                
                await MainActor.run {
                    let currentUserId = socialService.currentUserId ?? ""
                    self.sharedDecks = decks.filter { deck in
                        deck.canAccess(userId: currentUserId, isFriend: status == .friend)
                    }
                    isLoadingDecks = false
                }
            } catch {
                print("Error loading data: \(error)")
                await MainActor.run { isLoadingDecks = false }
            }
        } else {
            await MainActor.run { isLoadingDecks = false }
        }
    }
    
    private func sendFriendRequest() {
        guard let userId = profile.id else { return }
        isProcessing = true
        
        Task {
            do {
                try await socialService.sendFriendRequest(
                    to: userId,
                    recipientName: profile.displayName,
                    recipientUsername: profile.username
                )
                await MainActor.run {
                    friendStatus = .requestSent
                    isProcessing = false
                }
            } catch {
                print("Error sending request: \(error)")
                await MainActor.run { isProcessing = false }
            }
        }
    }
    
    private func acceptRequest() {
        // Need request ID... logic gap. 
        // We need to fetch the request ID if status is requestReceived.
        // For now, let's just refresh data or handle in list view mostly.
        // Or fetch pending requests and find match.
        Task {
            // Find request ID
            if let request = socialService.pendingRequests.first(where: { $0.senderId == profile.id }) {
                try? await socialService.acceptFriendRequest(request.id ?? "")
                await loadData()
            }
        }
    }
    
    private func declineRequest() {
        Task {
            if let request = socialService.pendingRequests.first(where: { $0.senderId == profile.id }) {
                try? await socialService.declineFriendRequest(request.id ?? "")
                await loadData()
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(seconds) / 60
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Item View

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared Deck Card View

struct SharedDeckCardView: View {
    let deck: SharedDeck
    @EnvironmentObject var dataService: DataService
    @State private var showingImportSheet = false
    @State private var isImporting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.title)
                        .font(.headline)
                    
                    if !deck.description.isEmpty {
                        Text(deck.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: visibilityIcon(deck.visibility))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(deck.flashcards.count) cards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Label("\(deck.downloads) downloads", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .disabled(isImporting)
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .confirmationDialog("Import Deck", isPresented: $showingImportSheet) {
            Button("Import to My Flashcards") {
                Task {
                    await importDeck()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Import \"\(deck.title)\" (\(deck.flashcards.count) cards)?")
        }
    }
    
    private func visibilityIcon(_ visibility: DeckVisibility) -> String {
        switch visibility {
        case .public: return "globe"
        case .friends: return "person.2"
        case .specific: return "person.fill.checkmark"
        case .private: return "lock"
        }
    }
    
    private func importDeck() async {
        isImporting = true
        
        do {
            guard let deckId = deck.id else { return }
            let flashcards = try await SocialService.shared.importSharedDeck(deckId)
            
            // Save to DataService
            try await dataService.importSharedDeck(title: deck.title, flashcards: flashcards)
            
            await MainActor.run {
                isImporting = false
            }
        } catch {
            print("Import error: \(error)")
            await MainActor.run {
                isImporting = false
            }
        }
    }
}
