import Foundation
import PDFKit

class PDFService {
    static let shared = PDFService()
    
    private init() {}
    
    func extractText(from url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
