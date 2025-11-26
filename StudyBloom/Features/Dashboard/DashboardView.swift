import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Chapter.orderIndex) private var chapters: [Chapter]
    @Environment(\.modelContext) var modelContext
    @AppStorage("userName") private var userName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome / Overview
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome Back, \(userName)!")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Here's your study progress.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Chapter Summaries
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Chapters")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if chapters.isEmpty {
                            Text("No chapters added yet.")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(chapters) { chapter in
                                    ChapterSummaryCard(chapter: chapter)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct ChapterSummaryCard: View {
    let chapter: Chapter
    
    var progress: Double {
        guard chapter.totalPages > 0 else { return 0 }
        return Double(chapter.pagesStudied) / Double(chapter.totalPages)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(chapter.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
            }
            
            ProgressView(value: progress)
                .tint(.white)
                .background(Color.black.opacity(0.1))
            
            HStack {
                Text("\(chapter.pagesStudied) of \(chapter.totalPages) pages")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.black)
                Spacer()
            }
        }
        .padding()
        .background(Color(hex: chapter.colorHex) ?? .blue)
        .foregroundColor(.white) // Assuming pastel colors are dark enough? Or maybe we need black text for pastels.
        // User asked for pastel colors, which are usually light. So black text is better.
        .foregroundColor(.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Chapter.self, inMemory: true)
}
