import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var selection: NavigationItem? = .home
    @EnvironmentObject var badgeManager: BadgeManager
    
    // For TabView binding (requires non-optional)
    @State private var tabSelection: NavigationItem = .home
    
    enum NavigationItem: String, CaseIterable, Identifiable {
        case home = "Home"
        case study = "Study"
        case flashcards = "Flashcards"
        case chapters = "Chapters"
        case social = "Social"
        case analytics = "Analytics"
        case profile = "Profile"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .study: return "book.fill"
            case .flashcards: return "rectangle.on.rectangle.angled"
            case .chapters: return "list.bullet"
            case .social: return "person.2.fill"
            case .analytics: return "chart.bar.fill"
            case .profile: return "person"
            }
        }
    }
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                // iPhone Layout
                TabView(selection: $tabSelection) {
                    NavigationStack {
                        DashboardView()
                    }
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(NavigationItem.home)
                    
                    NavigationStack {
                        StudyDashboardView()
                    }
                    .tabItem { Label("Study", systemImage: "book.fill") }
                    .tag(NavigationItem.study)
                    
                    NavigationStack {
                        FlashcardDeckView()
                    }
                    .tabItem { Label("Flashcards", systemImage: "rectangle.on.rectangle.angled") }
                    .tag(NavigationItem.flashcards)
                    
                    NavigationStack {
                        ChapterListView()
                    }
                    .tabItem { Label("Chapters", systemImage: "list.bullet") }
                    .tag(NavigationItem.chapters)
                    
                    NavigationStack {
                        SocialView()
                    }
                    .tabItem { Label("Social", systemImage: "person.2.fill") }
                    .tag(NavigationItem.social)
                    .badge(badgeManager.friendRequestCount)
                    
                    NavigationStack {
                        AnalyticsView()
                    }
                    .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                    .tag(NavigationItem.analytics)
                    
                    NavigationStack {
                        ProfileView()
                    }
                    .tabItem { Label("Profile", systemImage: "person") }
                    .tag(NavigationItem.profile)
                }
            } else {
                // iPad Layout
                NavigationSplitView {
                    List(NavigationItem.allCases, selection: $selection) { item in
                        Label(item.rawValue, systemImage: item.icon)
                            .tag(item)
                    }
                    .navigationTitle("StudyBloom")
                } detail: {
                    // Determine view based on selection
                    // Default to Home if selection is nil
                    switch selection ?? .home {
                    case .home: DashboardView()
                    case .study: StudyDashboardView()
                    case .flashcards: FlashcardDeckView()
                    case .chapters: ChapterListView()
                    case .social: SocialView()
                    case .analytics: AnalyticsView()
                    case .profile: ProfileView()
                    }
                }
            }
        }
        .onAppear {
            SocialService.shared.startListeningForFriendRequests()
        }
    }
}

#Preview {
    HomeView()
}
