import SwiftUI
import UniformTypeIdentifiers

struct PDFImportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GenerationViewModel()
    @State private var showingFilePicker = false
    @State private var selectedPDFUrl: URL?
    @State private var numberOfCards = 5.0
    @State private var apiKey = ""
    @State private var showingReview = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration")) {
                    SecureField("OpenAI API Key", text: $apiKey)
                    
                    VStack {
                        HStack {
                            Text("Number of Cards")
                            Spacer()
                            Text("\(Int(numberOfCards))")
                        }
                        Slider(value: $numberOfCards, in: 3...20, step: 1)
                    }
                }
                
                Section(header: Text("Source")) {
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text(selectedPDFUrl?.lastPathComponent ?? "Select PDF File")
                                .foregroundColor(selectedPDFUrl == nil ? .primary : .blue)
                        }
                    }
                }
                
                if viewModel.isGenerating {
                    Section {
                        VStack(spacing: 15) {
                            ProgressView(value: viewModel.generationProgress)
                            Text("Reading PDF and dreaming up questions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Generate Flashcards") {
                        generate()
                    }
                    .disabled(selectedPDFUrl == nil || apiKey.isEmpty || viewModel.isGenerating)
                }
            }
            .navigationTitle("AI Generation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // Access security scoped resource
                        if url.startAccessingSecurityScopedResource() {
                            selectedPDFUrl = url
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showingReview) {
                GeneratedContentReviewView(cards: viewModel.generatedFlashcards)
            }
            .onChange(of: viewModel.generatedFlashcards.isEmpty) { _, isEmpty in
                if !isEmpty {
                    showingReview = true
                }
            }
        }
    }
    
    private func generate() {
        guard let url = selectedPDFUrl else { return }
        viewModel.apiKey = apiKey
        Task {
            await viewModel.generateFlashcards(from: url, count: Int(numberOfCards))
        }
    }
}

#Preview {
    PDFImportView()
}
