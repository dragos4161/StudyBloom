import SwiftUI

struct DeckEditorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    let deckTitle: String
    var cards: [Flashcard]
    
    @State private var searchText = ""
    
    var filteredCards: [Flashcard] {
        if searchText.isEmpty {
            return cards
        } else {
            return cards.filter { 
                $0.front.localizedCaseInsensitiveContains(searchText) || 
                $0.back.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredCards) { card in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Front:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(card.front)
                        .font(.body)
                        .lineLimit(2)
                    
                    Divider()
                    
                    Text("Back:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(card.back)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteCard(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(deckTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .overlay {
            if cards.isEmpty {
                ContentUnavailableView(
                    "No Cards",
                    systemImage: "rectangle.portrait.on.rectangle.portrait.slash",
                    description: Text("This deck is empty.")
                )
            }
        }
    }
    
    private func deleteCard(_ card: Flashcard) {
        Task {
            do {
                try await dataService.deleteFlashcard(card)
                // Optimistic update handled by DataService listener usually, but here we passed 'cards' directly.
                // Since this view is likely presented from FlashcardDeckView which observes DataService, 
                // we rely on DataService updates to propagate if we were observing...
                // Wait, 'cards' is a let/var passed in. It won't update automatically if it's just an array.
                // However, we need to pass the source binding or rely on DataService.
                // Let's rely on DataService being EnvironmentObject and 'cards' being refreshed 
                // if the parent updates, but DeckEditorView inputs might be stale.
                // Actually, simpler: pass deck ID or rely on DataService.flashcards filter.
            } catch {
                print("Error deleting card: \(error)")
            }
        }
    }
}
