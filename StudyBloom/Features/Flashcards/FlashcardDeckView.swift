import SwiftUI

struct DeckWrapper: Identifiable {
    let id = UUID()
    let cards: [Flashcard]
}

struct FlashcardDeckView: View {
    @EnvironmentObject var dataService: DataService
    @State private var showingCreateSheet = false
    @State private var selectedDeck: DeckWrapper?
    
    var body: some View {
        NavigationView {
            List {
                // All Flashcards Section
                Section(header: Text("General")) {
                    DeckRow(title: "All Flashcards", count: dataService.flashcards.count) {
                        if !dataService.flashcards.isEmpty {
                            selectedDeck = DeckWrapper(cards: dataService.flashcards)
                        }
                    }
                    
                    let dueCards = dataService.flashcards.filter { $0.isDue }
                    if !dueCards.isEmpty {
                        DeckRow(title: "Due for Review", count: dueCards.count, color: .orange) {
                            selectedDeck = DeckWrapper(cards: dueCards)
                        }
                    }
                }
                
                // By Chapter Section
                if !dataService.chapters.isEmpty {
                    Section(header: Text("By Chapter")) {
                        ForEach(dataService.chapters) { chapter in
                            let chapterCards = dataService.flashcards.filter { $0.chapterId == chapter.id }
                            if !chapterCards.isEmpty {
                                DeckRow(title: chapter.title, count: chapterCards.count) {
                                    selectedDeck = DeckWrapper(cards: chapterCards)
                                }
                            }
                        }
                    }
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
            .fullScreenCover(item: $selectedDeck) { deckWrapper in
                NavigationView {
                    FlashcardSessionView(deck: deckWrapper.cards)
                }
            }
        }
    }
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

#Preview {
    FlashcardDeckView()
        .environmentObject(DataService())
}
