import SwiftUI

struct LogProgressView: View {
    @Environment(\.dismiss) var dismiss
    @State private var pagesRead: Double = 0
    @State private var isSaving = false
    
    let chapter: Chapter
    let onSave: (Int) -> Void
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Log Progress")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Text(chapter.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Circular Progress Interaction
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: pagesRead / Double(chapter.totalPages))
                        .stroke(
                            AngularGradient(colors: [.blue, .purple], center: .center),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: pagesRead)
                    
                    VStack {
                        Text("\(Int(pagesRead))")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText(value: pagesRead))
                        Text("pages")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Slider Control
                VStack(spacing: 10) {
                    Slider(value: $pagesRead, in: 0...Double(chapter.totalPages), step: 1)
                        .tint(.purple)
                    
                    HStack {
                        Text("0")
                        Spacer()
                        Text("\(chapter.totalPages)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    isSaving = true
                    // Simulate network delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onSave(Int(pagesRead))
                        dismiss()
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Progress")
                                .fontWeight(.bold)
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Initialize with current progress
            pagesRead = Double(chapter.pagesStudied)
        }
    }
}

#Preview {
    LogProgressView(
        chapter: Chapter(userId: "test", title: "Cardiology", totalPages: 120, orderIndex: 0, pagesStudied: 45),
        onSave: { _ in }
    )
}
