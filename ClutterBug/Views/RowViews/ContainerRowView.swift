import SwiftUI
import SwiftData

struct ContainerRowView: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // ✅ ENHANCED: Container icon - now shows photo if available!
            PhotoOrIcon(
                photoIdentifier: container.photoIdentifier,
                fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
                fallbackColor: container.colorTypeEnum?.color ?? .blue,
                size: .medium,
                cornerRadius: 8,
                borderColor: container.colorTypeEnum?.color ?? .blue,
                borderWidth: 1.5
            )
            
            // Container info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(container.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // ✅ NEW: Photo indicator badge
                    if container.photoIdentifier != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                
                Text(container.safeDynamicType(using: hierarchyManager).displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                let measurementText = container.safeMeasurementText(using: hierarchyManager)
                if !measurementText.isEmpty {
                    Text(measurementText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // ✅ ENHANCED: Stats with better styling
                HStack(spacing: 8) {
                    if let childCount = container.childContainers?.count, childCount > 0 {
                        StatsBadge(
                            count: childCount,
                            label: childCount == 1 ? "container" : "containers",
                            color: .green,
                            icon: "square.stack.3d.up"
                        )
                    }
                    
                    if container.totalItemCount > 0 {
                        StatsBadge(
                            count: container.totalItemCount,
                            label: container.totalItemCount == 1 ? "item" : "items",
                            color: .blue,
                            icon: "cube.box"
                        )
                    }
                }
            }
            
            Spacer()
            
            // ✅ ENHANCED: Action buttons with better styling
            HStack(spacing: 8) {
                ActionButton(
                    icon: "pencil",
                    color: .blue,
                    action: onEdit
                )
                
                ActionButton(
                    icon: "trash",
                    color: .red,
                    action: onDelete
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            print("🔥 Tapped container: \(container.name)")
            onTap()
        }
        // ✅ ENHANCED: Better accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(container.safeDynamicType(using: hierarchyManager).displayName): \(container.name)")
        .accessibilityHint("Contains \(container.totalItemCount) items. Double tap to open.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Enhanced Container Row with Animation (Optional)
struct AnimatedContainerRowView: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        ContainerRowView(
            container: container,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
        .environmentObject(hierarchyManager)
    }
}

// MARK: - Container Card View (Alternative Layout)
struct ContainerCardView: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ✅ ENHANCED: Header with larger photo/icon
            HStack {
                PhotoOrIcon(
                    photoIdentifier: container.photoIdentifier,
                    fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
                    fallbackColor: container.colorTypeEnum?.color ?? .blue,
                    size: .large,
                    cornerRadius: 12,
                    borderColor: container.colorTypeEnum?.color ?? .blue,
                    borderWidth: 2.0
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(container.name)
                            .font(.headline)
                            .lineLimit(2)
                        
                        if container.photoIdentifier != nil {
                            Image(systemName: "camera.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(container.safeDynamicType(using: hierarchyManager).displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu("Actions", systemImage: "ellipsis") {
                    Button("Edit", systemImage: "pencil") { onEdit() }
                    Button("Delete", systemImage: "trash", role: .destructive) { onDelete() }
                }
                .foregroundColor(.secondary)
            }
            
            // Purpose if available
            if let purpose = container.purpose, !purpose.isEmpty {
                Text(purpose)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // ✅ ENHANCED: Stats with icons
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(container.childContainers?.count ?? 0)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "cube.box")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(container.totalItemCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Measurements
                let measurements = container.safeMeasurementText(using: hierarchyManager)
                if !measurements.isEmpty {
                    Text(measurements)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Safe Container Row View (Alternative with Optional HierarchyManager)
struct SafeContainerRowView: View {
    let container: Container
    let hierarchyManager: HierarchyManager? // Optional to handle missing environment
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // ✅ ENHANCED: Container icon with photo support
            PhotoOrIcon(
                photoIdentifier: container.photoIdentifier,
                fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
                fallbackColor: container.colorTypeEnum?.color ?? .blue,
                size: .medium,
                cornerRadius: 8,
                borderColor: container.colorTypeEnum?.color ?? .blue,
                borderWidth: 1.5
            )
            
            // Container info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(container.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if container.photoIdentifier != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                
                Text(container.safeDynamicType(using: hierarchyManager).displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                let measurementText = container.safeMeasurementText(using: hierarchyManager)
                if !measurementText.isEmpty {
                    Text(measurementText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Stats
                HStack(spacing: 8) {
                    if let childCount = container.childContainers?.count, childCount > 0 {
                        StatsBadge(
                            count: childCount,
                            label: childCount == 1 ? "container" : "containers",
                            color: .green,
                            icon: "square.stack.3d.up"
                        )
                    }
                    
                    if container.totalItemCount > 0 {
                        StatsBadge(
                            count: container.totalItemCount,
                            label: container.totalItemCount == 1 ? "item" : "items",
                            color: .blue,
                            icon: "cube.box"
                        )
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                ActionButton(
                    icon: "pencil",
                    color: .blue,
                    action: onEdit
                )
                
                ActionButton(
                    icon: "trash",
                    color: .red,
                    action: onDelete
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            print("🔥 Tapped container: \(container.name)")
            onTap()
        }
    }
}

// MARK: - Preview Provider
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
    } catch {
        fatalError("Failed to create container for preview: \(error.localizedDescription)")
    }

    let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
    hierarchyManager.createDefaultIfNeeded()

    let dummyContainer = Container(
        name: "My Workshop",
        containerType: "level_2",
        purpose: "Tools and projects",
        mapX: 0, mapY: 0
    )
    // ✅ Simulate having a photo
    dummyContainer.photoIdentifier = "sample_photo_123"

    return VStack(spacing: 16) {
        // Row style
        ContainerRowView(
            container: dummyContainer,
            onTap: { print("Tapped!") },
            onEdit: { print("Edit!") },
            onDelete: { print("Delete!") }
        )
        .environmentObject(hierarchyManager)
        
        // Card style
        ContainerCardView(
            container: dummyContainer,
            onTap: { print("Tapped!") },
            onEdit: { print("Edit!") },
            onDelete: { print("Delete!") }
        )
        .environmentObject(hierarchyManager)
    }
    .padding()
}
