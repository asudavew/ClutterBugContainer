import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var photoIdentifier: String?
    var height: Double // Measurement in inches
    var width: Double  // Measurement in inches
    var length: Double // Measurement in inches
    var category: String
    var quantity: Int
    var notes: String?
    var sku: String?
    var condition: String

    // NEW: Photo display on map (enhanced from old system)
    var showPhotoOnMap: Bool = false
    var photoMapPosition: String = "floating"  // "corner", "center", "floating", "hidden"
    var photoIconSize: String = "small"        // "small", "medium", "large"

    // UPDATED: Items now belong to ANY Container (not just Room)
    var parentContainer: Container?
    
    // COMPUTED PROPERTIES: Backward compatibility + enhanced functionality
    
    // Get the container this item is directly in
    var containerName: String {
        parentContainer?.name ?? "Unassigned"
    }
    
    // Get the full hierarchy path (NEW FEATURE!)
    var fullPath: String {
        parentContainer?.pathString ?? "Unassigned"
    }
    
    // Get the ultimate building this item is in
    var building: Container? {
        parentContainer?.rootContainer
    }
    
    // Get the room this item is in (walks up hierarchy to find room-level container)
    var room: Container? {
        var current = parentContainer
        while let container = current {
            // Check if this container is at level 2 (typically room level)
            // For dynamic hierarchies, we need to check level number
            if container.levelNumber == 2 {
                return container
            }
            current = container.parentContainer
        }
        return nil
    }
    
    // BACKWARD COMPATIBILITY: For views that still expect roomName
    var roomName: String {
        room?.name ?? "Unknown Room"
    }
    
    // BACKWARD COMPATIBILITY: For views that still expect ultimateBuilding
    var ultimateBuilding: Container? {
        building
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        photoIdentifier: String? = nil,
        height: Double = 0.0,
        width: Double = 0.0,
        length: Double = 0.0,
        category: String = "",
        quantity: Int = 1,
        notes: String? = nil,
        sku: String? = nil,
        condition: String = "Used",
        parentContainer: Container  // CHANGED: Now takes Container instead of Room
    ) {
        self.id = id
        self.name = name
        self.photoIdentifier = photoIdentifier
        self.height = height
        self.width = width
        self.length = length
        self.category = category
        self.quantity = quantity
        self.notes = notes
        self.sku = sku
        self.condition = condition
        self.parentContainer = parentContainer
    }
}

// MARK: - Item Extensions for Enhanced Functionality

extension Item {
    // Get all containers in the hierarchy path
    var hierarchyContainers: [Container] {
        parentContainer?.hierarchyPath ?? []
    }
    
    // Check if item is in a specific level of container (using level numbers)
    func isInLevel(_ levelNumber: Int) -> Bool {
        var current = parentContainer
        while let container = current {
            if container.levelNumber == levelNumber {
                return true
            }
            current = container.parentContainer
        }
        return false
    }
    
    // Get the nearest container of a specific level
    func nearestContainer(atLevel levelNumber: Int) -> Container? {
        var current = parentContainer
        while let container = current {
            if container.levelNumber == levelNumber {
                return container
            }
            current = container.parentContainer
        }
        return nil
    }
    
    // Check if item is in a container with a specific name pattern
    func isIn(containerWithName name: String) -> Bool {
        var current = parentContainer
        while let container = current {
            if container.name.localizedCaseInsensitiveContains(name) {
                return true
            }
            current = container.parentContainer
        }
        return false
    }
    
    // Photo icon properties with type safety
    var photoMapPositionEnum: PhotoMapPosition {
        PhotoMapPosition(rawValue: photoMapPosition) ?? .floating
    }
    
    var photoIconSizeEnum: PhotoIconSize {
        PhotoIconSize(rawValue: photoIconSize) ?? .small
    }
}

// MARK: - Photo Position Types (for photo icons on maps)
enum PhotoMapPosition: String, CaseIterable {
    case corner = "corner"
    case center = "center"
    case floating = "floating"
    case hidden = "hidden"
    
    var displayName: String {
        switch self {
        case .corner: return "Corner"
        case .center: return "Center"
        case .floating: return "Floating"
        case .hidden: return "Hidden"
        }
    }
}
