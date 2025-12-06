import SwiftUI

struct LogProgressView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var pagesToAdd: Double = 0
    @State private var isSaving = false
    
    let chapter: Chapter
    let onSave: (Int) -> Void
    
    // Limits
    private var maxPagesToAdd: Double {
        Double(max(0, chapter.totalPages - chapter.pagesStudied))
    }
    
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ZStack {
            // Background Layer
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Log Progress")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(chapter.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    
                    // Dual Ring Visualization
                    ZStack {
                        // --- OUTER RING: TOTAL PROGRESS ---
                        // Track
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                            .frame(width: 220, height: 220)
                        
                        // Fill (Current + Added)
                        Circle()
                            .trim(from: 0, to: (Double(chapter.pagesStudied) + pagesToAdd) / Double(chapter.totalPages))
                            .stroke(
                                Color.blue,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 220, height: 220)
                            .animation(.spring(response: 0.4), value: pagesToAdd)
                        
                        // --- INNER RING: SESSION EFFORT ---
                        // Track
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                            .frame(width: 190, height: 190) // Increased size to reduce gap
                        
                        // Fill (Session % of Remaining)
                        Circle()
                            .trim(from: 0, to: maxPagesToAdd > 0 ? pagesToAdd / maxPagesToAdd : 0)
                            .stroke(
                                Color.purple,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 190, height: 190)
                            .animation(.spring(response: 0.4), value: pagesToAdd)
                        
                        // Center Text
                        VStack(spacing: 2) {
                            Text("+\(Int(pagesToAdd))")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .contentTransition(.numericText(value: pagesToAdd))
                                .foregroundStyle(.purple)
                            Text("pages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Status Text
                    HStack(spacing: 40) {
                        VStack(spacing: 2) {
                            Text("Current Limit")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text("\(chapter.pagesStudied + Int(pagesToAdd))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(spacing: 2) {
                            Text("Total Goal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text("\(chapter.totalPages)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // Slider Control
                    VStack(spacing: 12) {
                        if maxPagesToAdd > 0 {
                            Slider(value: $pagesToAdd, in: 0...maxPagesToAdd, step: 1)
                                .tint(.purple)
                        } else {
                            Text("Goal Achieved! 🎉")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer(minLength: 20)
                    
                    // Save Button
                    Button(action: {
                        isSaving = true
                        // Calculate new total
                        let newTotal = chapter.pagesStudied + Int(pagesToAdd)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSave(newTotal)
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Add Logs")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    .disabled(pagesToAdd == 0)
                    .opacity(pagesToAdd == 0 ? 0.6 : 1.0)
                }
            }
        }
        .presentationDetents(UIDevice.current.userInterfaceIdiom == .pad ? [.large] : [.fraction(0.75)]) // Locked to 0.85 for iPhone
        .presentationDragIndicator(.visible)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    LogProgressView(
        chapter: Chapter(userId: "test", title: "Cardiology", totalPages: 120, orderIndex: 0, pagesStudied: 45),
        onSave: { _ in }
    )
}
