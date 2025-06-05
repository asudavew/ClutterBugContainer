import Foundation
import SwiftData
import SwiftUI

// MARK: - Container Model (Dynamic Hierarchy Support)
@Model
final class Container {
    @Attribute(.unique) var id: UUID
    var name: String
    var containerType: String  // Now stores "level_X" (e.g., "level_1", "level_2")
    var purpose: String?
    var notes: String?
    
    // Physical dimensions (in feet for large containers, inches for smaller containers)
    var width: Double = 0.0
    var length: Double = 0.0
    var height: Double = 0.0
    var side3: Double?     // For triangles and complex shapes
    var side4: Double?     // For quadrilaterals and T-shapes
    
    // Visual/Map Properties
    var mapX: Double?          // X position on parent's map
    var mapY: Double?          // Y position on parent's map
    var mapWidth: Double?      // Visual width on map
    var mapHeight: Double?     // Visual height on map
    var rotation: Double?      // Rotation in degrees (0-360)
    var shapeType: String?     // "rectangle", "circle", "triangle", "quadrilateral", "tee"
    var colorType: String?     // "blue", "red", "green", "orange", "purple"
    var mapLabel: String?      // Custom label for map display
    
    // Photo Properties
    var photoIdentifier: String?        // Main photo of the container
    var showPhotoOnMap: Bool = false     // Show photo as icon on parent's map
    var photoMapPosition: String = "corner"  // "corner", "center", "floating"
    var photoIconSize: String = "small"     // "small", "medium", "large"
    
    // Hierarchy relationships (DYNAMIC level enforcement)
    var parentContainer: Container?
    @Relationship(deleteRule: .cascade, inverse: \Container.parentContainer)
    var childContainers: [Container]? = []
    
    // Items stored directly in this container (ONLY for final level)
    @Relationship(deleteRule: .cascade, inverse: \Item.parentContainer)
    var items: [Item]? = []
    
    // MARK: - Computed Properties
    
    var shapeTypeEnum: PlacedShape.ShapeType? {
        guard let shapeType = shapeType else { return .rectangle }
        return PlacedShape.ShapeType(rawValue: shapeType) ?? .rectangle
    }
    
    var colorTypeEnum: PlacedShape.ShapeColor? {
        guard let colorType = colorType else { return .blue }
        return PlacedShape.ShapeColor(rawValue: colorType) ?? .blue
    }
    
    // Get ALL items in this container and all child containers (recursive)
    var allItems: [Item] {
        var result = items ?? []
        for child in childContainers ?? [] {
            result.append(contentsOf: child.allItems)
        }
        return result
    }
    
    var totalItemCount: Int {
        allItems.count
    }
    
    var directItemCount: Int {
        items?.count ?? 0
    }
    
    // Get the full hierarchy path (like "Workshop → Main Room → Tool Area → Cabinet A → Top Shelf")
    var hierarchyPath: [Container] {
        var path: [Container] = []
        var current: Container? = self
        while let container = current {
            path.insert(container, at: 0)
            current = container.parentContainer
        }
        return path
    }
    
    var pathString: String {
        hierarchyPath.map { $0.name }.joined(separator: " → ")
    }
    
    var level: Int {
        var count = 0
        var current = parentContainer
        while current != nil {
            count += 1
            current = current?.parentContainer
        }
        return count
    }
    
    var rootContainer: Container {
        var current = self
        while let parent = current.parentContainer {
            current = parent
        }
        return current
    }
    
    // Shape and dimension properties (compatible with PlacedShape system)
    var dimensionType: PlacedShape.DimensionType {
        guard let type = shapeTypeEnum else { return .rectangular }
        switch type {
        case .circle: return .diameter
        case .rectangle: return .rectangular
        case .triangle: return .triangular
        case .quadrilateral: return .fourSided
        case .tee: return .teeShape
        }
    }
    
    var allSides: [Double] {
        switch dimensionType {
        case .fourSided:
            return [length, width, side3 ?? length, side4 ?? width]
        case .triangular:
            return [length, width, side3 ?? 5.0]
        case .teeShape:
            return [length, width, side3 ?? 4.0, side4 ?? 2.0]
        case .diameter, .rectangular:
            return [length, width]
        }
    }
    
    var canRotate: Bool {
        return shapeTypeEnum?.canRotate ?? true
    }
    
    // MARK: - Dynamic Hierarchy Methods
    
    // Get level number from containerType (e.g., "level_3" returns 3)
    var levelNumber: Int {
        if containerType.hasPrefix("level_") {
            let levelString = String(containerType.dropFirst(6)) // Remove "level_"
            return Int(levelString) ?? (level + 1)
        }
        // Fallback for legacy types
        switch containerType {
        case "building": return 1
        case "room": return 2
        case "storage_area": return 3
        case "storage_unit": return 4
        case "storage_detail": return 5
        default: return level + 1
        }
    }
    
    // ✅ SAFE dynamic type access with fallback
    func safeDynamicType(using hierarchyManager: HierarchyManager?) -> DynamicContainerType {
        guard let hierarchyManager = hierarchyManager else {
            // Fallback to legacy system if hierarchy manager is nil
            return legacyDynamicType()
        }
        
        guard let levelConfig = hierarchyManager.getLevel(at: levelNumber) else {
            print("⚠️ No level configuration found for level \(levelNumber), using fallback")
            return legacyDynamicType()
        }
        
        return DynamicContainerType(
            level: levelNumber,
            name: levelConfig.name,
            pluralName: levelConfig.pluralName,
            icon: levelConfig.icon,
            color: levelConfig.color,
            isLargeScale: levelConfig.isLargeScale,
            canContainItems: hierarchyManager.isLastLevel(levelNumber)
        )
    }
    
    // ✅ LEGACY fallback for when hierarchy manager is unavailable
    private func legacyDynamicType() -> DynamicContainerType {
        let legacyTypes = [
            DynamicContainerType(level: 1, name: "Building", pluralName: "Buildings", icon: "building.2.fill", color: "blue", isLargeScale: true, canContainItems: false),
            DynamicContainerType(level: 2, name: "Room", pluralName: "Rooms", icon: "rectangle.fill", color: "green", isLargeScale: true, canContainItems: false),
            DynamicContainerType(level: 3, name: "Storage Area", pluralName: "Storage Areas", icon: "square.dashed", color: "orange", isLargeScale: false, canContainItems: false),
            DynamicContainerType(level: 4, name: "Storage Unit", pluralName: "Storage Units", icon: "cabinet.fill", color: "purple", isLargeScale: false, canContainItems: false),
            DynamicContainerType(level: 5, name: "Storage Detail", pluralName: "Storage Details", icon: "archivebox.fill", color: "red", isLargeScale: false, canContainItems: true)
        ]
        
        let index = min(levelNumber - 1, legacyTypes.count - 1)
        return legacyTypes[max(0, index)]
    }
    
    // ✅ SAFE measurement text with fallback
    func safeMeasurementText(using hierarchyManager: HierarchyManager?) -> String {
        guard let hierarchyManager = hierarchyManager else {
            return measurementText // Use legacy version
        }
        return measurementText(using: hierarchyManager)
    }
    
    // ✅ SAFE container validation
    func canSafelyContainItems(using hierarchyManager: HierarchyManager?) -> Bool {
        guard let hierarchyManager = hierarchyManager else {
            return canContainItems // Use legacy version
        }
        return canContainItems(using: hierarchyManager)
    }
    
    // Get measurement text using hierarchy manager
    func measurementText(using hierarchyManager: HierarchyManager) -> String {
        let unit = hierarchyManager.isLargeScale(for: levelNumber) ? "ft" : "in"
        
        switch dimensionType {
        case .diameter:
            return "○ \(Int(width))\(unit) ⌀"
        case .rectangular:
            return "▭ \(Int(length))\(unit) × \(Int(width))\(unit)"
        case .triangular:
            let sides = allSides
            return "△ \(Int(sides[0]))\(unit), \(Int(sides[1]))\(unit), \(Int(sides[2]))\(unit)"
        case .fourSided:
            let sides = allSides
            return "◇ \(Int(sides[0]))\(unit), \(Int(sides[1]))\(unit), \(Int(sides[2]))\(unit), \(Int(sides[3]))\(unit)"
        case .teeShape:
            let measurements = allSides
            return "⊤ \(Int(measurements[0]))\(unit) × \(Int(measurements[1]))\(unit)"
        }
    }
    
    // Fallback measurement text without hierarchy manager
    var measurementText: String {
        let unit = levelNumber <= 2 ? "ft" : "in"
        
        switch dimensionType {
        case .diameter:
            return "○ \(Int(width))\(unit) ⌀"
        case .rectangular:
            return "▭ \(Int(length))\(unit) × \(Int(width))\(unit)"
        case .triangular:
            let sides = allSides
            return "△ \(Int(sides[0]))\(unit), \(Int(sides[1]))\(unit), \(Int(sides[2]))\(unit)"
        case .fourSided:
            let sides = allSides
            return "◇ \(Int(sides[0]))\(unit), \(Int(sides[1]))\(unit), \(Int(sides[2]))\(unit), \(Int(sides[3]))\(unit)"
        case .teeShape:
            let measurements = allSides
            return "⊤ \(Int(measurements[0]))\(unit) × \(Int(measurements[1]))\(unit)"
        }
    }
    
    // Dynamic hierarchy validation
    func canContainItems(using hierarchyManager: HierarchyManager) -> Bool {
        return hierarchyManager.isLastLevel(levelNumber)
    }
    
    // Legacy support for existing code
    var canContainItems: Bool {
        // For backward compatibility, assume 5 levels max
        return levelNumber >= 5
    }
    
    func hierarchyLevel(using hierarchyManager: HierarchyManager) -> String {
        let levelName = hierarchyManager.levelName(for: levelNumber)
        return "\(levelName) (Level \(levelNumber))"
    }
    
    // Legacy support
    var hierarchyLevel: String {
        switch levelNumber {
        case 1: return "Building (Level 1)"
        case 2: return "Room (Level 2)"
        case 3: return "Storage Area (Level 3)"
        case 4: return "Storage Unit (Level 4)"
        case 5: return "Storage Detail (Level 5)"
        default: return "Level \(levelNumber)"
        }
    }
    
    // Dynamic type information using hierarchy manager
    func dynamicType(using hierarchyManager: HierarchyManager) -> DynamicContainerType {
        return DynamicContainerType(
            level: levelNumber,
            name: hierarchyManager.levelName(for: levelNumber),
            pluralName: hierarchyManager.levelPluralName(for: levelNumber),
            icon: hierarchyManager.levelIcon(for: levelNumber),
            color: hierarchyManager.levelColor(for: levelNumber),
            isLargeScale: hierarchyManager.isLargeScale(for: levelNumber),
            canContainItems: hierarchyManager.isLastLevel(levelNumber)
        )
    }
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        containerType: String,
        purpose: String? = nil,
        notes: String? = nil,
        width: Double = 0.0,
        length: Double = 0.0,
        height: Double = 0.0,
        side3: Double? = nil,
        side4: Double? = nil,
        mapX: Double? = nil,
        mapY: Double? = nil,
        mapWidth: Double? = nil,
        mapHeight: Double? = nil,
        rotation: Double? = 0.0,
        shapeType: String? = "rectangle",
        colorType: String? = "blue",
        parentContainer: Container? = nil
    ) {
        self.id = id
        self.name = name
        self.containerType = containerType
        self.purpose = purpose
        self.notes = notes
        self.width = width
        self.length = length
        self.height = height
        self.side3 = side3
        self.side4 = side4
        self.mapX = mapX
        self.mapY = mapY
        self.mapWidth = mapWidth
        self.mapHeight = mapHeight
        self.rotation = rotation
        self.shapeType = shapeType
        self.colorType = colorType
        self.mapLabel = name
        self.parentContainer = parentContainer
    }
}

// MARK: - Dynamic Container Type
struct DynamicContainerType {
    let level: Int
    let name: String
    let pluralName: String
    let icon: String
    let color: String
    let isLargeScale: Bool
    let canContainItems: Bool
    
    var displayName: String { name }
    var shortName: String {
        switch name.lowercased() {
        case "building": return "BLDG"
        case "room": return "ROOM"
        case "storage area", "area": return "AREA"
        case "storage unit", "unit": return "UNIT"
        case "storage detail", "detail", "shelf": return "SHELF"
        default: return String(name.prefix(4)).uppercased()
        }
    }
    
    var colorEnum: PlacedShape.ShapeColor? {
        PlacedShape.ShapeColor(rawValue: color)
    }
}

// MARK: - Legacy ContainerType Support
enum ContainerType: String, CaseIterable, Identifiable {
    case building = "building"
    case room = "room"
    case storageArea = "storage_area"
    case storageUnit = "storage_unit"
    case storageDetail = "storage_detail"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .building: return "Building"
        case .room: return "Room"
        case .storageArea: return "Storage Area"
        case .storageUnit: return "Storage Unit"
        case .storageDetail: return "Storage Detail"
        }
    }
    
    var icon: String {
        switch self {
        case .building: return "building.2.fill"
        case .room: return "rectangle.fill"
        case .storageArea: return "square.dashed"
        case .storageUnit: return "cabinet.fill"
        case .storageDetail: return "archivebox.fill"
        }
    }
    
    var hierarchyLevel: Int {
        switch self {
        case .building: return 1
        case .room: return 2
        case .storageArea: return 3
        case .storageUnit: return 4
        case .storageDetail: return 5
        }
    }
}

// MARK: - Dynamic Container Factory Methods
extension Container {
    
    // Create container using dynamic hierarchy
    static func createDynamic(
        name: String,
        level: Int,
        parentContainer: Container?,
        hierarchyManager: HierarchyManager,
        mapX: Double? = nil,
        mapY: Double? = nil
    ) -> Container? {
        
        // Validate hierarchy rules
        if let parent = parentContainer {
            let parentLevel = parent.levelNumber
            guard hierarchyManager.canContain(parentLevel: parentLevel, childLevel: level) else {
                print("❌ HIERARCHY ERROR: Level \(parentLevel) cannot contain Level \(level)")
                return nil
            }
        } else if level != 1 {
            print("❌ HIERARCHY ERROR: Only Level 1 containers can be at root")
            return nil
        }
        
        // Get level configuration
        guard let levelConfig = hierarchyManager.getLevel(at: level) else {
            print("❌ No configuration found for level \(level)")
            return nil
        }
        
        // Calculate default dimensions
        let defaultWidth = levelConfig.isLargeScale ? 10.0 : 12.0
        let defaultLength = levelConfig.isLargeScale ? 12.0 : 8.0
        let defaultHeight = levelConfig.isLargeScale ? 9.0 : 6.0
        
        // Calculate default position
        let position = calculateDefaultPosition(
            for: level,
            in: parentContainer,
            mapX: mapX,
            mapY: mapY
        )
        
        let container = Container(
            name: name,
            containerType: "level_\(level)",
            width: defaultWidth,
            length: defaultLength,
            height: defaultHeight,
            mapX: position.x,
            mapY: position.y,
            mapWidth: 100.0,
            mapHeight: 80.0,
            shapeType: "rectangle",
            colorType: levelConfig.color,
            parentContainer: parentContainer
        )
        
        print("✅ Created \(levelConfig.name): '\(name)' at Level \(level)")
        if let parent = parentContainer {
            print("   Parent: \(parent.name)")
        }
        
        return container
    }
    
    // Create legacy building (for backward compatibility)
    static func createBuilding(
        name: String,
        width: Double = 30.0,
        length: Double = 40.0,
        mapX: Double = 150.0,
        mapY: Double = 200.0
    ) -> Container {
        return Container(
            name: name,
            containerType: "level_1", // Updated to use new format
            width: width,
            length: length,
            height: 12.0,
            mapX: mapX,
            mapY: mapY,
            mapWidth: 200.0,
            mapHeight: 150.0,
            shapeType: "rectangle",
            colorType: "blue"
        )
    }
    
    // Legacy create method (updated to use dynamic system)
    static func create(
        name: String,
        type: ContainerType,
        in parent: Container,
        at position: CGPoint? = nil
    ) -> Container? {
        // Convert legacy type to level number
        let level = type.hierarchyLevel
        
        // Use dynamic creation (requires hierarchy manager, but we'll use defaults)
        let container = Container(
            name: name,
            containerType: "level_\(level)",
            width: type == .building || type == .room ? 10.0 : 12.0,
            length: type == .building || type == .room ? 12.0 : 8.0,
            height: type == .building || type == .room ? 9.0 : 6.0,
            mapX: position?.x ?? 100.0,
            mapY: position?.y ?? 100.0,
            shapeType: "rectangle",
            colorType: type == .building ? "blue" : "green",
            parentContainer: parent
        )
        
        return container
    }
    
    private static func calculateDefaultPosition(
        for level: Int,
        in parent: Container?,
        mapX: Double? = nil,
        mapY: Double? = nil
    ) -> CGPoint {
        
        if let x = mapX, let y = mapY {
            return CGPoint(x: x, y: y)
        }
        
        // Default positioning based on parent and existing siblings
        let parentX = parent?.mapX ?? 150.0
        let parentY = parent?.mapY ?? 200.0
        let spacing: Double = 50.0
        
        let existingContainers = parent?.childContainers ?? []
        let siblingCount = existingContainers.count
        
        // Simple grid layout
        let columns = 3
        let row = siblingCount / columns
        let col = siblingCount % columns
        
        let x = parentX + Double(col) * spacing
        let y = parentY + Double(row) * spacing + spacing
        
        return CGPoint(x: x, y: y)
    }
}
