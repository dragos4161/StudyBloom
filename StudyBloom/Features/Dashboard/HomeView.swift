import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var selection: NavigationItem? = .study
    @EnvironmentObject var badgeManager: BadgeManager
    
    // For TabView binding (requires non-optional)
    @State private var tabSelection: NavigationItem = .study
    @State private var isShowingMoreSheet = false
    
    enum NavigationItem: String, CaseIterable, Identifiable {
        case study = "Study"
        case chapters = "Chapters"
        case flashcards = "Flashcards"
        case social = "Social"
        case more = "More"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .study: return "book.fill"
            case .chapters: return "list.bullet"
            case .flashcards: return "rectangle.on.rectangle.angled"
            case .social: return "person.2.fill"
            case .more: return "square.grid.2x2.fill"
            }
        }
    }
    
    @State private var lastSelection: NavigationItem = .study
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                // iPhone Layout
                if #available(iOS 18.0, *) {
                    TabView(selection: $tabSelection) {
                        Tab("Study", systemImage: "book.fill", value: .study) {
                            NavigationStack {
                                StudyDashboardView()
                            }
                        }
                        
                        Tab("Chapters", systemImage: "list.bullet", value: .chapters) {
                            NavigationStack {
                                ChapterListView()
                            }
                        }
                        
                        Tab("Flashcards", systemImage: "rectangle.on.rectangle.angled", value: .flashcards) {
                            NavigationStack {
                                FlashcardDeckView()
                            }
                        }
                        
                        Tab("Social", systemImage: "person.2.fill", value: .social) {
                            NavigationStack {
                                SocialView()
                            }
                            // Badge logic for iOS 18?
                            // .badge() modifier works on Tab content usually.
                        }
                        .badge(badgeManager.friendRequestCount)
                        
                        Tab("More", systemImage: "square.grid.2x2.fill", value: .more, role: .search) {
                             NavigationStack {
                                 MoreView()
                             }
                        }
                    }
                } else {
                    // Legacy iOS < 18 Layout
                    TabView(selection: $tabSelection) {
                        NavigationStack {
                            StudyDashboardView()
                        }
                        .tabItem { Label("Study", systemImage: "book.fill") }
                        .tag(NavigationItem.study)
                        
                        NavigationStack {
                            ChapterListView()
                        }
                        .tabItem { Label("Chapters", systemImage: "list.bullet") }
                        .tag(NavigationItem.chapters)
                        
                        NavigationStack {
                            FlashcardDeckView()
                        }
                        .tabItem { Label("Flashcards", systemImage: "rectangle.on.rectangle.angled") }
                        .tag(NavigationItem.flashcards)
                        
                        NavigationStack {
                            SocialView()
                        }
                        .tabItem { Label("Social", systemImage: "person.2.fill") }
                        .tag(NavigationItem.social)
                        .badge(badgeManager.friendRequestCount)
                        
                        // "More" Tab - dummy view, intercepted by onChange
                        Color.clear
                            .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
                            .tag(NavigationItem.more)
                    }
                    .onChange(of: tabSelection) { newValue in
                        if newValue == .more {
                            isShowingMoreSheet = true
                            tabSelection = lastSelection
                        } else {
                            lastSelection = newValue
                        }
                    }
                }
            } else {
                // iPad Layout (unchanged)
                NavigationSplitView {
                    List(NavigationItem.allCases, selection: $selection) { item in
                        Label(item.rawValue, systemImage: item.icon)
                            .tag(item)
                    }
                    .navigationTitle("StudyBloom")
                } detail: {
                    // Determine view based on selection
                    // Default to Study if selection is nil
                    NavigationStack {
                        switch selection ?? .study {
                        case .study: StudyDashboardView()
                        case .chapters: ChapterListView()
                        case .flashcards: FlashcardDeckView()
                        case .social: SocialView()
                        case .more: MoreView()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingMoreSheet) {
            NavigationStack {
                MoreView()
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            SocialService.shared.startListeningForFriendRequests()
        }
    }
}

#Preview {
    HomeView()
}

struct MoreView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Dashboard", systemImage: "gauge")
                        .foregroundColor(.primary)
                }
                
                NavigationLink {
                    AnalyticsView()
                } label: {
                    Label("Analytics", systemImage: "chart.bar.fill")
                        .foregroundColor(.primary)
                }
                
                NavigationLink {
                    ProfileView()
                } label: {
                    Label("Profile", systemImage: "person.circle")
                        .foregroundColor(.primary)
                }
            } header: {
                Text("More Options")
            }
        }
        .navigationTitle("More")
    }
}
