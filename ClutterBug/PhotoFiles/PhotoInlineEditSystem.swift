import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Quick Edit Modal (Fixed for SwiftData)
struct QuickEditModal: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let container: Container?
    let item: Item?
    
    @State private var editedName: String
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var newPhotoIdentifier: String? = nil
    @State private var showingDeletePhotoConfirmation = false
    
    private let originalPhotoIdentifier: String?
    
    init(container: Container) {
        self.container = container
        self.item = nil
        self._editedName = State(initialValue: container.name)
        self.originalPhotoIdentifier = container.photoIdentifier
        self._newPhotoIdentifier = State(initialValue: container.photoIdentifier)
    }
    
    init(item: Item) {
        self.container = nil
        self.item = item
        self._editedName = State(initialValue: item.name)
        self.originalPhotoIdentifier = item.photoIdentifier
        self._newPhotoIdentifier = State(initialValue: item.photoIdentifier)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Photo Section
                VStack(spacing: 16) {
                    Text("Photo")
                        .font(.headline)
                    
                    // Photo Display
                    if let data = selectedPhotoData, let uiImage = UIImage(data: data) {
                        // New photo selected
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if let photoId = newPhotoIdentifier, let uiImage = PhotoManager.shared.loadImage(identifier: photoId) {
                        // Existing photo
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // No photo placeholder
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            Text("No Photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Photo Action Buttons
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(hasPhoto ? "Change Photo" : "Add Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if hasPhoto {
                            Button {
                                showingDeletePhotoConfirmation = true
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Divider()
                
                // Name Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.headline)
                    
                    TextField("Enter name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Quick Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveChanges() }
                        .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                        newPhotoIdentifier = UUID().uuidString
                    } else if newValue == nil {
                        selectedPhotoData = nil
                    }
                }
            }
            .alert("Remove Photo", isPresented: $showingDeletePhotoConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    selectedPhotoItem = nil
                    selectedPhotoData = nil
                    newPhotoIdentifier = nil
                }
            } message: {
                Text("Are you sure you want to remove this photo?")
            }
        }
    }
    
    private var hasPhoto: Bool {
        selectedPhotoData != nil || newPhotoIdentifier != nil
    }
    
    private func saveChanges() {
        // Handle container or item
        if let container = container {
            saveContainer(container)
        } else if let item = item {
            saveItem(item)
        }
    }
    
    private func saveContainer(_ container: Container) {
        // Update name
        container.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle photo changes
        handlePhotoChanges { photoId in
            container.photoIdentifier = photoId
        }
        
        saveToContext()
    }
    
    private func saveItem(_ item: Item) {
        // Update name
        item.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle photo changes
        handlePhotoChanges { photoId in
            item.photoIdentifier = photoId
        }
        
        saveToContext()
    }
    
    private func handlePhotoChanges(updateEntity: (String?) -> Void) {
        if let newImageData = selectedPhotoData, let newPhotoId = newPhotoIdentifier, newPhotoId != originalPhotoIdentifier {
            // New photo selected - save with compression
            PhotoManager.shared.saveImage(data: newImageData, identifier: newPhotoId)
            updateEntity(newPhotoId)
            
            // Clean up old photo
            if let oldId = originalPhotoIdentifier {
                PhotoManager.shared.deleteImage(identifier: oldId)
                print("🧹 Removed old photo: \(oldId)")
            }
            print("✅ Updated to compressed photo: \(newPhotoId)")
            
        } else if newPhotoIdentifier == nil, let oldId = originalPhotoIdentifier {
            // Photo removed
            PhotoManager.shared.deleteImage(identifier: oldId)
            updateEntity(nil)
            print("🧹 Removed photo: \(oldId)")
            
        } else if let newImageData = selectedPhotoData, let newPhotoId = newPhotoIdentifier, originalPhotoIdentifier == nil {
            // First photo added - save with compression
            PhotoManager.shared.saveImage(data: newImageData, identifier: newPhotoId)
            updateEntity(newPhotoId)
            print("✅ Added new compressed photo: \(newPhotoId)")
        }
    }
    
    private func saveToContext() {
        do {
            try modelContext.save()
            print("✅ Quick edit saved")
            dismiss()
        } catch {
            print("❌ Error saving quick edit: \(error.localizedDescription)")
            // Clean up new photo if save failed
            if let id = newPhotoIdentifier, id != originalPhotoIdentifier {
                PhotoManager.shared.deleteImage(identifier: id)
                print("🧹 Cleaned up photo after failed save")
            }
        }
    }
}

// MARK: - Enhanced Row Views with Inline Edit

struct EditableContainerRow: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingQuickEdit = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Enhanced photo/icon with edit indicator
            ZStack(alignment: .topTrailing) {
                PhotoOrIcon(
                    photoIdentifier: container.photoIdentifier,
                    fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
                    fallbackColor: container.colorTypeEnum?.color ?? .blue,
                    size: .large,
                    cornerRadius: 8,
                    borderColor: container.colorTypeEnum?.color ?? .blue,
                    borderWidth: 1.5
                )
                
                // Quick edit indicator
                Button {
                    showingQuickEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.blue, in: Circle())
                        .background(Color.white.opacity(0.8), in: Circle().inset(by: -2))
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: 4, y: -4)
            }
            
            // Container info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(container.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Photo indicator badge
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
            VStack(spacing: 4) {
                ActionButton(
                    icon: "arrow.right",
                    color: .blue,
                    action: onTap
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
        .sheet(isPresented: $showingQuickEdit) {
            QuickEditModal(container: container)
        }
    }
}

struct EditableItemRow: View {
    let item: Item
    
    @State private var showingQuickEdit = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Enhanced photo/icon with edit indicator
            ZStack(alignment: .topTrailing) {
                PhotoOrIcon(
                    photoIdentifier: item.photoIdentifier,
                    fallbackIcon: "cube.box.fill",
                    fallbackColor: Color.gray,
                    size: PhotoIconSize.large,
                    cornerRadius: 8,
                    borderColor: Color.gray,
                    borderWidth: 1.5
                )
                
                // Quick edit indicator
                Button {
                    showingQuickEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.blue, in: Circle())
                        .background(Color.white.opacity(0.8), in: Circle().inset(by: -2))
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: 4, y: -4)
            }
            
            // Item info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Photo indicator badge
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
                
                // Condition and other badges
                HStack(spacing: 8) {
                    ConditionBadge(condition: item.condition)
                    
                    if let sku = item.sku, !sku.isEmpty {
                        SKUBadge(sku: sku)
                    }
                    
                    if item.height > 0 || item.width > 0 || item.length > 0 {
                        DimensionsBadge(item: item)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showingQuickEdit) {
            QuickEditModal(item: item)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Item: \(item.name)")
        .accessibilityValue("Quantity: \(item.quantity), Condition: \(item.condition)")
        .accessibilityHint("Located in \(item.fullPath). Double tap to edit.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Quick Photo Access Toolbar
struct QuickPhotoToolbar: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allContainers: [Container]
    @Query private var allItems: [Item]
    
    @State private var showingPhotoGrid = false
    @State private var showingPhotoSettings = false
    
    private var photoCount: Int {
        let containerPhotos = allContainers.filter { $0.photoIdentifier != nil }.count
        let itemPhotos = allItems.filter { $0.photoIdentifier != nil }.count
        return containerPhotos + itemPhotos
    }
    
    private var hasPhotos: Bool {
        photoCount > 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo count badge
            Button {
                showingPhotoGrid = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundColor(hasPhotos ? .blue : .gray)
                    
                    if hasPhotos {
                        Text("\(photoCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(hasPhotos ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 8) {
                Button {
                    showingPhotoSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingPhotoGrid) {
            EnhancedPhotoGridView()
        }
        .sheet(isPresented: $showingPhotoSettings) {
            PhotoSettingsView()
        }
    }
}

// MARK: - Enhanced Photo Grid View
struct EnhancedPhotoGridView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Query private var allContainers: [Container]
    @Query private var allItems: [Item]
    
    @State private var selectedFilter: PhotoFilter = .all
    @State private var searchText = ""
    @State private var selectedPhotoEntity: PhotoEntity?
    
    enum PhotoFilter: String, CaseIterable {
        case all = "All"
        case containers = "Containers"
        case items = "Items"
    }
    
    struct PhotoEntity: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let photoId: String
        let entity: Any // Container or Item
        let typeIcon: String
        let typeColor: Color
        
        init(container: Container, hierarchyManager: HierarchyManager) {
            self.name = container.name
            self.type = container.safeDynamicType(using: hierarchyManager).displayName
            self.photoId = container.photoIdentifier ?? ""
            self.entity = container
            self.typeIcon = container.safeDynamicType(using: hierarchyManager).icon
            self.typeColor = container.colorTypeEnum?.color ?? .blue
        }
        
        init(item: Item) {
            self.name = item.name
            self.type = "Item"
            self.photoId = item.photoIdentifier ?? ""
            self.entity = item
            self.typeIcon = "cube.box.fill"
            self.typeColor = .gray
        }
    }
    
    private var photoEntities: [PhotoEntity] {
        var entities: [PhotoEntity] = []
        
        if selectedFilter == .all || selectedFilter == .containers {
            entities.append(contentsOf: allContainers.compactMap { container in
                guard container.photoIdentifier != nil else { return nil }
                return PhotoEntity(container: container, hierarchyManager: hierarchyManager)
            })
        }
        
        if selectedFilter == .all || selectedFilter == .items {
            entities.append(contentsOf: allItems.compactMap { item in
                guard item.photoIdentifier != nil else { return nil }
                return PhotoEntity(item: item)
            })
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            entities = entities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return entities.sorted { $0.name < $1.name }
    }
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search photos...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Filters
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(PhotoFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Stats
                    HStack {
                        Text("\(photoEntities.count) photo\(photoEntities.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Photo Grid
                ScrollView {
                    if photoEntities.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Photos Yet" : "No Photos Found",
                            systemImage: "photo.on.rectangle.angled",
                            description: Text(searchText.isEmpty ? "Add photos to your containers and items to see them here" : "Try adjusting your search or filter")
                        )
                        .padding(.top, 100)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(photoEntities) { entity in
                                PhotoGridCell(
                                    entity: entity,
                                    onTap: {
                                        selectedPhotoEntity = entity
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // This will be handled by the sheet
                    }
                }
            }
            .sheet(item: $selectedPhotoEntity) { entity in
                PhotoDetailView(entity: entity)
                    .environmentObject(hierarchyManager)
            }
        }
    }
}

// MARK: - Photo Grid Cell
struct PhotoGridCell: View {
    let entity: EnhancedPhotoGridView.PhotoEntity
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            // Photo
            if let image = PhotoManager.shared.loadThumbnail(identifier: entity.photoId, size: .medium) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Entity info
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: entity.typeIcon)
                        .font(.caption2)
                        .foregroundColor(entity.typeColor)
                    
                    Text(entity.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                
                Text(entity.type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let entity: EnhancedPhotoGridView.PhotoEntity
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingQuickEdit = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Large photo display
                    if let image = PhotoManager.shared.loadImage(identifier: entity.photoId) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 10)
                    }
                    
                    // Entity details
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: entity.typeIcon)
                                .font(.title2)
                                .foregroundColor(entity.typeColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entity.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(entity.type)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Additional details based on entity type
                        if let container = entity.entity as? Container {
                            ContainerPhotoDetails(container: container)
                                .environmentObject(hierarchyManager)
                        } else if let item = entity.entity as? Item {
                            ItemPhotoDetails(item: item)
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingQuickEdit = true
                    }
                }
            }
            .sheet(isPresented: $showingQuickEdit) {
                if let container = entity.entity as? Container {
                    QuickEditModal(container: container)
                } else if let item = entity.entity as? Item {
                    QuickEditModal(item: item)
                }
            }
        }
    }
}

// MARK: - Detail Views for Photo Details
struct ContainerPhotoDetails: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let purpose = container.purpose {
                DetailRow(label: "Purpose", value: purpose)
            }
            
            DetailRow(label: "Type", value: container.safeDynamicType(using: hierarchyManager).displayName)
            DetailRow(label: "Level", value: "\(container.levelNumber)")
            DetailRow(label: "Path", value: container.pathString)
            
            if container.childContainers?.count ?? 0 > 0 {
                DetailRow(label: "Contains", value: "\(container.childContainers?.count ?? 0) containers")
            }
            
            if container.totalItemCount > 0 {
                DetailRow(label: "Total Items", value: "\(container.totalItemCount)")
            }
        }
    }
}

struct ItemPhotoDetails: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !item.category.isEmpty {
                DetailRow(label: "Category", value: item.category)
            }
            
            DetailRow(label: "Condition", value: item.condition)
            DetailRow(label: "Quantity", value: "\(item.quantity)")
            DetailRow(label: "Location", value: item.fullPath)
            
            if let sku = item.sku, !sku.isEmpty {
                DetailRow(label: "SKU", value: sku)
            }
            
            if item.height > 0 || item.width > 0 || item.length > 0 {
                let dimensions = [item.height, item.width, item.length].filter { $0 > 0 }
                let formatted = dimensions.map { String(format: "%.1f", $0) }
                DetailRow(label: "Dimensions", value: formatted.joined(separator: "\" × ") + "\"")
            }
            
            if let notes = item.notes, !notes.isEmpty {
                DetailRow(label: "Notes", value: notes)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
    let hierarchyManager = HierarchyManager(modelContext: container.mainContext)

    let dummyContainer = Container(
        name: "My Workshop",
        containerType: "level_2",
        purpose: "Tools and projects"
    )
    dummyContainer.photoIdentifier = "sample_photo_123"
    
    let dummyItem = Item(
        name: "Cordless Drill",
        category: "Power Tools",
        quantity: 1,
        condition: "Good",
        parentContainer: dummyContainer
    )

    return VStack(spacing: 16) {
        EditableContainerRow(
            container: dummyContainer,
            onTap: { print("Tapped!") },
            onDelete: { print("Delete!") }
        )
        .environmentObject(hierarchyManager)
        
        EditableItemRow(item: dummyItem)
        
        QuickPhotoToolbar()
    }
    .padding()
    .modelContainer(container)
}
