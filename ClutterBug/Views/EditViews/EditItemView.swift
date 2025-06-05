import SwiftUI
import SwiftData
import PhotosUI

struct EditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var hierarchyManager: HierarchyManager

    // The item to be edited. Use @Bindable to allow two-way binding from form fields.
    @Bindable var item: Item

    // State variables to hold temporary changes for the form.
    @State private var itemName: String
    @State private var itemCategory: String
    @State private var itemQuantity: Int
    @State private var itemNotes: String
    @State private var itemSKU: String
    @State private var itemCondition: String
    @State private var itemHeight: Double
    @State private var itemWidth: Double
    @State private var itemLength: Double

    // Photo picker state
    @State private var selectedPhotoPickerItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    
    // Holds the identifier of the photo currently associated with the item OR a new one if a new photo is picked.
    @State private var currentPhotoIdentifier: String?

    // Photo map properties
    @State private var showPhotoOnMap: Bool
    @State private var photoMapPosition: PhotoMapPosition
    @State private var photoIconSize: PhotoIconSize

    // To track the original photo identifier, so we know if we need to delete an old photo file.
    private let originalPhotoIdentifier: String?

    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""

    private let conditionOptions = ["New", "Like New", "Good", "Fair", "Poor", "For Parts"]
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private var canSave: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(item: Item) {
        _item = Bindable(item)

        // Initialize @State variables with the item's current values
        _itemName = State(initialValue: item.name)
        _itemCategory = State(initialValue: item.category)
        _itemQuantity = State(initialValue: item.quantity)
        _itemNotes = State(initialValue: item.notes ?? "")
        _itemSKU = State(initialValue: item.sku ?? "")
        _itemCondition = State(initialValue: item.condition)
        _itemHeight = State(initialValue: item.height)
        _itemWidth = State(initialValue: item.width)
        _itemLength = State(initialValue: item.length)
        
        _currentPhotoIdentifier = State(initialValue: item.photoIdentifier)
        self.originalPhotoIdentifier = item.photoIdentifier

        // Initialize photo map properties
        _showPhotoOnMap = State(initialValue: item.showPhotoOnMap)
        _photoMapPosition = State(initialValue: item.photoMapPositionEnum)
        _photoIconSize = State(initialValue: item.photoIconSizeEnum)
    }

    var body: some View {
        NavigationStack {
            Form {
                itemDetailsSection
                locationSection
                photoSection
                measurementsSection
                optionalInfoSection
                itemStatsSection
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateItem()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Validation on appear
                validateItem()
            }
        }
    }

    // MARK: - View Sections

    private var itemDetailsSection: some View {
        Section("Item Details") {
            TextField("Name", text: $itemName)
            
            TextField("Category", text: $itemCategory)
                .textInputAutocapitalization(.words)
            
            Picker("Condition", selection: $itemCondition) {
                ForEach(conditionOptions, id: \.self) { Text($0) }
            }
            
            Stepper("Quantity: \(itemQuantity)", value: $itemQuantity, in: 1...1000)
        }
    }

    private var locationSection: some View {
        Section("Location") {
            if let container = item.parentContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: container.dynamicType(using: hierarchyManager).icon)
                            .foregroundColor(container.colorTypeEnum?.color ?? .blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Container: \(container.name)")
                                .font(.headline)
                            Text("Type: \(container.dynamicType(using: hierarchyManager).displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let purpose = container.purpose {
                                Text(purpose)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Text("Path: \(container.pathString)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Container level validation
                    let containerCanHoldItems = hierarchyManager.isLastLevel(container.levelNumber)
                    if !containerCanHoldItems {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Note: This container typically holds other containers")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Items are usually stored in \(hierarchyManager.levelName(for: hierarchyManager.maxLevels()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No container assigned")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var photoSection: some View {
        Section("Photo") {
            VStack(spacing: 12) {
                // Photo display
                if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let identifier = currentPhotoIdentifier, let uiImage = PhotoManager.shared.loadImage(identifier: identifier) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    // Placeholder
                    VStack(spacing: 8) {
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("No Photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Photo picker
                PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images) {
                    Label(selectedPhotoData != nil || currentPhotoIdentifier != nil ? "Change Photo" : "Add Photo", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                .onChange(of: selectedPhotoPickerItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                            currentPhotoIdentifier = UUID().uuidString
                        } else {
                            if newValue == nil {
                                selectedPhotoData = nil
                                if self.selectedPhotoData == nil {
                                    self.currentPhotoIdentifier = self.originalPhotoIdentifier
                                }
                            }
                        }
                    }
                }
                
                // Remove photo button
                if selectedPhotoData != nil || currentPhotoIdentifier != nil {
                    Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                        selectedPhotoPickerItem = nil
                        selectedPhotoData = nil
                        currentPhotoIdentifier = nil
                    }
                    .tint(.red)
                }

                // Photo map options (if photo exists)
                if selectedPhotoData != nil || currentPhotoIdentifier != nil {
                    Divider()
                    
                    Toggle("Show on Map", isOn: $showPhotoOnMap)
                    
                    if showPhotoOnMap {
                        Picker("Map Position", selection: $photoMapPosition) {
                            ForEach(PhotoMapPosition.allCases, id: \.self) { position in
                                Text(position.displayName).tag(position)
                            }
                        }
                        
                        Picker("Icon Size", selection: $photoIconSize) {
                            ForEach(PhotoIconSize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                    }
                }
                
                // Photo compression info
                if selectedPhotoData != nil || currentPhotoIdentifier != nil {
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
    }

    private var measurementsSection: some View {
        Section("Measurements (inches)") {
            HStack {
                Text("H:")
                    .frame(width: 20, alignment: .leading)
                TextField("Height", value: $itemHeight, formatter: numberFormatter)
                    .keyboardType(.decimalPad)
            }
            HStack {
                Text("W:")
                    .frame(width: 20, alignment: .leading)
                TextField("Width", value: $itemWidth, formatter: numberFormatter)
                    .keyboardType(.decimalPad)
            }
            HStack {
                Text("L:")
                    .frame(width: 20, alignment: .leading)
                TextField("Length", value: $itemLength, formatter: numberFormatter)
                    .keyboardType(.decimalPad)
            }
            
            if itemHeight > 0 || itemWidth > 0 || itemLength > 0 {
                HStack {
                    Image(systemName: "ruler.fill")
                        .foregroundColor(.blue)
                    Text("Dimensions: \(formatDimensions())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var optionalInfoSection: some View {
        Section("Optional Info") {
            TextField("SKU", text: $itemSKU)
                .textInputAutocapitalization(.characters)
            
            VStack(alignment: .leading) {
                Text("Notes:")
                TextEditor(text: $itemNotes)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            if !itemNotes.isEmpty {
                Text("\(itemNotes.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var itemStatsSection: some View {
        Section("Item Information") {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.blue)
                Text("Added")
                Spacer()
                Text("Recently") // Could be enhanced with actual date tracking
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.green)
                Text("Last Modified")
                Spacer()
                Text("Now") // Could be enhanced with actual modification tracking
                    .foregroundColor(.secondary)
            }
            
            if let container = item.parentContainer {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.purple)
                    Text("Hierarchy Level")
                    Spacer()
                    Text("Level \(container.levelNumber)")
                        .foregroundColor(.secondary)
                }
            }
            
            if item.photoIdentifier != nil {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.green)
                    Text("Photo Available")
                    Spacer()
                    Text("Compressed & Optimized")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func validateItem() {
        if let container = item.parentContainer {
            let containerCanHoldItems = hierarchyManager.isLastLevel(container.levelNumber)
            if !containerCanHoldItems {
                print("⚠️ Item is in container that typically holds other containers (Level \(container.levelNumber))")
            }
        }
    }

    private func formatDimensions() -> String {
        let dimensions = [itemHeight, itemWidth, itemLength].filter { $0 > 0 }
        if dimensions.isEmpty { return "Not specified" }
        
        let formatted = dimensions.map { String(format: "%.1f", $0) }
        return formatted.joined(separator: "\" × ") + "\""
    }

    private func updateItem() {
        // Update basic properties
        item.name = itemName
        item.category = itemCategory
        item.quantity = itemQuantity
        item.notes = itemNotes.isEmpty ? nil : itemNotes
        item.sku = itemSKU.isEmpty ? nil : itemSKU
        item.condition = itemCondition
        item.height = itemHeight
        item.width = itemWidth
        item.length = itemLength

        // Update photo map properties
        item.showPhotoOnMap = showPhotoOnMap
        item.photoMapPosition = photoMapPosition.rawValue
        item.photoIconSize = photoIconSize.rawValue

        // ✅ ENHANCED PHOTO MANAGEMENT WITH COMPRESSION
        if let newPhotoData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, newPhotoId != originalPhotoIdentifier {
            // New photo selected - save with compression
            PhotoManager.shared.saveImage(data: newPhotoData, identifier: newPhotoId)
            item.photoIdentifier = newPhotoId
            
            // Clean up old photo
            if let oldId = originalPhotoIdentifier {
                PhotoManager.shared.deleteImage(identifier: oldId)
                print("🧹 Removed old photo: \(oldId)")
            }
            print("✅ Updated to compressed photo: \(newPhotoId)")
            
        } else if currentPhotoIdentifier == nil, let oldId = originalPhotoIdentifier {
            // Photo removed
            PhotoManager.shared.deleteImage(identifier: oldId)
            item.photoIdentifier = nil
            print("🧹 Removed photo: \(oldId)")
            
        } else if let newPhotoData = selectedPhotoData, let newPhotoId = currentPhotoIdentifier, originalPhotoIdentifier == nil {
            // First photo added - save with compression
            PhotoManager.shared.saveImage(data: newPhotoData, identifier: newPhotoId)
            item.photoIdentifier = newPhotoId
            print("✅ Added new compressed photo: \(newPhotoId)")
        }

        do {
            try modelContext.save()
            print("✅ Item '\(itemName)' updated successfully")
            if let container = item.parentContainer {
                print("   📍 Location: \(container.name)")
                print("   🗂️ Path: \(container.pathString)")
            }
            if item.photoIdentifier != nil {
                print("   📸 Photo updated and compressed")
            }
            dismiss()
        } catch {
            print("❌ Error updating item: \(error.localizedDescription)")
            // Clean up new photo if save failed
            if let id = currentPhotoIdentifier, id != originalPhotoIdentifier {
                PhotoManager.shared.deleteImage(identifier: id)
                print("🧹 Cleaned up photo after failed update")
            }
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
        
        // Create sample data for preview
        let sampleContainer = Container(
            name: "Tool Drawer",
            containerType: "level_5",
            purpose: "Small hand tools"
        )
        container.mainContext.insert(sampleContainer)
        
        let sampleItem = Item(
            name: "Phillips Screwdriver",
            category: "Hand Tools",
            quantity: 1,
            condition: "Good",
            parentContainer: sampleContainer
        )
        sampleItem.notes = "Size #2, red handle"
        container.mainContext.insert(sampleItem)
        
        return NavigationStack {
            EditItemView(item: sampleItem)
                .environmentObject(hierarchyManager)
                .modelContainer(container)
        }
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
