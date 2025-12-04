import Foundation

class OpenAIService: AIServiceProtocol {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateContent(from text: String, prompt: String) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemMessage = "You are a helpful study assistant. Your goal is to extract key information from the provided text and generate flashcards or questions as requested. Return ONLY valid JSON."
        let userMessage = "\(prompt)\n\nContext:\n\(text)"
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini", // Cost-effective and fast
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.7,
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIError.apiError(message)
            }
            throw AIError.invalidResponse
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.decodingError
        }
        
        return content
    }
}
