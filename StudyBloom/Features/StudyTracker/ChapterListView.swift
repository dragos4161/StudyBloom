import SwiftUI
import SwiftData

struct ChapterListView: View {
    @Query(sort: \Chapter.orderIndex) private var chapters: [Chapter]
    @Environment(\.modelContext) var modelContext
    
    @State private var selectedChapter: Chapter?
    @State private var isShowingAddChapter = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(chapters) { chapter in
                    Button(action: {
                        selectedChapter = chapter
                    }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: chapter.colorHex) ?? .gray)
                                .frame(width: 6, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text(chapter.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                HStack {
                                    ProgressView(value: Double(chapter.pagesStudied), total: Double(chapter.totalPages))
                                        .tint(Color(hex: chapter.colorHex) ?? .purple)
                                    Text("\(chapter.pagesStudied)/\(chapter.totalPages)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onMove(perform: moveChapters)
                .onDelete(perform: deleteChapters)
            }
            .navigationTitle("Study Material")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddChapter = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(item: $selectedChapter) { chapter in
                LogProgressView(chapter: chapter) { newPages in
                    chapter.pagesStudied = newPages
                    // Auto-save handled by SwiftData context usually, but good to be explicit if needed
                }
            }
            .sheet(isPresented: $isShowingAddChapter) {
                AddChapterView()
            }
        }
    }
    
    private func moveChapters(from source: IndexSet, to destination: Int) {
        var updatedChapters = chapters
        updatedChapters.move(fromOffsets: source, toOffset: destination)
        
        // Update orderIndex for all affected chapters
        for (index, chapter) in updatedChapters.enumerated() {
            chapter.orderIndex = index
        }
    }
    
    private func deleteChapters(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(chapters[index])
        }
    }
}

#Preview {
    ChapterListView()
        .modelContainer(for: Chapter.self, inMemory: true)
}
