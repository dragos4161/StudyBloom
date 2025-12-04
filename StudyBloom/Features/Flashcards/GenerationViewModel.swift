import Foundation
import Combine

class GenerationViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generatedFlashcards: [Flashcard] = []
    @Published var generationProgress: Double = 0
    
    private let aiService: AIServiceProtocol
    private let pdfService = PDFService.shared
    private let authService: AuthService
    
    // Temporary storage for API Key - in production this should be secure
    var apiKey: String = ""
    
    init(aiService: AIServiceProtocol? = nil, authService: AuthService = AuthService()) {
        // Default to OpenAIService with empty key, will be updated when user provides key
        self.aiService = aiService ?? OpenAIService(apiKey: "")
        self.authService = authService
    }
    
    func generateFlashcards(from pdfUrl: URL, count: Int) async {
        guard !apiKey.isEmpty else {
            errorMessage = "Please enter an OpenAI API Key"
            return
        }
        
        // Update service with key
        let service = OpenAIService(apiKey: apiKey)
        
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
            generationProgress = 0.1
        }
        
        // 1. Extract Text
        guard let text = pdfService.extractText(from: pdfUrl) else {
            await MainActor.run {
                errorMessage = "Failed to extract text from PDF"
                isGenerating = false
            }
            return
        }
        
        await MainActor.run { generationProgress = 0.3 }
        
        // 2. Prepare Prompt
        // Truncate text if too long (simple approach for MVP)
        let truncatedText = String(text.prefix(15000)) // Approx 4-5k tokens
        
        var contextInfo = ""
        if let user = authService.user {
            if let level = user.educationLevel {
                contextInfo += "Target Audience: \(level).\n"
            }
            if let focus = user.learningFocus, !focus.isEmpty {
                contextInfo += "Focus On: \(focus).\n"
            }
        }
        
        let prompt = """
        Generate \(count) flashcards based on the following text.
        \(contextInfo)
        Return a JSON object with a key "flashcards" containing an array of objects.
        Each object must have "front" (question) and "back" (answer) keys.
        Do not include any other text.
        """
        
        // 3. Call AI
        do {
            let jsonString = try await service.generateContent(from: truncatedText, prompt: prompt)
            await MainActor.run { generationProgress = 0.8 }
            
            // 4. Parse Response
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let cardsArray = json["flashcards"] as? [[String: String]] {
                
                let newCards = cardsArray.compactMap { dict -> Flashcard? in
                    guard let front = dict["front"], let back = dict["back"] else { return nil }
                    return Flashcard(
                        id: UUID().uuidString,
                        userId: "", // Will be set when saving
                        front: front,
                        back: back,
                        chapterId: nil
                    )
                }
                
                await MainActor.run {
                    self.generatedFlashcards = newCards
                    self.generationProgress = 1.0
                    self.isGenerating = false
                }
            } else {
                throw AIError.decodingError
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
        }
    }
}
