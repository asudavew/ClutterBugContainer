import SwiftUI
import SwiftData

struct PhotoSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var storageInfo: PhotoStorageInfo?
    @State private var validationReport: PhotoValidationReport?
    @State private var isValidating = false
    @State private var isMigrating = false
    @State private var isCalculatingStorage = false
    @State private var showingClearConfirmation = false
    @State private var showingMigrationAlert = false
    @State private var migrationMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                storageSection
                managementSection
                validationSection
                helpSection
            }
            .navigationTitle("Photo Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadStorageInfo()
            }
            .alert("Photo Migration", isPresented: $showingMigrationAlert) {
                Button("OK") { }
            } message: {
                Text(migrationMessage)
            }
            .alert("Clear All Photos", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllPhotosAction()
                }
            } message: {
                Text("This will permanently delete all photos and thumbnails. This cannot be undone.")
            }
        }
    }
    
    // MARK: - View Sections
    
    private var storageSection: some View {
        Section {
            if let info = storageInfo {
                VStack(spacing: 12) {
                    // Storage overview
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Storage Used")
                                .font(.headline)
                            Text(info.formattedTotalSize)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Photo Count")
                                .font(.headline)
                            Text("\(info.photoCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    // Detailed breakdown
                    VStack(spacing: 8) {
                        HStack {
                            Label("Original Photos", systemImage: "photo")
                            Spacer()
                            Text(info.formattedOriginalSize)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Thumbnails", systemImage: "photo.stack")
                            Spacer()
                            Text(info.formattedThumbnailSize)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Thumbnail Count", systemImage: "rectangle.grid.3x2")
                            Spacer()
                            Text("\(info.thumbnailCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        if info.compressionRatio > 0 {
                            HStack {
                                Label("Storage Saved", systemImage: "arrow.down.circle.fill")
                                Spacer()
                                Text(info.compressionPercentage)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack {
                    if isCalculatingStorage {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Calculating storage usage...")
                    } else {
                        Image(systemName: "externaldrive")
                            .foregroundColor(.gray)
                        Text("Tap to calculate storage")
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    loadStorageInfo()
                }
            }
            
            Button("Refresh Storage Info") {
                loadStorageInfo()
            }
            .disabled(isCalculatingStorage)
        } header: {
            Label("Photo Storage", systemImage: "externaldrive")
        } footer: {
            Text("Photos are automatically compressed and thumbnails are generated for optimal performance and storage efficiency.")
        }
    }
    
    private var managementSection: some View {
        Section {
            Button {
                migratePhotos()
            } label: {
                HStack {
                    Label("Optimize Existing Photos", systemImage: "arrow.clockwise")
                    Spacer()
                    if isMigrating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(isMigrating)
            
            Button {
                validatePhotos()
            } label: {
                HStack {
                    Label("Validate Photo Integrity", systemImage: "checkmark.shield")
                    Spacer()
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(isValidating)
            
            Button {
                cleanupOrphanedPhotos()
            } label: {
                Label("Clean Up Orphaned Photos", systemImage: "trash.circle")
            }
            
            Button {
                showingClearConfirmation = true
            } label: {
                Label("Clear All Photos", systemImage: "trash.fill")
                    .foregroundColor(.red)
            }
        } header: {
            Label("Photo Management", systemImage: "gear")
        } footer: {
            Text("Optimize existing photos to use compression. Validate checks for missing or orphaned photo files.")
        }
    }
    
    @ViewBuilder
    private var validationSection: some View {
        if let report = validationReport {
            Section {
                HStack {
                    Label("Valid Photos", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(report.validPhotos.count)")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                if !report.missingPhotos.isEmpty {
                    HStack {
                        Label("Missing Photos", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Text("\(report.missingPhotos.count)")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                    
                    // Show first few missing photos
                    ForEach(Array(report.missingPhotos.prefix(3).enumerated()), id: \.offset) { index, missing in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Missing: \(missing.entityName)")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Type: \(missing.entityType)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 28)
                    }
                    
                    if report.missingPhotos.count > 3 {
                        Text("...and \(report.missingPhotos.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                    }
                }
                
                if !report.orphanedPhotos.isEmpty {
                    HStack {
                        Label("Orphaned Photos", systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(report.orphanedPhotos.count)")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    
                    Button("Clean Up Orphaned Photos") {
                        cleanupOrphanedPhotos()
                    }
                    .font(.caption)
                    .padding(.leading, 28)
                }
                
                // Overall status
                HStack {
                    Image(systemName: report.hasIssues ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(report.hasIssues ? .orange : .green)
                    
                    Text(report.hasIssues ? "Issues Found" : "All Photos Valid")
                        .fontWeight(.medium)
                        .foregroundColor(report.hasIssues ? .orange : .green)
                    
                    Spacer()
                }
            } header: {
                Label("Validation Results", systemImage: "magnifyingglass")
            } footer: {
                if report.hasIssues {
                    Text("Missing photos indicate items/containers reference photos that no longer exist. Orphaned photos are files not referenced by any items/containers.")
                } else {
                    Text("All photos are properly linked and accessible.")
                }
            }
        }
    }
    
    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Compression")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Photos are automatically compressed when saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "photo.stack")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Thumbnails")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Multiple sizes generated for optimal performance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "paintbrush.pointed")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Photo Icons")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Photos automatically replace generic icons in lists")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Performance")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Smart caching keeps the app fast and responsive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("Photo Features", systemImage: "info.circle")
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadStorageInfo() {
        isCalculatingStorage = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let info = PhotoManager.shared.getDetailedStorageInfo()
            
            DispatchQueue.main.async {
                storageInfo = info
                isCalculatingStorage = false
            }
        }
    }
    
    private func migratePhotos() {
        isMigrating = true
        
        Task {
            await PhotoMigrationUtility.migrateExistingPhotos(modelContext: modelContext)
            
            await MainActor.run {
                isMigrating = false
                migrationMessage = "Photo migration completed successfully! All photos have been optimized for storage and performance."
                showingMigrationAlert = true
                loadStorageInfo()
            }
        }
    }
    
    private func validatePhotos() {
        isValidating = true
        
        Task {
            let report = await PhotoMigrationUtility.validatePhotoIntegrity(modelContext: modelContext)
            
            await MainActor.run {
                validationReport = report
                isValidating = false
            }
        }
    }
    
    private func cleanupOrphanedPhotos() {
        Task {
            do {
                // Get all valid photo identifiers
                let itemDescriptor = FetchDescriptor<Item>()
                let allItems = try modelContext.fetch(itemDescriptor)
                let itemPhotos = Set(allItems.compactMap { $0.photoIdentifier })
                
                let containerDescriptor = FetchDescriptor<Container>()
                let allContainers = try modelContext.fetch(containerDescriptor)
                let containerPhotos = Set(allContainers.compactMap { $0.photoIdentifier })
                
                let validIdentifiers = itemPhotos.union(containerPhotos)
                
                // Clean up orphaned photos using PhotoManager method
                PhotoManager.shared.cleanupOrphanedPhotos(validIdentifiers: validIdentifiers)
                
                await MainActor.run {
                    loadStorageInfo()
                    validatePhotos() // Refresh validation report
                }
                
            } catch {
                print("Error during cleanup: \(error)")
            }
        }
    }
    
    private func clearAllPhotosAction() {
        // Clear all photos using PhotoManager method
        PhotoManager.shared.clearAllPhotos()
        
        // Clear photo references from database
        do {
            let itemDescriptor = FetchDescriptor<Item>()
            let allItems = try modelContext.fetch(itemDescriptor)
            for item in allItems {
                item.photoIdentifier = nil
            }
            
            let containerDescriptor = FetchDescriptor<Container>()
            let allContainers = try modelContext.fetch(containerDescriptor)
            for container in allContainers {
                container.photoIdentifier = nil
            }
            
            try modelContext.save()
            
            // Refresh UI
            storageInfo = nil
            validationReport = nil
            loadStorageInfo()
            
        } catch {
            print("Error clearing photo references: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
    
    return NavigationStack {
        PhotoSettingsView()
            .modelContainer(container)
    }
}
