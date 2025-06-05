import SwiftUI
import SwiftData

// MARK: - Safe Map View (No Freeze)
struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    @State private var currentContainer: Container?
    @State private var showingContainerPicker = false
    @State private var isLoading = true
    @State private var containers: [Container] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading Map...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Container selection header
                    containerSelectionHeader
                    
                    // Map content based on current container
                    if let container = currentContainer {
                        SafeMapContentView(container: container)
                            .environmentObject(hierarchyManager)
                    } else {
                        emptyMapState
                    }
                }
            }
        }
        .navigationTitle("Map View")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingContainerPicker = true
                }) {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingContainerPicker) {
            SafeContainerPickerView(
                containers: containers,
                selectedContainer: $currentContainer,
                onDismiss: { showingContainerPicker = false }
            )
            .environmentObject(hierarchyManager)
        }
        .onAppear {
            loadContainersAsync()
        }
    }
    
    // MARK: - Async Loading (Prevents Freeze)
    
    private func loadContainersAsync() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            // Perform heavy work off main thread
            let fetchedContainers = await fetchTopLevelContainers()
            
            await MainActor.run {
                self.containers = fetchedContainers
                
                if currentContainer == nil && !containers.isEmpty {
                    currentContainer = containers.first
                }
                
                isLoading = false
                print("📍 Map loaded with \(containers.count) top-level containers")
            }
        }
    }
    
    @MainActor
    private func fetchTopLevelContainers() async -> [Container] {
        do {
            let predicate = #Predicate<Container> { container in
                container.parentContainer == nil
            }
            let descriptor = FetchDescriptor<Container>(predicate: predicate)
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Error fetching containers for map: \(error)")
            return []
        }
    }
    
    // MARK: - View Components
    
    private var containerSelectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let container = currentContainer {
                    Text(container.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(container.safeDynamicType(using: hierarchyManager).displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let purpose = container.purpose {
                        Text(purpose)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No Container Selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingContainerPicker = true
            }) {
                Text("Change")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var emptyMapState: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Select a Container to Map")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose a container to view and manage its layout.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if !containers.isEmpty {
                Button(action: {
                    showingContainerPicker = true
                }) {
                    Text("Select Container")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 12) {
                    Text("No containers found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Create containers first in the Containers tab")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Safe Map Content View
struct SafeMapContentView: View {
    let container: Container
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    var body: some View {
        VStack {
            // Simple map placeholder for now
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue.opacity(0.6))
                            
                            Text("Map View for \(container.name)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Interactive map coming soon!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Show container stats
                            VStack(spacing: 8) {
                                if let childCount = container.childContainers?.count, childCount > 0 {
                                    Text("\(childCount) child containers")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                }
                                
                                if container.totalItemCount > 0 {
                                    Text("\(container.totalItemCount) total items")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Container actions
            HStack(spacing: 16) {
                Button(action: {
                    print("📍 View container details: \(container.name)")
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Details")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    print("📍 Edit container: \(container.name)")
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Safe Container Picker View
struct SafeContainerPickerView: View {
    let containers: [Container]
    @Binding var selectedContainer: Container?
    let onDismiss: () -> Void
    
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    var body: some View {
        NavigationStack {
            List {
                if containers.isEmpty {
                    ContentUnavailableView(
                        "No Containers",
                        systemImage: "building.2",
                        description: Text("Create your first container to get started with mapping")
                    )
                } else {
                    ForEach(containers, id: \.id) { container in
                        SafeContainerPickerRow(
                            container: container,
                            isSelected: selectedContainer?.id == container.id,
                            onSelect: {
                                selectedContainer = container
                                onDismiss()
                            }
                        )
                        .environmentObject(hierarchyManager)
                    }
                }
            }
            .navigationTitle("Select Container to Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Cancel")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct SafeContainerPickerRow: View {
    let container: Container
    let isSelected: Bool
    let onSelect: () -> Void
    
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                PhotoOrIcon(
                    photoIdentifier: container.photoIdentifier,
                    fallbackIcon: container.safeDynamicType(using: hierarchyManager).icon,
                    fallbackColor: container.colorTypeEnum?.color ?? .blue,
                    size: .medium
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(container.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(container.safeDynamicType(using: hierarchyManager).displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let purpose = container.purpose {
                        Text(purpose)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Show child container count
                    let childCount = container.childContainers?.count ?? 0
                    if childCount > 0 {
                        let nextLevel = container.levelNumber + 1
                        let nextLevelName = hierarchyManager.levelPluralName(for: nextLevel)
                        Text("\(childCount) \(nextLevelName.lowercased())")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager.safeInitialize(modelContext: container.mainContext)
        
        let sampleContainer = Container.createBuilding(name: "Sample Workshop")
        container.mainContext.insert(sampleContainer)
        
        return NavigationStack {
            MapView()
                .environmentObject(hierarchyManager)
                .modelContainer(container)
        }
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
