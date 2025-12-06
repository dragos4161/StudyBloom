import SwiftUI

struct CalmingAnimationView: View {
    @State private var breathing = false
    
    var body: some View {
        ZStack {
            // Core (Breathing)
            Circle()
                .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 220, height: 220) // Increased to fill ring
                .scaleEffect(breathing ? 1.05 : 0.95) // Subtle pulse to avoid hitting edges
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathing)
            
            // Outer Glow (Static filling space)
            Circle()
                .fill(LinearGradient(colors: [.cyan.opacity(0.15), .blue.opacity(0.05)], startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 280, height: 280) // Larger to fill space up to ring (300)
                // No animation, just static presence
            
            // Particles/Orbs (Simulated)
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat(30 + i * 10), height: CGFloat(30 + i * 10))
                    .offset(x: breathing ? CGFloat(30 + i * 20) : CGFloat(-30 - i * 20),
                            y: breathing ? CGFloat(-20 + i * 10) : CGFloat(20 - i * 10))
                    .blur(radius: 5)
                    .animation(.easeInOut(duration: Double(3 + i)).repeatForever(autoreverses: true), value: breathing)
            }
        }
        .onAppear {
            breathing = true
        }
    }
}

#Preview {
    CalmingAnimationView()
        .preferredColorScheme(.dark)
}
