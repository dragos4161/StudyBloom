import SwiftUI

struct EditChapterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    let chapter: Chapter
    
    @State private var title: String
    @State private var totalPages: String
    @State private var selectedColorHex: String
    
    init(chapter: Chapter) {
        self.chapter = chapter
        _title = State(initialValue: chapter.title)
        _totalPages = State(initialValue: String(chapter.totalPages))
        _selectedColorHex = State(initialValue: chapter.colorHex)
    }
    
    let pastelColors = [
        "#FFB3BA", // Pastel Red
        "#FFDFBA", // Pastel Orange
        "#FFFFBA", // Pastel Yellow
        "#BAFFC9", // Pastel Green
        "#BAE1FF", // Pastel Blue
        "#E2BAFF", // Pastel Purple
        "#FFBAF2", // Pastel Pink
        "#E0E0E0"  // Pastel Grey
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chapter Details")) {
                    TextField("Chapter Title", text: $title)
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Color Code")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(pastelColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteChapter()
                    } label: {
                        Text("Delete Chapter")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Chapter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChapter()
                    }
                    .disabled(title.isEmpty || totalPages.isEmpty)
                }
            }
        }
    }
    
    private func saveChapter() {
        guard let pages = Int(totalPages) else { return }
        
        var updatedChapter = chapter
        updatedChapter.title = title
        updatedChapter.totalPages = pages
        updatedChapter.colorHex = selectedColorHex
        
        Task {
            do {
                try await dataService.updateChapter(updatedChapter)
                dismiss()
            } catch {
                print("Error updating chapter: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteChapter() {
        Task {
            do {
                try await dataService.deleteChapter(chapter)
                dismiss()
            } catch {
                print("Error deleting chapter: \(error.localizedDescription)")
            }
        }
    }
}
