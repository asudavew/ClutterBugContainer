import SwiftUI

// MARK: - Stats Badge Component
struct StatsBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Photo Icon Size Extension
extension PhotoIconSize {
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xlarge: return "Extra Large"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        // Stats Badge examples
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats Badges:")
                .font(.headline)
            
            HStack(spacing: 8) {
                StatsBadge(
                    count: 5,
                    label: "containers",
                    color: .green,
                    icon: "square.stack.3d.up"
                )
                
                StatsBadge(
                    count: 23,
                    label: "items",
                    color: .blue,
                    icon: "cube.box"
                )
            }
        }
        
        Divider()
        
        // Action Button examples
        VStack(alignment: .leading, spacing: 8) {
            Text("Action Buttons:")
                .font(.headline)
            
            HStack(spacing: 12) {
                ActionButton(
                    icon: "pencil",
                    color: .blue,
                    action: { print("Edit tapped") }
                )
                
                ActionButton(
                    icon: "trash",
                    color: .red,
                    action: { print("Delete tapped") }
                )
                
                ActionButton(
                    icon: "plus",
                    color: .green,
                    action: { print("Add tapped") }
                )
            }
        }
        
        Spacer()
    }
    .padding()
}
