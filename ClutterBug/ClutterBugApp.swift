import SwiftUI
import SwiftData

@main
struct ClutterBugApp: App {
    // ✅ ENHANCED: Static shared container with better error handling
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Container.self,
            Item.self,
            HierarchyConfiguration.self,
            HierarchyLevel.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully")
            return container
        } catch {
            print("❌ CRITICAL: Could not create ModelContainer: \(error.localizedDescription)")
            print("❌ App may not function correctly")
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }()
    
    // ✅ ENHANCED: Safe hierarchy manager initialization
    @StateObject private var hierarchyManager: HierarchyManager
    
    init() {
        print("🚀 Initializing ClutterBugApp...")
        
        // ✅ Use safe initialization method
        let manager = HierarchyManager.safeInitialize(modelContext: Self.sharedModelContainer.mainContext)
        self._hierarchyManager = StateObject(wrappedValue: manager)
        
        print("✅ HierarchyManager initialized")
    }

    var body: some Scene {
        let modelContainer = Self.sharedModelContainer

        WindowGroup {
            ContentView()
                .environmentObject(hierarchyManager)
                .modelContainer(modelContainer)
                .onAppear {
                    print("📱 ContentView appeared")
                    setupApp()
                }
                .task {
                    // ✅ Async setup with proper error handling
                    await performAsyncSetup()
                }
        }
    }
    
    // ✅ ENHANCED: Synchronous setup
    private func setupApp() {
        print("🔧 Setting up app...")
        
        // Ensure hierarchy manager is properly configured
        hierarchyManager.createDefaultIfNeeded()
        
        // Validate setup
        let configs = hierarchyManager.getAllConfigurations()
        print("📊 Found \(configs.count) hierarchy configurations")
        
        if let active = hierarchyManager.activeConfiguration {
            print("✅ Active configuration: \(active.name)")
        } else {
            print("⚠️ No active configuration found")
        }
    }
    
    // ✅ ENHANCED: Async setup with better error handling
    @MainActor
    private func performAsyncSetup() async {
        print("🔄 Performing async setup...")
        
        do {
            // Check for existing containers
            let containerFetchDescriptor = FetchDescriptor<Container>()
            let existingContainers = try Self.sharedModelContainer.mainContext.fetch(containerFetchDescriptor)
            
            print("📦 Found \(existingContainers.count) existing containers")
            
            if existingContainers.isEmpty {
                print("🏗️ Creating default sample data...")
                await ContainerDataSetup.ensureDefaultHierarchyExists(
                    modelContext: Self.sharedModelContainer.mainContext,
                    hierarchyManager: hierarchyManager
                )
            } else {
                print("✅ Existing containers found, skipping sample data creation")
                
                // Log some stats for debugging
                let topLevel = existingContainers.filter { $0.parentContainer == nil }
                print("📊 Top-level containers: \(topLevel.count)")
                
                let totalItems = existingContainers.reduce(0) { total, container in
                    return total + container.totalItemCount
                }
                print("📊 Total items across all containers: \(totalItems)")
            }
        } catch {
            print("❌ Error in async setup: \(error.localizedDescription)")
            // Don't crash the app, just log the error
        }
    }
}

// ✅ ENHANCED: Container Data Setup with better error handling
struct ContainerDataSetup {
    @MainActor
    static func ensureDefaultHierarchyExists(modelContext: ModelContext, hierarchyManager: HierarchyManager) async {
        print("🏗️ Creating default hierarchy...")
        
        // Ensure we have an active configuration
        if hierarchyManager.activeConfiguration == nil {
            print("❌ No active hierarchy configuration found")
            hierarchyManager.createDefaultIfNeeded()
            
            if hierarchyManager.activeConfiguration == nil {
                print("❌ Still no active configuration after createDefaultIfNeeded()")
                return
            }
            
            print("✅ Fixed: Now using configuration: \(hierarchyManager.activeConfiguration?.name ?? "Unknown")")
        }
        
        // At this point we know we have an active configuration
        guard let config = hierarchyManager.activeConfiguration else {
            print("❌ Unexpected: Active configuration became nil")
            return
        }
        
        let topLevelName = hierarchyManager.levelName(for: 1)
        let defaultName = "My \(topLevelName)"
        
        print("📝 Creating default \(topLevelName): '\(defaultName)'")
        
        let predicate = #Predicate<Container> { container in
            container.parentContainer == nil
        }
        
        let fetchDescriptor = FetchDescriptor<Container>(predicate: predicate)

        do {
            let existingTopLevel = try modelContext.fetch(fetchDescriptor)
            
            if existingTopLevel.isEmpty {
                print("🏗️ No existing top-level containers, creating sample hierarchy...")
                
                let sampleHierarchy = try await createSampleHierarchy(
                    modelContext: modelContext,
                    hierarchyManager: hierarchyManager,
                    rootName: defaultName
                )
                
                if let rootContainer = sampleHierarchy {
                    try modelContext.save()
                    print("✅ Default hierarchy created successfully!")
                    print("🏗️ Configuration: \(config.name)")
                    print("📊 Total containers: \(rootContainer.calculateAllContainerCount())")
                    print("📦 Total items: \(rootContainer.totalItemCount)")
                } else {
                    print("❌ Failed to create sample hierarchy")
                }
                
            } else {
                print("✅ Top-level containers already exist:")
                for container in existingTopLevel {
                    print("   - \(container.name) (Level \(container.levelNumber))")
                }
            }
        } catch {
            print("❌ Error in ensureDefaultHierarchyExists: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    static func createSampleHierarchy(
        modelContext: ModelContext,
        hierarchyManager: HierarchyManager,
        rootName: String
    ) async throws -> Container? {
        
        guard let config = hierarchyManager.activeConfiguration else {
            print("❌ No active configuration for sample hierarchy creation")
            return nil
        }
        
        print("🏗️ Creating sample hierarchy with \(config.maxLevels) levels")
        
        // Create root container (Level 1)
        guard let rootContainer = Container.createDynamic(
            name: rootName,
            level: 1,
            parentContainer: nil,
            hierarchyManager: hierarchyManager,
            mapX: 150.0,
            mapY: 200.0
        ) else {
            print("❌ Failed to create root container")
            return nil
        }
        
        rootContainer.purpose = "Main \(hierarchyManager.levelName(for: 1).lowercased()) and storage facility"
        modelContext.insert(rootContainer)
        print("✅ Created root: \(rootContainer.name)")
        
        // Create intermediate levels if needed
        var currentParent = rootContainer
        for level in 2..<config.maxLevels {
            let levelName = hierarchyManager.levelName(for: level)
            
            guard let container = Container.createDynamic(
                name: "Main \(levelName)",
                level: level,
                parentContainer: currentParent,
                hierarchyManager: hierarchyManager
            ) else {
                print("❌ Failed to create container at level \(level)")
                break
            }
            
            container.purpose = "Primary \(levelName.lowercased()) for storage"
            modelContext.insert(container)
            currentParent = container
            print("✅ Created level \(level): \(container.name)")
        }
        
        // Create final level containers with sample items
        let finalLevel = config.maxLevels
        let finalLevelName = hierarchyManager.levelName(for: finalLevel)
        
        // Tools container
        if let toolsContainer = Container.createDynamic(
            name: "\(finalLevelName) - Tools",
            level: finalLevel,
            parentContainer: currentParent,
            hierarchyManager: hierarchyManager
        ) {
            toolsContainer.purpose = "Tools and equipment"
            modelContext.insert(toolsContainer)
            
            // Add sample tool
            let drill = Item(
                name: "Cordless Drill",
                category: "Power Tools",
                quantity: 1,
                condition: "Good",
                parentContainer: toolsContainer
            )
            drill.notes = "20V battery included"
            modelContext.insert(drill)
            print("✅ Created tools container with sample drill")
        }
        
        // Parts container
        if let partsContainer = Container.createDynamic(
            name: "\(finalLevelName) - Parts",
            level: finalLevel,
            parentContainer: currentParent,
            hierarchyManager: hierarchyManager
        ) {
            partsContainer.purpose = "Hardware and small parts"
            modelContext.insert(partsContainer)
            
            // Add sample parts
            let screws = Item(
                name: "Wood Screws Assortment",
                category: "Fasteners",
                quantity: 100,
                condition: "New",
                parentContainer: partsContainer
            )
            screws.notes = "Various lengths and sizes"
            modelContext.insert(screws)
            print("✅ Created parts container with sample screws")
        }
        
        return rootContainer
    }
}

// ✅ ENHANCED: Container Extension with safe counting
extension Container {
    func calculateAllContainerCount() -> Int {
        let childCount = childContainers?.count ?? 0
        let subChildCount = childContainers?.reduce(0, { total, container in
            return total + container.calculateAllContainerCount()
        }) ?? 0
        return childCount + subChildCount
    }
    
    // ✅ Safe total item count to prevent crashes
    var safeTotalItemCount: Int {
        let directItems = items?.count ?? 0
        let childItems = childContainers?.reduce(0, { total, container in
            return total + container.safeTotalItemCount
        }) ?? 0
        return directItems + childItems
    }
}
