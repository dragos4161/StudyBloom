import SwiftUI

struct CreateFlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var authService: AuthService
    
    var flashcardToEdit: Flashcard?
    
    @State private var frontText = ""
    @State private var backText = ""
    @State private var selectedChapterId: String?
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(flashcardToEdit: Flashcard? = nil) {
        self.flashcardToEdit = flashcardToEdit
        _frontText = State(initialValue: flashcardToEdit?.front ?? "")
        _backText = State(initialValue: flashcardToEdit?.back ?? "")
        _selectedChapterId = State(initialValue: flashcardToEdit?.chapterId)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Content")) {
                    TextField("Front (Question)", text: $frontText, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Back (Answer)", text: $backText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Association")) {
                    Picker("Chapter (Optional)", selection: $selectedChapterId) {
                        Text("None (General)").tag(Optional<String>.none)
                        ForEach(dataService.chapters) { chapter in
                            Text(chapter.title).tag(Optional(chapter.id))
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(flashcardToEdit == nil ? "New Flashcard" : "Edit Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFlashcard()
                    }
                    .disabled(frontText.isEmpty || backText.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveFlashcard() {
        guard let userId = authService.user?.id else { return }
        
        isSaving = true
        errorMessage = nil
        
        if let existingCard = flashcardToEdit {
            // Update existing
            let updatedCard = Flashcard(
                id: existingCard.id,
                userId: existingCard.userId,
                front: frontText,
                back: backText,
                chapterId: selectedChapterId,
                interval: existingCard.interval,
                repetition: existingCard.repetition,
                easeFactor: existingCard.easeFactor,
                nextReviewDate: existingCard.nextReviewDate
            )
            
            Task {
                do {
                    try await dataService.updateFlashcard(updatedCard)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isSaving = false
            }
        } else {
            // Create new
            let newFlashcard = Flashcard(
                id: UUID().uuidString,
                userId: userId,
                front: frontText,
                back: backText,
                chapterId: selectedChapterId
            )
            
            Task {
                do {
                    try await dataService.addFlashcard(newFlashcard)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isSaving = false
            }
        }
    }
}

#Preview {
    CreateFlashcardView()
        .environmentObject(DataService())
        .environmentObject(AuthService())
}
