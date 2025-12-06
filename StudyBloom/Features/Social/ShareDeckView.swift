import SwiftUI

struct ShareDeckView: View {
    let flashcards: [Flashcard]
    @Environment(\.dismiss) var dismiss
    @StateObject private var socialService = SocialService.shared
    @EnvironmentObject var dataService: DataService
    
    @State private var deckTitle = ""
    @State private var deckDescription = ""
    @State private var selectedVisibility: DeckVisibility = .friends
    @State private var selectedFriends: Set<String> = []
    @State private var isSharing = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Deck Information") {
                    TextField("Deck Title", text: $deckTitle)
                    
                    TextField("Description (optional)", text: $deckDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Visibility") {
                    Picker("Who can see this deck?", selection: $selectedVisibility) {
                        Label("Private", systemImage: "lock.fill")
                            .tag(DeckVisibility.private)
                        Label("Friends Only", systemImage: "person.2.fill")
                            .tag(DeckVisibility.friends)
                        Label("Public", systemImage: "globe")
                            .tag(DeckVisibility.public)
                    }
                    .pickerStyle(.menu)
                    
                    visibilityExplanation
                }
                
                if selectedVisibility == .friends {
                    Section("Share With Specific Friends") {
                        if socialService.friends.isEmpty {
                            Text("No friends to share with yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(socialService.friends) { friend in
                                Toggle(isOn: Binding(
                                    get: { selectedFriends.contains(friend.id ?? "") },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedFriends.insert(friend.id ?? "")
                                        } else {
                                            selectedFriends.remove(friend.id ?? "")
                                        }
                                    }
                                )) {
                                    HStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 30, height: 30)
                                            .overlay {
                                                Text(friend.displayName.prefix(1))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                            }
                                        
                                        Text(friend.displayName)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    deckPreview
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
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        Task {
                            await shareDeck()
                        }
                    }
                    .disabled(deckTitle.isEmpty || isSharing)
                }
            }
            .task {
                try? await loadFriends()
            }
            .alert("Deck Shared!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(deckTitle) has been shared successfully!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Visibility Explanation
    
    private var visibilityExplanation: some View {
        Group {
            switch selectedVisibility {
            case .private:
                Label("Only you can see this deck", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .friends:
                Label("Only your friends can see and import this deck", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .public:
                Label("Anyone can discover and import this deck", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Deck Preview
    
    private var deckPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deckTitle.isEmpty ? "Untitled Deck" : deckTitle)
                        .font(.headline)
                    
                    if !deckDescription.isEmpty {
                        Text(deckDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text("\(flashcards.count) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadFriends() async {
        do {
            let friends = try await socialService.fetchFriends()
            await MainActor.run {
                socialService.friends = friends
            }
        } catch {
            print("Error loading friends: \(error)")
        }
    }
    
    private func shareDeck() async {
        guard let userId = dataService.currentUserId else { return }
        
        isSharing = true
        
        do {
            // Get user profile for owner info
            let userProfile = try await socialService.fetchUserProfile(userId: userId)
            
            let sharedDeck = SharedDeck(
                ownerId: userId,
                ownerName: userProfile.displayName,
                ownerUsername: userProfile.username,
                title: deckTitle,
                description: deckDescription,
                flashcards: flashcards,
                visibility: selectedVisibility,
                sharedWith: Array(selectedFriends)
            )
            
            try await socialService.shareFlashcardDeck(sharedDeck)
            
            await MainActor.run {
                isSharing = false
                showingSuccess = true
            }
        } catch {
            await MainActor.run {
                isSharing = false
                errorMessage = "Failed to share deck: \(error.localizedDescription)"
            }
        }
    }
}
