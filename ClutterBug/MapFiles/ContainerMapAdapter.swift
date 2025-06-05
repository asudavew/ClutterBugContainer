import SwiftUI
import SwiftData

// MARK: - Container Map Adapter
// Bridges between the new Container system and the existing map system

struct ContainerMapAdapter: View {
    let container: Container?
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if let container = container {
            // Since MapView now manages its own container selection,
            // we'll use the enhanced map view that can accept a container
            EnhancedMapView(container: container)
                .environmentObject(hierarchyManager)
                .onReceive(NotificationCenter.default.publisher(for: .shapeCreated)) { notification in
                    handleShapeCreated(notification, for: container)
                }
        } else {
            // No container selected - show instruction
            ContentUnavailableView(
                "Select a Container",
                systemImage: "map.circle",
                description: Text("Choose a container from the list to view its map")
            )
        }
    }
    
    // MARK: - Shape Creation Handler
    
    private func handleShapeCreated(_ notification: Notification, for parentContainer: Container) {
        guard let userInfo = notification.userInfo,
              let shape = userInfo["shape"] as? PlacedShape else {
            return
        }
        
        // Calculate what level the new container should be
        let nextLevel = parentContainer.levelNumber + 1
        
        // Check if we can add this level
        guard nextLevel <= hierarchyManager.maxLevels() else {
            print("⚠️ Cannot add container at level \(nextLevel) - exceeds max levels")
            return
        }
        
        // Create a new Container from the PlacedShape
        guard let newContainer = Container.createDynamic(
            name: shape.label,
            level: nextLevel,
            parentContainer: parentContainer,
            hierarchyManager: hierarchyManager,
            mapX: Double(shape.position.x),
            mapY: Double(shape.position.y)
        ) else {
            print("❌ Failed to create container from shape")
            return
        }
        
        // Set the container's shape properties based on the PlacedShape
        newContainer.shapeType = shape.type.rawValue
        newContainer.colorType = shape.colorType.rawValue
        newContainer.rotation = shape.rotation
        newContainer.mapWidth = Double(shape.width)
        newContainer.mapHeight = Double(shape.length)
        
        // Set dimensions based on shape type
        newContainer.length = shape.length
        newContainer.width = shape.width
        newContainer.side3 = shape.side3
        newContainer.side4 = shape.side4
        
        // Insert and save
        modelContext.insert(newContainer)
        
        do {
            try modelContext.save()
            print("✅ Created \(hierarchyManager.levelName(for: nextLevel)) from map shape: '\(shape.label)'")
        } catch {
            print("❌ Error saving container from shape: \(error)")
        }
    }
}

// MARK: - Enhanced Map View Integration
struct EnhancedMapView: View {
    let container: Container?
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Container info header if we have a specific container
                if let container = container {
                    containerHeader(for: container)
                }
                
                // Use the existing MapView but in a way that works with current implementation
                MapView()
                    .environmentObject(hierarchyManager)
            }
            .navigationTitle(container?.name ?? "Map View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Map Options", systemImage: "ellipsis.circle") {
                        Button("Show Child Containers", systemImage: "square.stack.3d.up") {
                            // Show child containers as shapes on map
                        }
                        
                        Button("Add Container Shape", systemImage: "plus.square") {
                            // Enable shape adding mode
                        }
                        
                        Divider()
                        
                        Button("Map Settings", systemImage: "gear") {
                            // Show map settings
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func containerHeader(for container: Container) -> some View {
        HStack {
            PhotoOrIcon(
                photoIdentifier: container.photoIdentifier,
                fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
                fallbackColor: container.colorTypeEnum?.color ?? .blue,
                size: .medium
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(container.name)
                    .font(.headline)
                
                Text(container.safeDynamicType(using: hierarchyManager).displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let purpose = container.purpose {
                    Text(purpose)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let childCount = container.childContainers?.count, childCount > 0 {
                    Text("\(childCount) containers")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if container.totalItemCount > 0 {
                    Text("\(container.totalItemCount) items")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Notification for Shape Creation
extension Notification.Name {
    static let shapeCreated = Notification.Name("shapeCreated")
}

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager.safeInitialize(modelContext: container.mainContext)
        
        let sampleContainer = Container.createBuilding(name: "Sample Workshop")
        container.mainContext.insert(sampleContainer)
        
        return EnhancedMapView(container: sampleContainer)
            .environmentObject(hierarchyManager)
            .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
