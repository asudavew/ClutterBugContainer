import SwiftUI
import SwiftData

struct HierarchyPreviewView: View {
    let hierarchyName: String
    let levels: [CustomLevel]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("Your Custom Style: \(hierarchyName)") {
                ForEach(levels.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: levels[index].icon)
                            .foregroundColor(levels[index].colorEnum?.color ?? .gray)
                            .font(.title2)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level \(index + 1): \(levels[index].name)")
                                .font(.headline)
                            
                            Text("Dimensions in \(levels[index].dimensionUnit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if index == levels.count - 1 {
                                Text("📦 Items will be stored here")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Example Structure") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(levels.indices, id: \.self) { index in
                        HStack {
                            ForEach(0..<index, id: \.self) { _ in
                                Text("  ")
                            }
                            
                            Text("• Example \(levels[index].name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        ForEach(0..<levels.count, id: \.self) { _ in
                            Text("  ")
                        }
                        Text("• Your Item")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("How It Works") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Each level can only contain the next level down")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text("Items go in the final level: \(levels.last?.name ?? "Last Level")")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(.orange)
                        Text("Large levels use feet, small levels use inches")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.purple)
                        Text("Each level has its own color and icon")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    let sampleLevels = [
        CustomLevel(name: "Workshop", icon: "building.2.fill", color: "blue", dimensionUnit: "ft"),
        CustomLevel(name: "Area", icon: "rectangle.fill", color: "green", dimensionUnit: "ft"),
        CustomLevel(name: "Cabinet", icon: "cabinet.fill", color: "orange", dimensionUnit: "in"),
        CustomLevel(name: "Shelf", icon: "archivebox.fill", color: "red", dimensionUnit: "in")
    ]
    
    return NavigationStack {
        HierarchyPreviewView(hierarchyName: "My Custom Workshop", levels: sampleLevels)
    }
}
