import SwiftUI

struct GeneratedContentReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var authService: AuthService
    
    @State var cards: [Flashcard]
    @State private var selectedChapterId: String?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Save To")) {
                    Picker("Chapter (Optional)", selection: $selectedChapterId) {
                        Text("None (General)").tag(Optional<String>.none)
                        ForEach(dataService.chapters) { chapter in
                            Text(chapter.title).tag(Optional(chapter.id))
                        }
                    }
                }
                
                Section(header: Text("Generated Cards (\(cards.count))")) {
                    ForEach($cards) { $card in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Front", text: $card.front)
                                .font(.headline)
                            Divider()
                            TextField("Back", text: $card.back)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        cards.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Review Content")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save All") {
                        saveAll()
                    }
                    .disabled(cards.isEmpty)
                }
            }
        }
    }
    
    private func saveAll() {
        guard let userId = authService.user?.id else { return }
        
        Task {
            for card in cards {
                var newCard = card
                newCard.userId = userId
                newCard.chapterId = selectedChapterId
                try? await dataService.addFlashcard(newCard)
            }
            dismiss()
        }
    }
}

#Preview {
    GeneratedContentReviewView(cards: [
        Flashcard(id: "1", userId: "u1", front: "Q1", back: "A1", chapterId: nil),
        Flashcard(id: "2", userId: "u1", front: "Q2", back: "A2", chapterId: nil)
    ])
    .environmentObject(DataService())
    .environmentObject(AuthService())
}
