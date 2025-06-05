//v8 - Added T-shape support with proper dimensionType enum - FIXED 4-sided icon
import SwiftUI
import Foundation

// MARK: - PlacedShape Model
struct PlacedShape: Identifiable, Codable {
    let id: UUID
    var type: ShapeType
    var position: CGPoint  // Center position in map coordinates
    var width: Double      // Actual width in feet (or side2 for 4-sided shapes)
    var length: Double     // Actual length in feet (or side1 for 4-sided shapes)
    var side3: Double?     // Third side for triangles and 4-sided shapes
    var side4: Double?     // Fourth side for 4-sided shapes
    var rotation: Double   // Rotation in degrees (0-360)
    var label: String
    var colorType: ShapeColor
    
    // Computed properties
    var color: Color {
        colorType.color
    }
    
    // Dimension system
    var dimensionType: DimensionType {
        switch type {
        case .circle: return .diameter
        case .rectangle: return .rectangular  // Simple rectangle: length × width
        case .triangle: return .triangular
        case .quadrilateral: return .fourSided  // True 4-sided with all sides
        case .tee: return .teeShape  // T-shape with 4 key measurements
        }
    }
    
    var dimensionLabels: [String] {
        switch dimensionType {
        case .diameter: return ["Diameter (ft)"]
        case .rectangular: return ["Length (ft)", "Width (ft)"]
        case .triangular: return ["Side 1 (ft)", "Side 2 (ft)", "Side 3 (ft)"]
        case .fourSided:
            return ["Top (ft)", "Right (ft)", "Bottom (ft)", "Left (ft)"]
        case .teeShape:
            return ["Total Width (ft)", "Total Height (ft)", "Stem Width (ft)", "Top Height (ft)"]
        }
    }
    
    // Get all measurements for different shape types
    var allSides: [Double] {
        switch dimensionType {
        case .fourSided:
            return [length, width, side3 ?? length, side4 ?? width]
        case .triangular:
            return [length, width, side3 ?? 5.0]
        case .teeShape:
            return [length, width, side3 ?? 4.0, side4 ?? 2.0] // totalWidth, totalHeight, stemWidth, topHeight
        case .diameter, .rectangular:
            return [length, width]
        }
    }
    
    // Display text for measurements
    var measurementText: String {
        switch dimensionType {
        case .diameter:
            return "○ \(Int(width))ft ⌀"  // ○ = thin circle symbol, ⌀ = diameter symbol
        case .rectangular:
            return "▭ \(Int(length))ft × \(Int(width))ft"  // ▭ = rectangle symbol
        case .triangular:
            let sides = allSides
            return "△ \(Int(sides[0]))', \(Int(sides[1]))', \(Int(sides[2]))'"  // △ = triangle symbol
        case .fourSided:
            let sides = allSides
            return "◇ \(Int(sides[0]))', \(Int(sides[1]))', \(Int(sides[2]))', \(Int(sides[3]))'"  // ◇ = diamond symbol (4-sided)
        case .teeShape:
            let measurements = allSides
            return "⊤ \(Int(measurements[0]))' × \(Int(measurements[1]))' (stem:\(Int(measurements[2]))', top:\(Int(measurements[3]))')"  // ⊤ = T-shape symbol
        }
    }
    
    var rotationText: String {
        return rotation == 0 ? "" : " ∠\(Int(rotation))°"
    }
    
    // Dynamic display name based on shape type
    var actualDisplayName: String {
        switch type {
        case .circle:
            return "Circle"
        case .triangle:
            return "Triangle"
        case .quadrilateral:
            return "Quadrilateral"
        case .tee:
            return "T-Shape"
        case .rectangle:
            // Check if it's actually square
            if abs(length - width) < 0.1 {
                return "Square"
            } else {
                return "Rectangle"
            }
        }
    }
    
    init(id: UUID = UUID(), type: ShapeType, position: CGPoint, width: Double, length: Double, side3: Double? = nil, side4: Double? = nil, rotation: Double = 0, label: String, colorType: ShapeColor) {
        self.id = id
        self.type = type
        self.position = position
        self.width = width
        self.length = length
        self.side3 = side3
        self.side4 = side4
        self.rotation = rotation
        self.label = label
        self.colorType = colorType
    }
}

// MARK: - Dimension Type
extension PlacedShape {
    enum DimensionType: Codable {
        case diameter     // Circle: just diameter
        case rectangular  // Rectangle: length × width
        case triangular   // Triangle: side1, side2, side3
        case fourSided    // Quadrilateral: all 4 sides
        case teeShape     // T-shape: total width, total height, stem width, top height
    }
}

// MARK: - Shape Type
extension PlacedShape {
    enum ShapeType: String, CaseIterable, Codable {
        case rectangle = "rectangle"
        case circle = "circle"
        case triangle = "triangle"
        case quadrilateral = "quadrilateral"
        case tee = "tee"
        
        var icon: String {
            switch self {
            case .rectangle: return "rectangle.fill"  // Valid SF Symbol
            case .circle: return "circle.fill"        // Valid SF Symbol
            case .triangle: return "triangle.fill"    // Valid SF Symbol
            case .quadrilateral: return "rhombus.fill"  // Solid diamond icon to match other filled icons
            case .tee: return "t.square"  // T-shape icon
            }
        }
        
        var defaultWidth: Double {
            switch self {
            case .circle: return 8.0      // 8 foot diameter circle
            case .rectangle, .triangle: return 4.0  // 4 feet width
            case .quadrilateral: return 5.0  // 5 feet width
            case .tee: return 8.0  // 8 feet total height
            }
        }
        
        var defaultLength: Double {
            switch self {
            case .circle: return 8.0      // Not used, but set same as width
            case .rectangle, .triangle: return 6.0  // 6 feet length
            case .quadrilateral: return 7.0  // 7 feet length
            case .tee: return 12.0  // 12 feet total width
            }
        }
        
        var defaultSide3: Double? {
            switch self {
            case .triangle: return 5.0    // 5 feet for third side
            case .quadrilateral: return 6.0  // 6 feet for third side
            case .tee: return 4.0  // 4 feet stem width
            default: return nil
            }
        }
        
        var defaultSide4: Double? {
            switch self {
            case .quadrilateral: return 4.0  // 4 feet for fourth side
            case .tee: return 3.0  // 3 feet top height
            default: return nil
            }
        }
        
        var defaultRotation: Double {
            return 0.0  // All shapes start unrotated
        }
        
        var displayName: String {
            switch self {
            case .quadrilateral: return "Quad"
            case .tee: return "Tee"
            default: return rawValue.capitalized
            }
        }
        
        var canRotate: Bool {
            switch self {
            case .circle: return false  // Circles don't need rotation
            case .rectangle, .triangle, .quadrilateral, .tee: return true
            }
        }
        
        var dimensionLabel: String {
            switch self {
            case .circle: return "Diameter (ft)"
            case .rectangle: return "Length × Width (ft)"
            case .quadrilateral: return "Four Sides (ft)"
            case .triangle: return "Three Sides (ft)"
            case .tee: return "T-Shape Dimensions (ft)"
            }
        }
    }
}

// MARK: - Shape Color
extension PlacedShape {
    enum ShapeColor: String, CaseIterable, Codable {
        case blue = "blue"
        case red = "red"
        case green = "green"
        case orange = "orange"
        case purple = "purple"
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .red: return .red
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            }
        }
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}

// MARK: - Shape Factory
extension PlacedShape {
    static func create(type: ShapeType, at position: CGPoint) -> PlacedShape {
        return PlacedShape(
            type: type,
            position: position,
            width: type.defaultWidth,
            length: type.defaultLength,
            side3: type.defaultSide3,
            side4: type.defaultSide4,
            rotation: type.defaultRotation,
            label: "New \(type.displayName)",
            colorType: .blue
        )
    }
}
