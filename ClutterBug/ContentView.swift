import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(hierarchyManager)
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                    .environmentObject(hierarchyManager)
            }
        }
        .onAppear {
            print("📱 ContentView appeared, onboarding completed: \(hasCompletedOnboarding)")
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 0) {
                    ContainerListView()
                        .environmentObject(hierarchyManager)
                    
                    QuickPhotoToolbar()
                }
            }
            .tabItem {
                Label("Containers", systemImage: "square.stack.3d.up.fill")
            }
            
            // 🆕 NEW: Add this Map tab between Containers and Photos
            NavigationStack {
                MapView()
                    .environmentObject(hierarchyManager)
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            
            NavigationStack {
                EnhancedPhotoGridView()
                    .environmentObject(hierarchyManager)
            }
            .tabItem {
                Label("Photos", systemImage: "photo.on.rectangle.angled")
            }
            
            NavigationStack {
                SearchView()
                    .environmentObject(hierarchyManager)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            NavigationStack {
                UPCScanView()
                    .environmentObject(hierarchyManager)
            }
            .tabItem {
                Label("Scan", systemImage: "barcode.viewfinder")
            }
            
            NavigationStack {
                SettingsView()
                    .environmentObject(hierarchyManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager.safeInitialize(modelContext: container.mainContext)
        
        return ContentView()
            .environmentObject(hierarchyManager)
            .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
