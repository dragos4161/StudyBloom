import Foundation

protocol AIServiceProtocol {
    func generateContent(from text: String, prompt: String) async throws -> String
}

enum AIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid response from server"
        case .apiError(let message): return "AI Error: \(message)"
        case .decodingError: return "Failed to decode response"
        case .noData: return "No data received"
        }
    }
}
