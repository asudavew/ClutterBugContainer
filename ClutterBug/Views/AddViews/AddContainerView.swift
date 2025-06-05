import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Add Container View (Dynamic Hierarchy Support)
struct AddContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    let parentContainer: Container?
    let targetLevel: Int
    
    // Container Properties
    @State private var containerName: String = ""
    @State private var containerPurpose: String = ""
    @State private var containerNotes: String = ""
    @State private var selectedColor: PlacedShape.ShapeColor = .blue
    @State private var selectedShapeType: PlacedShape.ShapeType = .rectangle
    
    // Dimensions
    @State private var containerLength: Double = 0.0
    @State private var containerWidth: Double = 0.0
    @State private var containerHeight: Double = 0.0
    @State private var side3: Double = 0.0
    @State private var side4: Double = 0.0
    @State private var rotation: Double = 0.0
    
    // Photo
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var photoIdentifier: String? = nil
    
    private var numberFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }
    
    private var levelInfo: HierarchyLevel? {
        hierarchyManager.getLevel(at: targetLevel)
    }
    
    private var canSave: Bool {
        !containerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var dimensionUnit: String {
        levelInfo?.defaultDimensionUnit ?? "in"
    }
    
    private var isLargeScale: Bool {
        levelInfo?.isLargeScale ?? false
    }
    
    var body: some View {
        Form {
            containerDetailsSection
            containerShapeSection
            dimensionsSection
            
            if selectedShapeType.canRotate {
                orientationSection
            }
            
            photoSection
            notesSection
            
            if let parent = parentContainer {
                locationSection(parent: parent)
            }
            
            hierarchyInfoSection
        }
        .navigationTitle("Add \(levelInfo?.name ?? "Container")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveContainer() }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            setupDefaults()
        }
    }
    
    // MARK: - View Sections
    
    private var containerDetailsSection: some View {
        Section("Container Details") {
            TextField("Name (e.g., Tool Cabinet, Storage Room)", text: $containerName)
            
            HStack {
                Image(systemName: levelInfo?.icon ?? "square.fill")
                    .foregroundColor(selectedColor.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Type: \(levelInfo?.name ?? "Container")")
                        .font(.headline)
                    Text("Level \(targetLevel) in hierarchy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("(Auto-assigned)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
            
            TextField("Purpose (Optional)", text: $containerPurpose)
                .textInputAutocapitalization(.words)
        }
    }
    
    private var containerShapeSection: some View {
        Section("Container Shape") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Shape:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PlacedShape.ShapeType.allCases, id: \.self) { shapeType in
                            Button(action: {
                                selectedShapeType = shapeType
                                if shapeType == .circle {
                                    containerLength = containerWidth
                                }
                            }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedShapeType == shapeType ? selectedColor.color.opacity(0.2) : Color.gray.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedShapeType == shapeType ? selectedColor.color : Color.gray, lineWidth: selectedShapeType == shapeType ? 2 : 1)
                                            )
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: shapeType.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(selectedShapeType == shapeType ? selectedColor.color : .gray)
                                    }
                                    
                                    Text(shapeType.displayName)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedShapeType == shapeType ? selectedColor.color : .gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
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
    
    private var dimensionsSection: some View {
        Section("Dimensions (\(dimensionUnit))") {
            VStack(spacing: 8) {
                switch selectedShapeType {
                case .circle:
                    HStack {
                        Text("Diameter:")
                        TextField("Diameter", value: $containerWidth, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                            .onChange(of: containerWidth) { _, newValue in
                                containerLength = newValue
                            }
                    }
                    
                case .rectangle:
                    HStack {
                        Text("Length:")
                        TextField("Length", value: $containerLength, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Width:")
                        TextField("Width", value: $containerWidth, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    
                case .triangle:
                    HStack {
                        Text("Side 1:")
                        TextField("Side 1", value: $containerLength, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Side 2:")
                        TextField("Side 2", value: $containerWidth, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Side 3:")
                        TextField("Side 3", value: $side3, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    
                case .quadrilateral:
                    HStack {
                        Text("Top:")
                        TextField("Top", value: $containerLength, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Right:")
                        TextField("Right", value: $containerWidth, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Bottom:")
                        TextField("Bottom", value: $side3, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Left:")
                        TextField("Left", value: $side4, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    
                case .tee:
                    HStack {
                        Text("Total Width:")
                        TextField("Total Width", value: $containerLength, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Total Height:")
                        TextField("Total Height", value: $containerWidth, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Stem Width:")
                        TextField("Stem Width", value: $side3, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Top Height:")
                        TextField("Top Height", value: $side4, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                }
                
                if !isLargeScale {
                    HStack {
                        Text("Height:")
                        TextField("Height", value: $containerHeight, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
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
        Section("Photo (Optional)") {
            VStack(spacing: 12) {
                // Photo preview
                if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
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
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Label(selectedPhotoItem == nil ? "Add Photo" : "Change Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                
                if selectedPhotoItem != nil {
                    Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                        selectedPhotoItem = nil
                        selectedPhotoData = nil
                        photoIdentifier = nil
                    }
                }
                
                // Photo info
                if selectedPhotoData != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📸 Photo will be:")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("• Automatically compressed for storage")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Used as icon in lists and views")
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
                    photoIdentifier = UUID().uuidString
                } else {
                    selectedPhotoData = nil
                    if newValue == nil { photoIdentifier = nil }
                }
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes (Optional)") {
            TextEditor(text: $containerNotes)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private func locationSection(parent: Container) -> some View {
        Section("Location") {
            HStack {
                Image(systemName: hierarchyManager.levelIcon(for: parent.levelNumber))
                    .foregroundColor(hierarchyManager.levelColorEnum(for: parent.levelNumber)?.color ?? .blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Inside: \(parent.name)")
                        .font(.headline)
                    Text("Type: \(hierarchyManager.levelName(for: parent.levelNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let purpose = parent.purpose {
                        Text(purpose)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("Path: \(parent.pathString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private var hierarchyInfoSection: some View {
        Section("Hierarchy Information") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("This will be a Level \(targetLevel) container")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if targetLevel < hierarchyManager.maxLevels() {
                    let nextLevel = targetLevel + 1
                    let nextLevelName = hierarchyManager.levelName(for: nextLevel)
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.green)
                        Text("Can contain: \(nextLevelName) containers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(.orange)
                        Text("Can contain: Items only (final level)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let config = hierarchyManager.activeConfiguration {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundColor(.purple)
                        Text("Using: \(config.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupDefaults() {
        guard let levelInfo = levelInfo else { return }
        
        let defaultWidth = isLargeScale ? 10.0 : 12.0
        let defaultLength = isLargeScale ? 12.0 : 8.0
        let defaultHeight = isLargeScale ? 9.0 : 6.0
        
        containerLength = defaultLength
        containerWidth = defaultWidth
        containerHeight = defaultHeight
        
        selectedColor = levelInfo.colorEnum ?? .blue
        
        if containerName.isEmpty {
            containerName = "New \(levelInfo.name)"
        }
    }
    
    private func saveContainer() {
        guard let levelInfo = levelInfo else {
            print("❌ No level information available")
            return
        }
        
        guard let newContainer = Container.createDynamic(
            name: containerName,
            level: targetLevel,
            parentContainer: parentContainer,
            hierarchyManager: hierarchyManager
        ) else {
            print("❌ Failed to create container")
            return
        }
        
        // ✅ ENHANCED PHOTO HANDLING WITH COMPRESSION
        if let data = selectedPhotoData, let id = photoIdentifier {
            // Use the enhanced compressed saving method
            PhotoManager.shared.saveImage(data: data, identifier: id)
            newContainer.photoIdentifier = id
            print("✅ Saved compressed photo for container: \(id)")
        }
        
        // Set container properties
        newContainer.purpose = containerPurpose.isEmpty ? nil : containerPurpose
        newContainer.notes = containerNotes.isEmpty ? nil : containerNotes
        newContainer.colorType = selectedColor.rawValue
        newContainer.shapeType = selectedShapeType.rawValue
        newContainer.rotation = rotation
        
        // Set dimensions based on shape type
        switch selectedShapeType {
        case .circle:
            newContainer.length = containerWidth
            newContainer.width = containerWidth
            newContainer.side3 = nil
            newContainer.side4 = nil
            
        case .rectangle:
            newContainer.length = containerLength
            newContainer.width = containerWidth
            newContainer.side3 = nil
            newContainer.side4 = nil
            
        case .triangle:
            newContainer.length = containerLength
            newContainer.width = containerWidth
            newContainer.side3 = side3
            newContainer.side4 = nil
            
        case .quadrilateral:
            newContainer.length = containerLength
            newContainer.width = containerWidth
            newContainer.side3 = side3
            newContainer.side4 = side4
            
        case .tee:
            newContainer.length = containerLength
            newContainer.width = containerWidth
            newContainer.side3 = side3
            newContainer.side4 = side4
        }
        
        if !isLargeScale {
            newContainer.height = containerHeight
        }
        
        modelContext.insert(newContainer)
        
        do {
            try modelContext.save()
            print("✅ Container '\(containerName)' created as \(levelInfo.name) (Level \(targetLevel))")
            if let parent = parentContainer {
                print("   └── Inside: \(parent.pathString)")
            } else {
                print("   └── At root level")
            }
            if newContainer.photoIdentifier != nil {
                print("   📸 Photo saved and compressed")
            }
            dismiss()
        } catch {
            print("❌ Error saving container: \(error.localizedDescription)")
            // Clean up photo if save failed
            if let id = photoIdentifier {
                PhotoManager.shared.deleteImage(identifier: id)
                print("🧹 Cleaned up photo after failed save")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
        
        let workshop = Container.createBuilding(name: "Sample Workshop")
        container.mainContext.insert(workshop)
        
        return AddContainerView(
            parentContainer: workshop,
            targetLevel: 2
        )
        .environmentObject(hierarchyManager)
        .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
