import SwiftUI

struct ChapterListView: View {
    @EnvironmentObject var dataService: DataService
    
    private var chapters: [Chapter] { dataService.chapters }
    
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
                    var updatedChapter = chapter
                    updatedChapter.pagesStudied = newPages
                    
                    Task {
                        try? await dataService.updateChapter(updatedChapter)
                    }
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
        
        Task {
            try? await dataService.reorderChapters(updatedChapters)
        }
    }
    
    private func deleteChapters(at offsets: IndexSet) {
        for index in offsets {
            let chapter = chapters[index]
            Task {
                try? await dataService.deleteChapter(chapter)
            }
        }
    }
}

#Preview {
    ChapterListView()
        .environmentObject(DataService())
}
