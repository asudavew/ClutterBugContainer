import SwiftUI
import SwiftData

// MARK: - Map Edit Mode Enum
enum MapEditMode: String, CaseIterable {
    case view = "view"
    case edit = "edit"
    
    var isEditing: Bool {
        return self == .edit
    }
    
    var displayName: String {
        switch self {
        case .view: return "View"
        case .edit: return "Edit"
        }
    }
    
    var icon: String {
        switch self {
        case .view: return "eye.circle"
        case .edit: return "pencil.circle.fill"
        }
    }
}

// MARK: - Grid Background
struct MapGridView: View {
    let gridSize: CGFloat = 20
    
    var body: some View {
        Canvas { context, size in
            let cols = Int(size.width / gridSize) + 1
            let rows = Int(size.height / gridSize) + 1
            
            for col in 0...cols {
                let x = CGFloat(col) * gridSize
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(.gray.opacity(0.3)),
                    lineWidth: 0.5
                )
            }
            
            for row in 0...rows {
                let y = CGFloat(row) * gridSize
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(.gray.opacity(0.3)),
                    lineWidth: 0.5
                )
            }
        }
    }
}

// MARK: - Map Controls
struct MapControlsView: View {
    @Binding var editMode: MapEditMode
    @Binding var scale: CGFloat
    @Binding var showingAddShape: Bool
    @Binding var newShapeType: PlacedShape.ShapeType
    
    let onAddShape: (PlacedShape.ShapeType, CGPoint) -> Void
    let onResetView: () -> Void
    
    var body: some View {
        HStack {
            VStack(spacing: 8) {
                Button(action: {
                    editMode = editMode == .edit ? .view : .edit
                }) {
                    Image(systemName: editMode == .edit ? "pencil.circle.fill" : "pencil.circle")
                        .font(.title2)
                        .foregroundColor(editMode == .edit ? .blue : .gray)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showingAddShape = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                VStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = min(3.0, scale + 0.25)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = max(0.5, scale - 0.25)
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .shadow(radius: 2)
                
                Button(action: {
                    onResetView()
                }) {
                    Image(systemName: "scope")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingAddShape) {
            ShapeSelectionView(
                selectedType: $newShapeType,
                onAdd: { shapeType in
                    onAddShape(shapeType, CGPoint(x: 200, y: 200))
                    showingAddShape = false
                }
            )
        }
    }
}

// MARK: - Shape Selection Sheet
struct ShapeSelectionView: View {
    @Binding var selectedType: PlacedShape.ShapeType
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (PlacedShape.ShapeType) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose Container Shape")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 16)
                ], spacing: 20) {
                    ForEach(PlacedShape.ShapeType.allCases, id: \.self) { shapeType in
                        ShapeOptionView(
                            shapeType: shapeType,
                            isSelected: selectedType == shapeType,
                            onSelect: {
                                selectedType = shapeType
                            }
                        )
                    }
                }
                
                Spacer()
                
                Button(action: {
                    onAdd(selectedType)
                }) {
                    Text("Add Container")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .navigationTitle("Add Container")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct ShapeOptionView: View {
    let shapeType: PlacedShape.ShapeType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    .frame(width: 80, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                Image(systemName: shapeType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            
            Text(shapeType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Map Interaction Handler
struct MapInteractionView: View {
    @Binding var editMode: MapEditMode
    @Binding var selectedContainer: Container?
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    let onShapeAdded: (PlacedShape) -> Void
    let onShapeSelected: (PlacedShape?) -> Void
    
    var body: some View {
        ZStack {
            // Map grid background
            MapGridView()
            
            // Container shapes will be rendered here
            // This is where you'd add your shape rendering logic
            
            // Interaction overlay for edit mode
            if editMode.isEditing {
                Color.blue.opacity(0.1)
                    .allowsHitTesting(true)
                    .onTapGesture { location in
                        // Handle tap to add new shape
                        if editMode.isEditing {
                            addShapeAt(location)
                        }
                    }
            }
        }
    }
    
    private func addShapeAt(_ location: CGPoint) {
        // Create a new shape at the tapped location
        let newShape = PlacedShape.create(type: .rectangle, at: location)
        onShapeAdded(newShape)
    }
}

// MARK: - Preview
#Preview {
    struct MapComponentsPreview: View {
        @State private var editMode: MapEditMode = .view
        @State private var scale: CGFloat = 1.0
        @State private var showingAddShape = false
        @State private var newShapeType: PlacedShape.ShapeType = .rectangle
        
        var body: some View {
            VStack {
                Text("Map Edit Mode: \(editMode.displayName)")
                    .font(.headline)
                    .padding()
                
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                    
                    MapControlsView(
                        editMode: $editMode,
                        scale: $scale,
                        showingAddShape: $showingAddShape,
                        newShapeType: $newShapeType,
                        onAddShape: { shapeType, point in
                            print("Add shape: \(shapeType) at \(point)")
                        },
                        onResetView: {
                            print("Reset view")
                            scale = 1.0
                        }
                    )
                    .padding()
                }
                
                Text("Scale: \(String(format: "%.2f", scale))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Test buttons to verify they work
                HStack(spacing: 16) {
                    Button(action: {
                        print("Test button 1 tapped")
                    }) {
                        Text("Test 1")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        print("Test button 2 tapped")
                    }) {
                        Text("Test 2")
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
        }
    }
    
    return MapComponentsPreview()
}
