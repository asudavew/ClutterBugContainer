import Foundation
import SwiftData
import SwiftUI

// MARK: - Hierarchy Manager
class HierarchyManager: ObservableObject {
    @Published var activeConfiguration: HierarchyConfiguration?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadActiveConfiguration()
    }
    
    private func loadActiveConfiguration() {
        let predicate = #Predicate<HierarchyConfiguration> { $0.isActive == true }
        let descriptor = FetchDescriptor<HierarchyConfiguration>(predicate: predicate)
        
        do {
            let configs = try modelContext.fetch(descriptor)
            activeConfiguration = configs.first
            if activeConfiguration == nil {
                createDefaultIfNeeded() // Attempt to create defaults if no active config found
            }
        } catch {
            print("Error loading active configuration: \(error)")
            createDefaultIfNeeded() // Always attempt to create defaults on error
        }
    }
    
    func createDefaultIfNeeded() {
        let allConfigs = (try? modelContext.fetch(FetchDescriptor<HierarchyConfiguration>())) ?? []
        
        if allConfigs.isEmpty {
            let defaultConfigs = HierarchyPresets.createDefaultConfigurations()
            for config in defaultConfigs {
                // It's crucial to insert before setting relationships for SwiftData
                modelContext.insert(config) // Insert config first
                for level in config.levels {
                    // SwiftData expects the object to be in context or already inserted
                    // before establishing relationships.
                    modelContext.insert(level) // Insert level before assigning config
                    level.configuration = config
                }
            }
            
            // Set workshop as active
            if let workshop = defaultConfigs.first(where: { $0.isDefault }) {
                workshop.isActive = true
                activeConfiguration = workshop
            }
            
            do {
                try modelContext.save()
                print("✅ Default hierarchy configurations created")
            } catch {
                print("❌ Error saving default configurations: \(error)")
            }
        } else if activeConfiguration == nil {
            // If we have configs but none active, activate the first default one if available, otherwise just the first
            if let defaultActive = allConfigs.first(where: { $0.isDefault }) {
                defaultActive.isActive = true
                activeConfiguration = defaultActive
                try? modelContext.save()
            } else if let firstConfig = allConfigs.first {
                firstConfig.isActive = true
                activeConfiguration = firstConfig
                try? modelContext.save()
            }
        }
    }
    
    func switchToConfiguration(_ config: HierarchyConfiguration) {
        // Deactivate current
        activeConfiguration?.isActive = false
        
        // Activate new
        config.isActive = true
        activeConfiguration = config
        
        do {
            try modelContext.save()
            print("✅ Switched to hierarchy: \(config.name)")
        } catch {
            print("❌ Error switching configuration: \(error)")
        }
    }
    
    func canContain(parentLevel: Int, childLevel: Int) -> Bool {
        return activeConfiguration?.canContain(parentLevel: parentLevel, childLevel: childLevel) ?? false
    }
    
    func levelName(for order: Int) -> String {
        return activeConfiguration?.level(at: order)?.name ?? "Level \(order)"
    }
    
    func levelPluralName(for order: Int) -> String {
        return activeConfiguration?.level(at: order)?.pluralName ?? "Level \(order)s"
    }
    
    func levelIcon(for order: Int) -> String {
        return activeConfiguration?.level(at: order)?.icon ?? "square.fill"
    }
    
    func levelColor(for order: Int) -> String {
        return activeConfiguration?.level(at: order)?.color ?? "blue"
    }
    
    func levelColorEnum(for order: Int) -> PlacedShape.ShapeColor? {
        return activeConfiguration?.level(at: order)?.colorEnum
    }
    
    func dimensionUnit(for order: Int) -> String {
        return activeConfiguration?.level(at: order)?.defaultDimensionUnit ?? "in"
    }
    
    func isLargeScale(for order: Int) -> Bool {
        return activeConfiguration?.level(at: order)?.isLargeScale ?? false
    }
    
    func maxLevels() -> Int {
        return activeConfiguration?.maxLevels ?? 5
    }
    
    func isLastLevel(_ level: Int) -> Bool {
        return level >= maxLevels()
    }
    
    func getLevel(at order: Int) -> HierarchyLevel? {
        return activeConfiguration?.level(at: order)
    }
    
    func getAllConfigurations() -> [HierarchyConfiguration] {
        do {
            return try modelContext.fetch(FetchDescriptor<HierarchyConfiguration>())
        } catch {
            print("Error fetching configurations: \(error)")
            return []
        }
    }
    
    func deleteConfiguration(_ config: HierarchyConfiguration) {
        guard !config.isActive else {
            print("Cannot delete active configuration")
            return
        }
        
        modelContext.delete(config)
        try? modelContext.save()
    }
    
    // Public method to access modelContext (needed for MigrationHelper)
    func getModelContext() -> ModelContext {
        return modelContext
    }
    
    // ✅ FAIL-SAFE INITIALIZATION HELPER
    static func safeInitialize(modelContext: ModelContext) -> HierarchyManager {
        let manager = HierarchyManager(modelContext: modelContext)
        
        // Always ensure defaults exist
        do {
            manager.createDefaultIfNeeded()
            
            // Verify we have at least one configuration
            let configs = manager.getAllConfigurations()
            if configs.isEmpty {
                print("⚠️ No configurations found after createDefaultIfNeeded(), forcing creation")
                // Force create at least one default
                let emergency = HierarchyPresets.createWorkshopHierarchy()
                emergency.isActive = true
                modelContext.insert(emergency)
                try modelContext.save()
                manager.activeConfiguration = emergency
            }
            
            // Ensure we have an active configuration
            if manager.activeConfiguration == nil {
                if let first = configs.first {
                    first.isActive = true
                    manager.activeConfiguration = first
                    try modelContext.save()
                }
            }
            
        } catch {
            print("❌ Error in safe initialization: \(error)")
            // Even if there's an error, return the manager - it has fallbacks
        }
        
        return manager
    }
}

// MARK: - Default Hierarchy Presets
struct HierarchyPresets {
    
    static func createDefaultConfigurations() -> [HierarchyConfiguration] {
        return [
            createWorkshopHierarchy(),
            createHomeHierarchy(),
            createWarehouseHierarchy(),
            createSimpleHierarchy(),
            createOfficeHierarchy()
        ]
    }
    
    // Original 5-level workshop hierarchy
    static func createWorkshopHierarchy() -> HierarchyConfiguration {
        let config = HierarchyConfiguration(
            name: "Workshop (5 Levels)",
            maxLevels: 5,
            isDefault: true,
            isActive: true
        )
        
        config.levels = [
            HierarchyLevel(order: 1, name: "Building", pluralName: "Buildings", icon: "building.2.fill", color: "blue", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 2, name: "Room", pluralName: "Rooms", icon: "rectangle.fill", color: "green", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 3, name: "Storage Area", pluralName: "Storage Areas", icon: "square.dashed", color: "orange", defaultDimensionUnit: "in"),
            HierarchyLevel(order: 4, name: "Storage Unit", pluralName: "Storage Units", icon: "cabinet.fill", color: "purple", defaultDimensionUnit: "in"),
            HierarchyLevel(order: 5, name: "Storage Detail", pluralName: "Storage Details", icon: "archivebox.fill", color: "red", defaultDimensionUnit: "in")
        ]
        
        return config
    }
    
    // Simple 3-level hierarchy
    static func createSimpleHierarchy() -> HierarchyConfiguration {
        let config = HierarchyConfiguration(
            name: "Simple (3 Levels)",
            maxLevels: 3
        )
        
        config.levels = [
            HierarchyLevel(order: 1, name: "Location", pluralName: "Locations", icon: "house.fill", color: "blue", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 2, name: "Container", pluralName: "Containers", icon: "shippingbox.fill", color: "green", defaultDimensionUnit: "in"),
            HierarchyLevel(order: 3, name: "Section", pluralName: "Sections", icon: "tray.fill", color: "orange", defaultDimensionUnit: "in")
        ]
        
        return config
    }
    
    // Home organization
    static func createHomeHierarchy() -> HierarchyConfiguration {
        let config = HierarchyConfiguration(
            name: "Home Organization (4 Levels)",
            maxLevels: 4
        )
        
        config.levels = [
            HierarchyLevel(order: 1, name: "Home", pluralName: "Homes", icon: "house.fill", color: "blue", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 2, name: "Room", pluralName: "Rooms", icon: "door.left.hand.open", color: "green", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 3, name: "Furniture", pluralName: "Furniture", icon: "bed.double.fill", color: "orange", defaultDimensionUnit: "in"),
            HierarchyLevel(order: 4, name: "Drawer/Shelf", pluralName: "Drawers/Shelves", icon: "tray.2.fill", color: "purple", defaultDimensionUnit: "in")
        ]
        
        return config
    }
    
    // Warehouse/Business
    static func createWarehouseHierarchy() -> HierarchyConfiguration {
        let config = HierarchyConfiguration(
            name: "Warehouse (5 Levels)",
            maxLevels: 5
        )
        
        config.levels = [
            HierarchyLevel(order: 1, name: "Facility", pluralName: "Facilities", icon: "building.2.fill", color: "blue", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 2, name: "Zone", pluralName: "Zones", icon: "square.grid.3x3.fill", color: "green", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 3, name: "Aisle", pluralName: "Aisles", icon: "arrow.left.arrow.right", color: "orange", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 4, name: "Rack", pluralName: "Racks", icon: "square.stack.3d.up.fill", color: "purple", defaultDimensionUnit: "in"),
            HierarchyLevel(order: 5, name: "Bin", pluralName: "Bins", icon: "tray.fill", color: "red", defaultDimensionUnit: "in")
        ]
        
        return config
    }
    
    // Office
    static func createOfficeHierarchy() -> HierarchyConfiguration {
        let config = HierarchyConfiguration(
            name: "Office (3 Levels)",
            maxLevels: 3
        )
        
        config.levels = [
            HierarchyLevel(order: 1, name: "Office", pluralName: "Offices", icon: "building.fill", color: "blue", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 2, name: "Workstation", pluralName: "Workstations", icon: "desktopcomputer", color: "green", defaultDimensionUnit: "ft"),
            HierarchyLevel(order: 3, name: "Storage", pluralName: "Storage", icon: "archivebox.fill", color: "orange", defaultDimensionUnit: "in")
        ]
        
        return config
    }
}
