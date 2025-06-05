import SwiftUI
import SwiftData

// MARK: - Hierarchy Breadcrumb Navigation
struct HierarchyBreadcrumbView: View {
    let currentContainer: Container?
    let onContainerSelected: (Container?) -> Void
    
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    private var breadcrumbPath: [Container] {
        currentContainer?.hierarchyPath ?? []
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                BreadcrumbButton(
                    title: "Top Level",
                    icon: "house.fill",
                    isActive: currentContainer == nil,
                    action: {
                        onContainerSelected(nil)
                    }
                )
                
                ForEach(breadcrumbPath, id: \.id) { container in
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        BreadcrumbButton(
                            title: container.name,
                            icon: container.safeDynamicType(using: hierarchyManager).icon,
                            isActive: container.id == currentContainer?.id,
                            action: {
                                onContainerSelected(container)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

struct BreadcrumbButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? Color.blue : Color.clear)
            )
            .foregroundColor(isActive ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
