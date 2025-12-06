import SwiftUI

struct TimerRingView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            // Track (matches outer glow gradient exactly)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.15), .blue.opacity(0.05)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    lineWidth: 20
                )
            
            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress) // Smooth linear updates
        }
    }
}
