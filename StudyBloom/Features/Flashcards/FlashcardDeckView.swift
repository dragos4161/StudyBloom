import SwiftUI

struct FlashcardDeckView: View {
    var body: some View {
        NavigationView {
            VStack {
                ContentUnavailableView("No Decks Created", systemImage: "rectangle.on.rectangle.slash", description: Text("Create your first flashcard deck to start studying."))
                
                Button(action: {
                    // Action to create deck
                }) {
                    Text("Create Deck")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Flashcards")
        }
    }
}

#Preview {
    FlashcardDeckView()
}
