import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.modelContext) private var modelContext
    @State private var showingHierarchyConfig = false
    @State private var showingCustomBuilder = false
    @State private var showingPhotoSettings = false  // ✅ NEW
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Queries for statistics
    @Query private var allContainers: [Container]
    @Query private var allItems: [Item]

    var body: some View {
        NavigationStack {
            Form {
                Section("Organization Style") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Style")
                                .font(.headline)
                            Text(hierarchyManager.activeConfiguration?.name ?? "Default")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let config = hierarchyManager.activeConfiguration {
                                Text("\(config.maxLevels) levels: \(levelsSummary(config))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button("Change") {
                            showingHierarchyConfig = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                    
                    // Quick action buttons
                    HStack(spacing: 12) {
                        Button {
                            showingCustomBuilder = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.purple)
                                Text("Create Custom")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            showingHierarchyConfig = true
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.blue)
                                Text("Browse All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Show current hierarchy levels with safe access
                    if let config = hierarchyManager.activeConfiguration {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your Levels:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 2)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 8)
                            ], spacing: 8) {
                                ForEach(config.sortedLevels, id: \.id) { level in
                                    HStack(spacing: 6) {
                                        Image(systemName: level.icon)
                                            .foregroundColor(level.colorEnum?.color ?? .gray)
                                            .font(.caption)
                                        Text("\(level.order). \(level.name)")
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(level.colorEnum?.color.opacity(0.1) ?? Color.gray.opacity(0.1))
                                    .foregroundColor(level.colorEnum?.color ?? .gray)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // ✅ NEW: Photo Management Section
                Section("Photos & Media") {
                    Button {
                        showingPhotoSettings = true
                    } label: {
                        HStack {
                            Label("Photo Management", systemImage: "photo.on.rectangle.angled")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Quick photo stats
                    let photoStats = getPhotoStats()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Items with Photos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(photoStats.itemsWithPhotos)")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Containers with Photos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(photoStats.containersWithPhotos)")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Inventory Summary") {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(.blue)
                        Text("Total Items")
                        Spacer()
                        Text("\(allItems.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundColor(.green)
                        Text("Total Containers")
                        Spacer()
                        Text("\(allContainers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let config = hierarchyManager.activeConfiguration {
                        let topLevelCount = allContainers.filter { $0.parentContainer == nil }.count
                        HStack {
                            Image(systemName: config.sortedLevels.first?.icon ?? "building.fill")
                                .foregroundColor(config.sortedLevels.first?.colorEnum?.color ?? .blue)
                            Text("Top Level (\(hierarchyManager.levelPluralName(for: 1)))")
                            Spacer()
                            Text("\(topLevelCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Items by category
                    let categoryStats = itemCategoryStats()
                    if !categoryStats.isEmpty {
                        DisclosureGroup("Items by Category") {
                            ForEach(categoryStats, id: \.category) { stat in
                                HStack {
                                    Text(stat.category.isEmpty ? "Uncategorized" : stat.category)
                                    Spacer()
                                    Text("\(stat.count)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("Organization Tools") {
                    Button("Create New Custom Style") {
                        showingCustomBuilder = true
                    }
                    .foregroundColor(.purple)
                    
                    Button("Browse All Organization Styles") {
                        showingHierarchyConfig = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Default Hierarchy") {
                        resetToDefaultHierarchy()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Validate Current Setup") {
                        validateSetup()
                    }
                    .foregroundColor(.green)
                }
                
                Section(header: Text("About ClutterBug")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("2.1.0 (Photo Enhanced)")
                    }
                    
                    HStack {
                        Text("Data Model Version")
                        Spacer()
                        Text("SwiftData + Dynamic + Photos")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Active Configuration")
                        Spacer()
                        Text(hierarchyManager.activeConfiguration != nil ? "✅ OK" : "❌ Missing")
                            .foregroundColor(hierarchyManager.activeConfiguration != nil ? .green : .red)
                    }
                    
                    // ✅ NEW: Photo system status
                    HStack {
                        Text("Photo System")
                        Spacer()
                        Text("✅ Enhanced")
                            .foregroundColor(.green)
                    }
                }
                
                // Debug information (can be removed in production)
                Section("Debug Information") {
                    HStack {
                        Text("Configurations Available")
                        Spacer()
                        Text("\(hierarchyManager.getAllConfigurations().count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Active Configuration")
                        Spacer()
                        Text(hierarchyManager.activeConfiguration?.name ?? "None")
                            .foregroundColor(.secondary)
                    }
                    
                    if let config = hierarchyManager.activeConfiguration {
                        HStack {
                            Text("Max Levels")
                            Spacer()
                            Text("\(config.maxLevels)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Levels Configured")
                            Spacer()
                            Text("\(config.levels.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // ✅ NEW: Photo debug info
                    let photoStats = getPhotoStats()
                    HStack {
                        Text("Total Photos")
                        Spacer()
                        Text("\(photoStats.totalPhotos)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Placeholder for future features
                Section(header: Text("Future Features")) {
                    Label("iCloud Sync", systemImage: "icloud")
                        .foregroundColor(.secondary)
                    Label("Data Export/Import", systemImage: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                    Label("Barcode Scanning", systemImage: "barcode.viewfinder")
                        .foregroundColor(.secondary)
                    Label("Advanced Search", systemImage: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Label("Map View", systemImage: "map")
                        .foregroundColor(.secondary)
                    Label("Photo Sharing", systemImage: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
                
                Section("Support") {
                    Link(destination: URL(string: "mailto:support@clutterbug.app")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://clutterbug.app/help")!) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Help & Documentation")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingHierarchyConfig) {
                NavigationStack {
                    HierarchyConfigurationView()
                        .environmentObject(hierarchyManager)
                }
            }
            .sheet(isPresented: $showingCustomBuilder) {
                NavigationStack {
                    EnhancedCustomHierarchyBuilderView()
                        .environmentObject(hierarchyManager)
                }
            }
            // ✅ NEW: Photo settings sheet
            .sheet(isPresented: $showingPhotoSettings) {
                PhotoSettingsView()
            }
            .alert("Setup Issue", isPresented: $showingError) {
                Button("OK") { }
                if errorMessage.contains("Failed") {
                    Button("Reset") { resetToDefaultHierarchy() }
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func levelsSummary(_ config: HierarchyConfiguration) -> String {
        let levelNames = config.sortedLevels.prefix(3).map { $0.name }
        if config.maxLevels > 3 {
            return levelNames.joined(separator: ", ") + "..."
        } else {
            return levelNames.joined(separator: ", ")
        }
    }
    
    private func itemCategoryStats() -> [CategoryStat] {
        let grouped = Dictionary(grouping: allItems) { $0.category }
        return grouped.map { CategoryStat(category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }
    
    // ✅ NEW: Get photo statistics
    private func getPhotoStats() -> PhotoStats {
        let itemsWithPhotos = allItems.filter { $0.photoIdentifier != nil }.count
        let containersWithPhotos = allContainers.filter { $0.photoIdentifier != nil }.count
        
        return PhotoStats(
            itemsWithPhotos: itemsWithPhotos,
            containersWithPhotos: containersWithPhotos,
            totalPhotos: itemsWithPhotos + containersWithPhotos
        )
    }
    
    private func resetToDefaultHierarchy() {
        print("🔄 Resetting to default hierarchy...")
        hierarchyManager.createDefaultIfNeeded()
        
        if let defaultConfig = hierarchyManager.getAllConfigurations().first(where: { $0.isDefault }) {
            hierarchyManager.switchToConfiguration(defaultConfig)
            errorMessage = "✅ Reset to default hierarchy successfully!"
            showingError = true
        } else {
            errorMessage = "⚠️ No default configuration found. Please create a custom one."
            showingError = true
        }
    }
    
    private func validateSetup() {
        print("🔍 Validating setup...")
        
        let configurations = hierarchyManager.getAllConfigurations()
        
        if configurations.isEmpty {
            errorMessage = "❌ No hierarchy configurations found. This shouldn't happen!"
            showingError = true
            return
        }
        
        if hierarchyManager.activeConfiguration == nil {
            errorMessage = "❌ No active configuration set. Fixing this now..."
            showingError = true
            resetToDefaultHierarchy()
            return
        }
        
        guard let activeConfig = hierarchyManager.activeConfiguration else {
            errorMessage = "❌ Active configuration is nil after reset"
            showingError = true
            return
        }
        
        // Validate active configuration
        if activeConfig.levels.isEmpty {
            errorMessage = "❌ Active configuration has no levels defined"
            showingError = true
            return
        }
        
        if activeConfig.maxLevels != activeConfig.levels.count {
            errorMessage = "⚠️ Configuration mismatch: says \(activeConfig.maxLevels) levels but has \(activeConfig.levels.count)"
            showingError = true
            return
        }
        
        // Check for orphaned containers
        let orphanedContainers = allContainers.filter { container in
            container.levelNumber > activeConfig.maxLevels
        }
        
        if !orphanedContainers.isEmpty {
            errorMessage = "⚠️ Found \(orphanedContainers.count) containers with levels higher than current max (\(activeConfig.maxLevels))"
            showingError = true
            return
        }
        
        // ✅ NEW: Validate photos
        let photoStats = getPhotoStats()
        
        // All good
        errorMessage = "✅ Setup validation passed! Everything looks good.\n\nConfigurations: \(configurations.count)\nActive: \(activeConfig.name)\nContainers: \(allContainers.count)\nItems: \(allItems.count)\nPhotos: \(photoStats.totalPhotos)"
        showingError = true
    }
}

// MARK: - Supporting Types
struct CategoryStat {
    let category: String
    let count: Int
}

// ✅ NEW: Photo statistics
struct PhotoStats {
    let itemsWithPhotos: Int
    let containersWithPhotos: Int
    let totalPhotos: Int
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    let hierarchyManager: HierarchyManager
    
    do {
        container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        hierarchyManager = HierarchyManager(modelContext: container.mainContext)
        
        // Create some sample data for preview
        let sampleContainer = Container(name: "Sample Workshop", containerType: "level_1")
        container.mainContext.insert(sampleContainer)
        
        let sampleItem = Item(name: "Sample Tool", category: "Tools", quantity: 1, condition: "Good", parentContainer: sampleContainer)
        container.mainContext.insert(sampleItem)
        
        return SettingsView()
            .environmentObject(hierarchyManager)
            .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
