import SwiftUI

struct DeckWrapper: Identifiable {
    let id = UUID()
    let cards: [Flashcard]
}

struct FlashcardDeckView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showingCreateSheet = false
    @State private var deckToShare: ShareableDeck?
    @State private var deckToManage: DeckWrapper?
    @State private var selectedDeck: DeckWrapper?
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ScrollView {
            if sizeClass == .compact {
                // iPhone Layout (List)
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    deckContent
                }
            } else {
                // iPad Layout (Grid)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)], spacing: 20) {
                   deckContent
                }
                .padding()
            }
        }
        .navigationTitle("Flashcards")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: PDFImportView()) {
                    Image(systemName: "wand.and.stars")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateFlashcardView()
        }
        .sheet(item: $deckToShare) { deck in
            ShareDeckView(flashcards: deck.cards, initialTitle: deck.title)
        }
        .sheet(item: $deckToManage) { deckWrapper in
            NavigationView {
                DeckEditorView(deckTitle: "Manage Deck", cards: deckWrapper.cards)
            }
        }
        .fullScreenCover(item: $selectedDeck) { deckWrapper in
            NavigationView {
                FlashcardSessionView(deck: deckWrapper.cards)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    @ViewBuilder
    private var deckContent: some View {
        // General Section
        Section(header: sectionHeader("General")) {
            Group {
                deckItem(title: "All Flashcards", count: dataService.flashcards.count, color: .blue) {
                    if !dataService.flashcards.isEmpty {
                        selectedDeck = DeckWrapper(cards: dataService.flashcards)
                    }
                }
                .contextMenu {
                    Button {
                        if !dataService.flashcards.isEmpty {
                            deckToShare = ShareableDeck(title: "All Flashcards", cards: dataService.flashcards)
                        }
                    } label: {
                        Label("Share Deck", systemImage: "square.and.arrow.up")
                    }
                }
                
                let dueCards = dataService.flashcards.filter { $0.isDue }
                if !dueCards.isEmpty {
                    deckItem(title: "Due for Review", count: dueCards.count, color: .orange) {
                        selectedDeck = DeckWrapper(cards: dueCards)
                    }
                    .contextMenu {
                        Button {
                            deckToShare = ShareableDeck(title: "Due for Review", cards: dueCards)
                        } label: {
                            Label("Share Deck", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        
        // By Chapter Section
        if !dataService.chapters.isEmpty {
            Section(header: sectionHeader("By Chapter")) {
                ForEach(dataService.chapters) { chapter in
                    let chapterCards = dataService.flashcards.filter { $0.chapterId == chapter.id }
                    // Show chapter even if empty so it can be deleted!
                    // Wait, previously checking !chapterCards.isEmpty.
                    // If we want to allow deleting empty imported decks, we should remove that check.
                    
                    deckItem(title: chapter.title, count: chapterCards.count, color: Color(hex: chapter.colorHex) ?? .purple) {
                        if !chapterCards.isEmpty {
                            selectedDeck = DeckWrapper(cards: chapterCards)
                        } else {
                            // Can't study empty deck, but maybe show alert or just nothing?
                        }
                    }
                    .contextMenu {
                        Button {
                            deckToShare = ShareableDeck(title: chapter.title, cards: chapterCards)
                        } label: {
                            Label("Share Deck", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            // Manage Cards
                            deckToManage = DeckWrapper(cards: chapterCards)
                        } label: {
                            Label("Manage Cards", systemImage: "rectangle.stack")
                        }
                        
                        Button(role: .destructive) {
                            deleteChapter(chapter)
                        } label: {
                            Label("Delete Deck", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private func deleteChapter(_ chapter: Chapter) {
        Task {
            do {
                try await dataService.deleteChapter(chapter)
            } catch {
                print("Error deleting deck: \(error)")
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, sizeClass == .compact ? 16 : 0)
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    @ViewBuilder
    private func deckItem(title: String, count: Int, color: Color, action: @escaping () -> Void) -> some View {
        if sizeClass == .compact {
            // List Row Style
            DeckRow(title: title, count: count, color: color, action: action)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
        } else {
            // Grid Card Style
            DeckCard(title: title, count: count, color: color, action: action)
        }
    }
}

struct ShareableDeck: Identifiable {
    let id = UUID()
    let title: String
    let cards: [Flashcard]
}

struct DeckRow: View {
    let title: String
    let count: Int
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(count) cards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(color)
            }
            .padding(.vertical, 4)
        }
    }
}

struct DeckCard: View {
    let title: String
    let count: Int
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                                .foregroundColor(color)
                        )
                    Spacer()
                    Text("\(count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    FlashcardDeckView()
        .environmentObject(DataService())
}
