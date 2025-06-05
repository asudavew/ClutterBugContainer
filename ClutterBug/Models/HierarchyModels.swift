import Foundation
import SwiftData
import SwiftUI

// MARK: - Hierarchy Configuration Model
@Model
final class HierarchyConfiguration {
    @Attribute(.unique) var id: UUID
    var name: String // "Workshop Setup", "Home Organization", etc.
    var maxLevels: Int // 2-6 levels
    var isDefault: Bool
    var isActive: Bool
    var createdDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \HierarchyLevel.configuration)
    var levels: [HierarchyLevel] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        maxLevels: Int,
        isDefault: Bool = false,
        isActive: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.maxLevels = maxLevels
        self.isDefault = isDefault
        self.isActive = isActive
        self.createdDate = createdDate
    }
    
    // Get level by order
    func level(at order: Int) -> HierarchyLevel? {
        return levels.first { $0.order == order }
    }
    
    // Validate hierarchy rules
    func canContain(parentLevel: Int, childLevel: Int) -> Bool {
        guard parentLevel < childLevel && childLevel <= maxLevels else { return false }
        return childLevel == parentLevel + 1 // Only immediate next level
    }
    
    // Get sorted levels
    var sortedLevels: [HierarchyLevel] {
        return levels.sorted { $0.order < $1.order }
    }
}

// MARK: - Hierarchy Level Model
@Model
final class HierarchyLevel {
    @Attribute(.unique) var id: UUID
    var order: Int // 1, 2, 3, etc. (1 = top level)
    var name: String // "Building", "Workshop", "Cabinet", etc.
    var pluralName: String // "Buildings", "Workshops", "Cabinets"
    var icon: String // SF Symbol name
    var color: String // "blue", "green", etc.
    var defaultDimensionUnit: String // "ft" or "in"
    
    var configuration: HierarchyConfiguration?
    
    init(
        id: UUID = UUID(),
        order: Int,
        name: String,
        pluralName: String,
        icon: String,
        color: String,
        defaultDimensionUnit: String = "ft"
    ) {
        self.id = id
        self.order = order
        self.name = name
        self.pluralName = pluralName
        self.icon = icon
        self.color = color
        self.defaultDimensionUnit = defaultDimensionUnit
    }
    
    var isLargeScale: Bool {
        return order <= 2 // First two levels typically use feet
    }
    
    var colorEnum: PlacedShape.ShapeColor? {
        return PlacedShape.ShapeColor(rawValue: color)
    }
    
    var displayName: String {
        return name
    }
    
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
}
