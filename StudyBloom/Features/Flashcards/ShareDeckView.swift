import SwiftUI

struct ShareDeckView: View {
    @Environment(\.dismiss) var dismiss
    private let socialService = SocialService.shared
    
    let flashcards: [Flashcard]
    let initialTitle: String
    
    @State private var title: String
    @State private var description: String = ""
    @State private var visibility: DeckVisibility = .friends
    @State private var isSharing = false
    @State private var errorMessage: String?
    
    // Specific Sharing
    @State private var friends: [UserProfile] = []
    @State private var selectedFriendIds: Set<String> = []
    @State private var isLoadingFriends = false
    
    init(flashcards: [Flashcard], initialTitle: String) {
        self.flashcards = flashcards
        self.initialTitle = initialTitle
        _title = State(initialValue: initialTitle)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Deck Details")) {
                    TextField("Deck Title", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Visibility")) {
                    Picker("Who can see this?", selection: $visibility) {
                        Text("Friends Only").tag(DeckVisibility.friends)
                        Text("Public").tag(DeckVisibility.public)
                        Text("Specific Friends").tag(DeckVisibility.specific)
                        Text("Private").tag(DeckVisibility.private)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: visibility) { newValue in
                        if newValue == .specific && friends.isEmpty {
                            loadFriends()
                        }
                    }
                    
                    if visibility == .public {
                        Text("Anyone can find and import this deck.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if visibility == .friends {
                        Text("Only your confirmed friends can see this.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if visibility == .specific {
                        Text("Only selected friends can see this.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if visibility == .specific {
                    Section(header: Text("Select Friends")) {
                        if isLoadingFriends {
                            ProgressView()
                        } else if friends.isEmpty {
                            Text("No friends found.")
                                .foregroundStyle(.secondary)
                        } else {
                            List(friends) { friend in
                                Button {
                                    if selectedFriendIds.contains(friend.id ?? "") {
                                        selectedFriendIds.remove(friend.id ?? "")
                                    } else {
                                        selectedFriendIds.insert(friend.id ?? "")
                                    }
                                } label: {
                                    HStack {
                                        Text(friend.displayName)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedFriendIds.contains(friend.id ?? "") {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        if isSharing {
                            ProgressView()
                        } else {
                            Button("Share Deck") {
                                shareDeck()
                            }
                            .disabled(title.isEmpty || (visibility == .specific && selectedFriendIds.isEmpty))
                        }
                        Spacer()
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Cards")
                        Spacer()
                        Text("\(flashcards.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Share Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func loadFriends() {
        isLoadingFriends = true
        Task {
            do {
                let fetchedFriends = try await socialService.fetchFriends()
                await MainActor.run {
                    self.friends = fetchedFriends
                    self.isLoadingFriends = false
                }
            } catch {
                print("Error fetching friends: \(error)")
                await MainActor.run {
                    self.isLoadingFriends = false
                }
            }
        }
    }
    
    private func shareDeck() {
        guard !title.isEmpty else { return }
        isSharing = true
        errorMessage = nil
        
        Task {
            do {
                // Get current user details from SocialService or Auth
                // We fetch the profile directly in fetchAndShare using currentUserId
                try await fetchAndShare()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }
    
    private func fetchAndShare() async throws {
        // We need user profile to populate SharedDeck owner info
        guard let userId = socialService.currentUserId else { return }
        let profile = try await socialService.fetchUserProfile(userId: userId)
        
        let deck = SharedDeck(
            ownerId: userId,
            ownerName: profile.displayName,
            ownerUsername: profile.username,
            title: title,
            description: description,
            flashcards: flashcards,
            visibility: visibility,
            sharedWith: Array(selectedFriendIds)
        )
        
        try await socialService.shareFlashcardDeck(deck)
        
        await MainActor.run {
            isSharing = false
            dismiss()
        }
    }
}
