import SwiftUI
import SwiftData

// MARK: - Supporting Components (without ActionButton - it's in UIComponents.swift)

struct QuantityBadge: View {
    let quantity: Int
    
    var body: some View {
        Text("×\(quantity)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue)
            .clipShape(Capsule())
    }
}

struct ConditionBadge: View {
    let condition: String
    
    private var conditionColor: Color {
        switch condition {
        case "New": return .green
        case "Like New": return .mint
        case "Good": return .blue
        case "Fair": return .orange
        case "Poor": return .red
        case "For Parts": return .gray
        default: return .blue
        }
    }
    
    var body: some View {
        Text(condition)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(conditionColor.opacity(0.1))
            .foregroundColor(conditionColor)
            .clipShape(Capsule())
    }
}

struct SKUBadge: View {
    let sku: String
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "barcode")
                .font(.caption2)
            Text(sku)
                .font(.caption2)
        }
        .foregroundColor(.purple)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.purple.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct DimensionsBadge: View {
    let item: Item
    
    private var dimensionsText: String {
        let dimensions = [item.height, item.width, item.length].filter { $0 > 0 }
        guard !dimensions.isEmpty else { return "" }
        
        let formatted = dimensions.map { String(format: "%.1f", $0) }
        return formatted.joined(separator: "×") + "\""
    }
    
    var body: some View {
        if !dimensionsText.isEmpty {
            HStack(spacing: 2) {
                Image(systemName: "ruler.fill")
                    .font(.caption2)
                    .foregroundColor(.purple)
                Text(dimensionsText)
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Main ItemRow Component

struct ItemRow: View {
    let item: Item
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // ✅ ENHANCED: Photo or icon - now shows actual photo if available!
            PhotoOrIcon(
                photoIdentifier: item.photoIdentifier,
                fallbackIcon: "cube.box.fill",
                fallbackColor: Color.gray,
                size: PhotoIconSize.large,  // Slightly larger for items since photos are more important
                cornerRadius: 8,
                borderColor: Color.gray,
                borderWidth: 1.5
            )
            
            // Item info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // ✅ NEW: Photo indicator badge
                    if item.photoIdentifier != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                // Category and quantity
                HStack(spacing: 8) {
                    if !item.category.isEmpty {
                        Text(item.category)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if item.quantity > 1 {
                        QuantityBadge(quantity: item.quantity)
                    }
                }
                
                // Location path
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(item.fullPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // ✅ ENHANCED: Condition, SKU, and dimensions with better styling
                HStack(spacing: 8) {
                    ConditionBadge(condition: item.condition)
                    
                    if let sku = item.sku, !sku.isEmpty {
                        SKUBadge(sku: sku)
                    }
                    
                    // Show dimensions if available
                    if item.height > 0 || item.width > 0 || item.length > 0 {
                        DimensionsBadge(item: item)
                    }
                }
            }
            
            Spacer()
            
            // ✅ ENHANCED: Edit button with better styling
            ActionButton(
                icon: "pencil",
                color: .blue,
                action: onEdit
            )
        }
        .padding(.vertical, 6)
        // ✅ ENHANCED: Better accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Item: \(item.name)")
        .accessibilityValue("Quantity: \(item.quantity), Condition: \(item.condition)")
        .accessibilityHint("Located in \(item.fullPath). Double tap to edit.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Enhanced Item Card View
struct ItemCardView: View {
    let item: Item
    let onEdit: () -> Void
    let onTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ✅ ENHANCED: Photo section - larger display with fallback
            HStack {
                if let photoId = item.photoIdentifier {
                    PhotoDisplay(
                        photoIdentifier: photoId,
                        fallbackIcon: "cube.box.fill",
                        fallbackColor: Color.gray,
                        maxHeight: 120,
                        cornerRadius: 8,
                        showPlaceholder: true
                    )
                    .frame(height: 120)
                } else {
                    PhotoOrIcon(
                        photoIdentifier: String?.none,
                        fallbackIcon: "cube.box.fill",
                        fallbackColor: Color.gray,
                        size: PhotoIconSize.xlarge,
                        cornerRadius: 8
                    )
                }
                
                Spacer()
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if item.quantity > 1 {
                        QuantityBadge(quantity: item.quantity)
                    }
                }
                
                if !item.category.isEmpty {
                    Text(item.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    ConditionBadge(condition: item.condition)
                    
                    if let sku = item.sku, !sku.isEmpty {
                        SKUBadge(sku: sku)
                    }
                    
                    Spacer()
                }
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(item.fullPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Notes if available
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            // Actions
            HStack {
                Button("Edit", systemImage: "pencil") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                DimensionsBadge(item: item)
                
                // ✅ NEW: Photo indicator
                if item.photoIdentifier != nil {
                    HStack(spacing: 2) {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                        Text("Photo")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Grid Item View (for grid layouts)
struct ItemGridCell: View {
    let item: Item
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // ✅ ENHANCED: Photo/Icon with better sizing
            PhotoOrIcon(
                photoIdentifier: item.photoIdentifier,
                fallbackIcon: "cube.box.fill",
                fallbackColor: Color.gray,
                size: PhotoIconSize.large,
                cornerRadius: 6
            )
            
            // Name
            Text(item.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Quantity if > 1
            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            
            // ✅ NEW: Photo indicator for grid
            if item.photoIdentifier != nil {
                Image(systemName: "camera.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .frame(width: 80, height: 110)
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
    } catch {
        fatalError("Failed to create container for preview")
    }
    
    let sampleContainer = Container(name: "Tool Drawer", containerType: "level_5")
    container.mainContext.insert(sampleContainer)
    
    let sampleItem = Item(
        name: "Phillips Screwdriver Set",
        category: "Hand Tools",
        quantity: 3,
        condition: "Good",
        parentContainer: sampleContainer
    )
    sampleItem.notes = "Sizes #1, #2, #3 with magnetic tips"
    sampleItem.sku = "SD-PH-SET-3"
    sampleItem.height = 8.5
    sampleItem.width = 1.2
    sampleItem.length = 0.5
    // ✅ Simulate having a photo
    sampleItem.photoIdentifier = "sample_tool_photo"
    
    return VStack(spacing: 16) {
        // Standard row view
        ItemRow(item: sampleItem) {
            print("Edit tapped")
        }
        
        // Card view
        ItemCardView(item: sampleItem, onEdit: {
            print("Card edit tapped")
        }, onTap: {
            print("Card tapped")
        })
        
        // Grid cell
        HStack {
            ItemGridCell(item: sampleItem) {
                print("Grid item tapped")
            }
            Spacer()
        }
    }
    .padding()
}
