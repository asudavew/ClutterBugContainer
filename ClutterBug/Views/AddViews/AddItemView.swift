import SwiftUI
import SwiftData
import PhotosUI

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var hierarchyManager: HierarchyManager

    // Updated to work with Container instead of Room
    let targetContainer: Container

    @State private var itemName: String = ""
    @State private var itemCategory: String = ""
    @State private var itemQuantity: Int = 1
    @State private var itemNotes: String = ""
    @State private var itemSKU: String = ""
    
    private let conditionOptions = ["New", "Like New", "Good", "Fair", "Poor", "For Parts"]
    @State private var itemCondition: String = "Good"

    @State private var itemHeight: Double = 0.0
    @State private var itemWidth: Double = 0.0
    @State private var itemLength: Double = 0.0

    @State private var selectedPhotoPickerItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var newPhotoIdentifier: String? = nil

    // Photo map properties
    @State private var showPhotoOnMap: Bool = false
    @State private var photoMapPosition: PhotoMapPosition = .floating
    @State private var photoIconSize: PhotoIconSize = .small

    // State for validation and error handling
    @State private var showingError = false
    @State private var errorMessage = ""

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

    private var containerCanHoldItems: Bool {
        hierarchyManager.isLastLevel(targetContainer.levelNumber)
    }

    var body: some View {
        NavigationStack {
            Form {
                itemDetailsSection
                locationSection
                photoSection
                measurementsSection
                optionalInfoSection
            }
            .navigationTitle("Add New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .alert("Cannot Add Item", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                validateContainer()
            }
        }
    }

    // MARK: - View Sections

    private var itemDetailsSection: some View {
        Section("Item Details") {
            TextField("Name (e.g., Wrench)", text: $itemName)
            
            TextField("Category (e.g., Tools)", text: $itemCategory)
                .textInputAutocapitalization(.words)
            
            Picker("Condition", selection: $itemCondition) {
                ForEach(conditionOptions, id: \.self) { option in
                    Text(option)
                }
            }
            
            Stepper("Quantity: \(itemQuantity)", value: $itemQuantity, in: 1...1000)
        }
    }

    private var locationSection: some View {
        Section("Location") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: targetContainer.dynamicType(using: hierarchyManager).icon)
                        .foregroundColor(targetContainer.colorTypeEnum?.color ?? .blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Container: \(targetContainer.name)")
                            .font(.headline)
                        Text("Type: \(targetContainer.dynamicType(using: hierarchyManager).displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let purpose = targetContainer.purpose {
                            Text(purpose)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Text("Path: \(targetContainer.pathString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Container validation
                if !containerCanHoldItems {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Warning: This container typically holds other containers")
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
                PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images, photoLibrary: .shared()) {
                    Label(selectedPhotoPickerItem == nil ? "Add Photo" : "Change Photo", systemImage: "photo.on.rectangle.angled")
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
                            newPhotoIdentifier = UUID().uuidString
                        } else {
                            selectedPhotoData = nil
                            if newValue == nil {
                                newPhotoIdentifier = nil
                            }
                        }
                    }
                }
                
                // Remove photo button
                if selectedPhotoPickerItem != nil || selectedPhotoData != nil {
                    Button("Remove Photo", systemImage: "xmark.circle.fill", role: .destructive) {
                        selectedPhotoPickerItem = nil
                        selectedPhotoData = nil
                        newPhotoIdentifier = nil
                    }
                    .tint(.red)
                }

                // Photo map options (if photo is selected)
                if selectedPhotoData != nil {
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
            TextField("SKU (Optional)", text: $itemSKU)
                .textInputAutocapitalization(.characters)
            
            VStack(alignment: .leading) {
                Text("Notes (Optional):")
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

    // MARK: - Helper Functions

    private func validateContainer() {
        if !containerCanHoldItems {
            print("⚠️ Warning: Adding item to container that typically holds other containers")
        }
    }

    private func formatDimensions() -> String {
        let dimensions = [itemHeight, itemWidth, itemLength].filter { $0 > 0 }
        if dimensions.isEmpty { return "Not specified" }
        
        let formatted = dimensions.map { String(format: "%.1f", $0) }
        return formatted.joined(separator: "\" × ") + "\""
    }

    private func saveItem() {
        guard canSave else {
            errorMessage = "Item name cannot be empty."
            showingError = true
            return
        }

        // ✅ ENHANCED PHOTO HANDLING WITH COMPRESSION
        var identifierToSaveWithItem: String? = nil
        if let photoData = selectedPhotoData, let definiteIdentifier = newPhotoIdentifier {
            // Use the enhanced compressed saving method
            PhotoManager.shared.saveImage(data: photoData, identifier: definiteIdentifier)
            identifierToSaveWithItem = definiteIdentifier
            print("✅ Saved compressed photo for item: \(definiteIdentifier)")
        }

        // Create the item
        let newItem = Item(
            name: itemName,
            photoIdentifier: identifierToSaveWithItem,
            height: itemHeight,
            width: itemWidth,
            length: itemLength,
            category: itemCategory,
            quantity: itemQuantity,
            notes: itemNotes.isEmpty ? nil : itemNotes,
            sku: itemSKU.isEmpty ? nil : itemSKU,
            condition: itemCondition,
            parentContainer: targetContainer
        )

        // Set photo map properties
        newItem.showPhotoOnMap = showPhotoOnMap
        newItem.photoMapPosition = photoMapPosition.rawValue
        newItem.photoIconSize = photoIconSize.rawValue

        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            print("✅ Item '\(itemName)' saved to container '\(targetContainer.name)'")
            print("   📍 Path: \(targetContainer.pathString)")
            print("   📊 Container level: \(targetContainer.levelNumber) (\(targetContainer.dynamicType(using: hierarchyManager).displayName))")
            
            if !containerCanHoldItems {
                print("   ⚠️ Note: Container level \(targetContainer.levelNumber) typically holds other containers, not items")
            }
            
            if newItem.photoIdentifier != nil {
                print("   📸 Photo saved and compressed")
            }
            
            dismiss()
        } catch {
            print("❌ Error saving new item: \(error.localizedDescription)")
            
            // Clean up photo if save failed
            if let id = identifierToSaveWithItem {
                print("🧹 Cleaning up orphaned photo: \(id)")
                PhotoManager.shared.deleteImage(identifier: id)
            }
            
            errorMessage = "Failed to save item: \(error.localizedDescription)"
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
        
        // Create a sample container for preview
        let sampleContainer = Container(
            name: "Tool Cabinet",
            containerType: "level_5",
            purpose: "Hand tools and small hardware"
        )
        container.mainContext.insert(sampleContainer)
        
        return NavigationStack {
            AddItemView(targetContainer: sampleContainer)
                .environmentObject(hierarchyManager)
                .modelContainer(container)
        }
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
