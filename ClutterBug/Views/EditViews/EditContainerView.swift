import SwiftUI
import SwiftData
import PhotosUI

struct EditContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    @Bindable var container: Container
    
    // State variables for editing
    @State private var containerName: String
    @State private var containerPurpose: String
    @State private var containerNotes: String
    @State private var selectedColor: PlacedShape.ShapeColor
    @State private var rotation: Double
    
    // Dimensions
    @State private var containerLength: Double
    @State private var containerWidth: Double
    @State private var containerHeight: Double
    @State private var side3: Double
    @State private var side4: Double
    
    // Photo handling
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var currentPhotoIdentifier: String? // This holds the ID of the photo being displayed/edited
    private let originalPhotoIdentifier: String? // This holds the ID of the photo when the view loaded
    
    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }
    
    private var canSave: Bool {
        !containerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var levelInfo: HierarchyLevel? {
        hierarchyManager.getLevel(at: container.levelNumber)
    }
    
    private var dimensionUnit: String {
        levelInfo?.defaultDimensionUnit ?? "in"
    }
    
    private var isLargeScale: Bool {
        levelInfo?.isLargeScale ?? false
    }
    
    private var shapeType: PlacedShape.ShapeType {
        container.shapeTypeEnum ?? .rectangle
    }
    
    init(container: Container) {
        _container = Bindable(container)
        
        // Initialize state variables with current container values
        _containerName = State(initialValue: container.name)
        _containerPurpose = State(initialValue: container.purpose ?? "")
        _containerNotes = State(initialValue: container.notes ?? "")
        _selectedColor = State(initialValue: container.colorTypeEnum ?? .blue)
        _rotation = State(initialValue: container.rotation ?? 0.0)
        
        _containerLength = State(initialValue: container.length)
        _containerWidth = State(initialValue: container.width)
        _containerHeight = State(initialValue: container.height)
        _side3 = State(initialValue: container.side3 ?? 0.0)
        _side4 = State(initialValue: container.side4 ?? 0.0)
        
        _currentPhotoIdentifier = State(initialValue: container.photoIdentifier)
        self.originalPhotoIdentifier = container.photoIdentifier
    }
    
    var body: some View {
        Form {
            containerDetailsSection
            hierarchyInfoSection
            shapeAndDimensionsSection
            if shapeType.canRotate {
                orientationSection
            }
            photoSection
            notesSection
            containerStatsSection
        }
        .navigationTitle("Edit \(levelInfo?.name ?? "Container")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { updateContainer() }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var containerDetailsSection: some View {
        Section("Container Details") {
            TextField("Name", text: $containerName)
            
            // Show container type (not editable)
            HStack {
                Image(systemName: levelInfo?.icon ?? "square.fill")
                    .foregroundColor(selectedColor.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Type: \(levelInfo?.name ?? "Container")")
                        .font(.headline)
                    Text("Level \(container.levelNumber) in hierarchy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("(Cannot change)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
            
            TextField("Purpose", text: $containerPurpose)
                .textInputAutocapitalization(.words)
            
            Picker("Color", selection: $selectedColor) {
                ForEach(PlacedShape.ShapeColor.allCases, id: \.self) { color in
                    HStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 20, height: 20)
                        Text(color.displayName)
                    }
                    .tag(color)
                }
            }
        }
    }
    
    private var hierarchyInfoSection: some View {
        Section("Hierarchy Information") {
            VStack(alignment: .leading, spacing: 8) {
                if let parent = container.parentContainer {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Parent: \(parent.name)")
                                .font(.subheadline)
                            Text("Type: \(hierarchyManager.levelName(for: parent.levelNumber))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    Text("Path: \(container.pathString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let children = container.childContainers, !children.isEmpty {
                    let nextLevel = container.levelNumber + 1
                    let nextLevelName = hierarchyManager.levelPluralName(for: nextLevel)
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.purple)
                        Text("Contains: \(children.count) \(nextLevelName.lowercased())")
                            .font(.subheadline)
                    }
                }
                
                if container.totalItemCount > 0 {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(.orange)
                        Text("Total Items: \(container.totalItemCount)")
                            .font(.subheadline)
                    }
                }
                
                // Show what this container can contain
                if container.levelNumber < hierarchyManager.maxLevels() {
                    let nextLevel = container.levelNumber + 1
                    let nextLevelName = hierarchyManager.levelName(for: nextLevel)
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.mint)
                        Text("Can contain: \(nextLevelName) containers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.mint)
                        Text("Can contain: Items only (final level)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var shapeAndDimensionsSection: some View {
        Section("Shape & Dimensions") {
            HStack {
                Image(systemName: shapeType.icon)
                    .foregroundColor(selectedColor.color)
                    .font(.title2)
                Text("Shape: \(shapeType.displayName)")
                    .font(.headline)
                Spacer()
                Text("(Cannot change)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
            
            dimensionInputs
        }
    }
    
    @ViewBuilder
    private var dimensionInputs: some View {
        VStack(spacing: 8) {
            switch shapeType {
            case .circle:
                HStack {
                    Text("Diameter (\(dimensionUnit)):")
                    TextField("Diameter", value: $containerWidth, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .onChange(of: containerWidth) { _, newValue in
                            containerLength = newValue
                        }
                }
                
            case .rectangle:
                HStack {
                    Text("Length (\(dimensionUnit)):");
                    TextField("Length", value: $containerLength, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Width (\(dimensionUnit)):");
                    TextField("Width", value: $containerWidth, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                
            case .triangle:
                HStack {
                    Text("Side 1 (\(dimensionUnit)):");
                    TextField("Side 1", value: $containerLength, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Side 2 (\(dimensionUnit)):");
                    TextField("Side 2", value: $containerWidth, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Side 3 (\(dimensionUnit)):");
                    TextField("Side 3", value: $side3, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                
            case .quadrilateral:
                HStack {
                    Text("Top (\(dimensionUnit)):");
                    TextField("Top", value: $containerLength, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Right (\(dimensionUnit)):");
                    TextField("Right", value: $containerWidth, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Bottom (\(dimensionUnit)):");
                    TextField("Bottom", value: $side3, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Left (\(dimensionUnit)):");
                    TextField("Left", value: $side4, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                
                quickFillButtons
                
            case .tee:
                HStack {
                    Text("Total Width (\(dimensionUnit)):");
                    TextField("Total Width", value: $containerLength, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Total Height (\(dimensionUnit)):");
                    TextField("Total Height", value: $containerWidth, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Stem Width (\(dimensionUnit)):");
                    TextField("Stem Width", value: $side3, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Top Height (\(dimensionUnit)):");
                    TextField("Top Height", value: $side4, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
            }
            
            if !isLargeScale {
                HStack {
                    Text("Height (\(dimensionUnit)):");
                    TextField("Height", value: $containerHeight, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    private var quickFillButtons: some View {
        VStack(spacing: 8) {
            Text("Quick Fill:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Rectangle") {
                    side3 = containerLength  // bottom = top
                    side4 = containerWidth   // left = right
                }
                .font(.caption)
                .buttonStyle(.bordered)
                
                Button("Square") {
                    let side = containerLength
                    containerWidth = side
                    side3 = side
                    side4 = side
                }
                .font(.caption)
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    private var orientationSection: some View {
        Section("Orientation") {
            VStack(spacing: 8) {
                HStack {
                    Text("Rotation: \(Int(rotation))°")
                        .font(.subheadline)
                    Spacer()
                    Button("Reset") {
                        rotation = 0
                    }
                    .font(.caption)
                    .disabled(rotation == 0)
                }
                
                Slider(value: $rotation, in: 0...360, step: 15) {
                    Text("Rotation")
                }
                .accentColor(selectedColor.color)
            }
        }
    }
    
    private var photoSection: some View {
        Section("Photo") {
            VStack(spacing: 12) {
                // Photo display
                if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let photoId = currentPhotoIdentifier, let uiImage = PhotoManager.shared.loadImage(identifier: photoId) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Placeholder
                    VStack(spacing: 8) {
                        Image(systemName: levelInfo?.icon ?? "square.fill")
                            .font(.system(size: 40))
                            .foregroundColor(selectedColor.color.opacity(0.6))
                        
                        Text("No Photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: 120)
                    .frame(maxWidth: .infinity)
                    .background(selectedColor.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Photo picker
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(currentPhotoIdentifier != nil || selectedPhotoData != nil ? "Change Photo" : "Add Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                
                if currentPhotoIdentifier != nil || selectedPhotoData != nil {
                    Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                        selectedPhotoItem = nil
                        selectedPhotoData = nil
                        currentPhotoIdentifier = nil
                    }
                }
                
                // Photo info
                if currentPhotoIdentifier != nil || selectedPhotoData != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📸 Photo features:")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("• Used as icon in lists and views")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Automatically compressed for storage")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Generated in multiple sizes for performance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedPhotoData = data
                    currentPhotoIdentifier = UUID().uuidString
                } else if newValue == nil {
                    selectedPhotoData = nil
                }
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $containerNotes)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var containerStatsSection: some View {
        Section("Container Statistics") {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(.blue)
                Text("Direct Children")
                Spacer()
                Text("\(container.childContainers?.count ?? 0)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(.green)
                Text("Items (Direct)")
                Spacer()
                Text("\(container.directItemCount)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(.orange)
                Text("Items (Total)")
                Spacer()
                Text("\(container.totalItemCount)")
                    .foregroundColor(.secondary)
            }
            
            if let config = hierarchyManager.activeConfiguration {
                HStack {
                    Image(systemName: "list.bullet.indent")
                        .foregroundColor(.purple)
                    Text("Organization Style")
                    Spacer()
                    Text(config.name)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func updateContainer() {
        container.name = containerName
        container.purpose = containerPurpose.isEmpty ? nil : containerPurpose
        container.notes = containerNotes.isEmpty ? nil : containerNotes
        container.colorType = selectedColor.rawValue
        container.rotation = rotation
        
        // Update dimensions based on shape type
        switch shapeType {
        case .circle:
            container.length = containerWidth
            container.width = containerWidth
            container.side3 = nil
            container.side4 = nil
            
        case .rectangle:
            container.length = containerLength
            container.width = containerWidth
            container.side3 = nil
            container.side4 = nil
            
        case .triangle:
            container.length = containerLength
            container.width = containerWidth
            container.side3 = side3
            container.side4 = nil
            
        case .quadrilateral:
            container.length = containerLength  // Top
            container.width = containerWidth    // Right
            container.side3 = side3             // Bottom
            container.side4 = side4             // Left
            
        case .tee:
            container.length = containerLength  // Total width
            container.width = containerWidth    // Total height
            container.side3 = side3             // Stem width
            container.side4 = side4             // Top height
        }
        
        if !isLargeScale {
            container.height = containerHeight
        }
        
        // ✅ ENHANCED PHOTO UPDATE HANDLING WITH COMPRESSION
        if let newImageData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, newPhotoId != originalPhotoIdentifier {
            // New photo selected - save with compression
            PhotoManager.shared.saveImage(data: newImageData, identifier: newPhotoId)
            container.photoIdentifier = newPhotoId
            
            // Clean up old photo
            if let oldId = originalPhotoIdentifier {
                PhotoManager.shared.deleteImage(identifier: oldId)
                print("🧹 Removed old photo: \(oldId)")
            }
            print("✅ Updated to compressed photo: \(newPhotoId)")
            
        } else if currentPhotoIdentifier == nil, let oldId = originalPhotoIdentifier {
            // Photo removed
            PhotoManager.shared.deleteImage(identifier: oldId)
            container.photoIdentifier = nil
            print("🧹 Removed photo: \(oldId)")
            
        } else if let newImageData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, originalPhotoIdentifier == nil {
            // First photo added - save with compression
            PhotoManager.shared.saveImage(data: newImageData, identifier: newPhotoId)
            container.photoIdentifier = newPhotoId
            print("✅ Added new compressed photo: \(newPhotoId)")
        }
        
        do {
            try modelContext.save()
            print("✅ Container '\(containerName)' updated")
            if container.photoIdentifier != nil {
                print("   📸 Photo updated and compressed")
            }
            dismiss()
        } catch {
            print("❌ Error updating container: \(error.localizedDescription)")
            // Clean up new photo if save failed
            if let id = currentPhotoIdentifier, id != originalPhotoIdentifier {
                PhotoManager.shared.deleteImage(identifier: id)
                print("🧹 Cleaned up photo after failed update")
            }
        }
    }
}
