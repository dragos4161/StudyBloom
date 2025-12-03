import SwiftUI

struct AddChapterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    private var chapters: [Chapter] { dataService.chapters }
    
    @State private var title = ""
    @State private var totalPages = ""
    @State private var selectedColorHex = "#FFB3BA" // Default pastel red
    
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
            }
            .navigationTitle("New Chapter")
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
        guard let userId = dataService.currentUserId else { return }
        
        // Calculate order index (append to end)
        let maxOrderIndex = chapters.map { $0.orderIndex }.max() ?? -1
        let newOrderIndex = maxOrderIndex + 1
        
        let newChapter = Chapter(
            userId: userId,
            title: title,
            totalPages: pages,
            orderIndex: newOrderIndex,
            colorHex: selectedColorHex
        )
        
        Task {
            do {
                try await dataService.addChapter(newChapter)
                dismiss()
            } catch {
                print("Error adding chapter: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    AddChapterView()
}
