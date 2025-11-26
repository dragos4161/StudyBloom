import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            StudyDashboardView()
                .tabItem {
                    Label("Study", systemImage: "book.fill")
                }
            
            ChapterListView()
                .tabItem {
                    Label("Chapters", systemImage: "list.bullet")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

// Placeholder views are now in their own files


#Preview {
    HomeView()
}
