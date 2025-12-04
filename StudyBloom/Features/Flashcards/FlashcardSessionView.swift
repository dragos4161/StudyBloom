import SwiftUI

struct FlashcardSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: DataService
    
    let deck: [Flashcard]
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var sessionComplete = false
    @State private var showingEditSheet = false
    
    // Animation states
    @State private var rotation: Double = 0
    
    var currentCard: Flashcard? {
        if currentIndex < deck.count {
            // Check if we have an updated version in dataService, otherwise use the one from deck
            let cardId = deck[currentIndex].id
            return dataService.flashcards.first(where: { $0.id == cardId }) ?? deck[currentIndex]
        }
        return nil
    }
    
    var body: some View {
        VStack {
            if sessionComplete {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    Text("Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("You've reviewed \(deck.count) cards.")
                        .foregroundColor(.secondary)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
            } else if let card = currentCard {
                VStack {
                    // Progress
                    ProgressView(value: Double(currentIndex), total: Double(deck.count))
                        .padding()
                    
                    Spacer()
                    
                    // Card
                    ZStack {
                        // Back (Answer)
                        CardContent(text: card.back, title: "Answer", color: Color(red: 0.85, green: 0.92, blue: 1.0)) // Pastel Blue
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .opacity(isFlipped ? 1 : 0)
                        
                        // Front (Question)
                        CardContent(text: card.front, title: "Question", color: Color(red: 0.85, green: 0.92, blue: 1.0)) // Pastel Blue
                            .opacity(isFlipped ? 0 : 1)
                    }
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            rotation += 180
                            isFlipped.toggle()
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Controls
                    if isFlipped {
                        HStack(spacing: 20) {
                            Button(action: { processCard(rating: .again) }) {
                                Label("Again", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: { processCard(rating: .easy) }) {
                                Label("Easy", systemImage: "star.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.2)) // Changed to green for positive reinforcement
                                    .foregroundColor(.green)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    } else {
                        Text("Tap card to flip")
                            .foregroundColor(.secondary)
                            .padding(.bottom, 50)
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    CreateFlashcardView(flashcardToEdit: card)
                }
            } else {
                Text("No cards to study")
            }
        }
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            
            if !sessionComplete {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
        }
    }
    
    private func processCard(rating: Rating) {
        guard let card = currentCard else { return }
        
        var updatedCard = card
        
        // Simplified Spaced Repetition Logic
        switch rating {
        case .again:
            updatedCard.interval = 0
            updatedCard.repetition = 0
        case .easy:
            // Boost interval significantly
            updatedCard.interval = max(3, Int(Double(updatedCard.interval == 0 ? 1 : updatedCard.interval) * 2.5))
            updatedCard.repetition += 1
        }
        
        updatedCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: updatedCard.interval, to: Date()) ?? Date()
        
        Task {
            try? await dataService.updateFlashcard(updatedCard)
        }
        
        withAnimation {
            isFlipped = false
            rotation = 0
            if currentIndex < deck.count - 1 {
                currentIndex += 1
            } else {
                sessionComplete = true
            }
        }
    }
    
    enum Rating {
        case again, easy
    }
}

struct CardContent: View {
    let text: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
            
            Spacer()
            
            Text(text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(color)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

#Preview {
    FlashcardSessionView(deck: [
        Flashcard(id: "1", userId: "u1", front: "What is SwiftUI?", back: "A UI framework", chapterId: nil),
        Flashcard(id: "2", userId: "u1", front: "What is MVVM?", back: "Model View ViewModel", chapterId: nil)
    ])
    .environmentObject(DataService())
}
