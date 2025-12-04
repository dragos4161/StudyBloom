import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color matching the splash screen
                Color(red: 0.93, green: 0.87, blue: 0.95)
                    .ignoresSafeArea()
                
                // Display the splash screen image
                Image("SplashScreen")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashScreenView()
}
