import SwiftUI
import SwiftData

struct ContainerListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var hierarchyManager: HierarchyManager
    
    @Query private var allContainers: [Container]
    @State private var currentContainer: Container?
    @State private var showingAddContainer = false
    @State private var showingEditContainer = false
    @State private var containerToEdit: Container?
    @State private var showingDeleteAlert = false
    @State private var containerToDelete: Container?
    @State private var searchText = ""
    
    // Get top-level containers (no parent)
    private var topLevelContainers: [Container] {
        allContainers.filter { $0.parentContainer == nil }
    }
    
    // Get child containers of current container
    private var currentChildContainers: [Container] {
        currentContainer?.childContainers?.sorted { $0.name < $1.name } ?? []
    }
    
    // Get items in current container (only if it can hold items)
    private var currentItems: [Item] {
        guard let container = currentContainer,
              hierarchyManager.isLastLevel(container.levelNumber) else {
            return []
        }
        return container.items?.sorted { $0.name < $1.name } ?? []
    }
    
    // Filter containers based on search
    private var filteredContainers: [Container] {
        let containers = currentContainer == nil ? topLevelContainers : currentChildContainers
        
        if searchText.isEmpty {
            return containers
        } else {
            return containers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Filter items based on search
    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return currentItems
        } else {
            return currentItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                if !allContainers.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search containers and items...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Breadcrumb navigation
                if currentContainer != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("🏠 Top") {
                                withAnimation {
                                    currentContainer = nil
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            ForEach(currentContainer?.hierarchyPath ?? [], id: \.id) { container in
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button(container.name) {
                                        withAnimation {
                                            currentContainer = container
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                
                // Main content
                if allContainers.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
        }
        .navigationTitle(currentContainer?.name ?? "Containers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if currentContainer != nil {
                    Button("Back") {
                        withAnimation {
                            currentContainer = currentContainer?.parentContainer
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add", systemImage: "plus") {
                    showingAddContainer = true
                }
                .disabled(!canAddContainers)
            }
        }
        .sheet(isPresented: $showingAddContainer) {
            NavigationStack {
                AddContainerView(
                    parentContainer: currentContainer,
                    targetLevel: (currentContainer?.levelNumber ?? 0) + 1
                )
                .environmentObject(hierarchyManager)
            }
        }
        .sheet(isPresented: $showingEditContainer) {
            if let container = containerToEdit {
                NavigationStack {
                    EditContainerView(container: container)
                        .environmentObject(hierarchyManager)
                }
            }
        }
        .alert("Delete Container", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                containerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let container = containerToDelete {
                    deleteContainer(container)
                }
                containerToDelete = nil
            }
        } message: {
            if let container = containerToDelete {
                Text("Are you sure you want to delete '\(container.name)' and all its contents? This cannot be undone.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("No Containers Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start organizing by creating your first container")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Container") {
                showingAddContainer = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainContentView: some View {
        List {
            // Show containers
            if !filteredContainers.isEmpty {
                Section {
                    ForEach(filteredContainers, id: \.id) { container in
                        EditableContainerRow(
                            container: container,
                            onTap: {
                                withAnimation {
                                    currentContainer = container
                                }
                            },
                            onDelete: {
                                containerToDelete = container
                                showingDeleteAlert = true
                            }
                        )
                        .environmentObject(hierarchyManager)
                    }
                } header: {
                    if currentContainer == nil {
                        Text("Top Level")
                    } else {
                        let nextLevel = (currentContainer?.levelNumber ?? 0) + 1
                        Text(hierarchyManager.levelPluralName(for: nextLevel))
                    }
                }
            }
            
            // Show items (only for containers that can hold items)
            if !filteredItems.isEmpty {
                Section {
                    ForEach(filteredItems, id: \.id) { item in
                        EditableItemRow(item: item)
                    }
                } header: {
                    Text("Items")
                }
            }
            
            // Add item section (only for containers that can hold items)
            if let container = currentContainer, hierarchyManager.isLastLevel(container.levelNumber) {
                Section {
                    NavigationLink(destination: AddItemView(targetContainer: container).environmentObject(hierarchyManager)) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Item to \(container.name)")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            // Refresh action - could add data sync here
        }
    }
    
    // MARK: - Computed Properties
    
    private var canAddContainers: Bool {
        if let container = currentContainer {
            return container.levelNumber < hierarchyManager.maxLevels()
        } else {
            return true // Can always add top-level containers
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteContainer(_ container: Container) {
        // Delete photo if exists
        if let photoId = container.photoIdentifier {
            PhotoManager.shared.deleteImage(identifier: photoId)
        }
        
        // Remove from current selection if needed
        if currentContainer?.id == container.id {
            currentContainer = container.parentContainer
        }
        
        // Delete from model
        modelContext.delete(container)
        
        do {
            try modelContext.save()
            print("✅ Container '\(container.name)' deleted successfully")
        } catch {
            print("❌ Error deleting container: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager.safeInitialize(modelContext: container.mainContext)
        
        // Create some sample data
        let workshop = Container.createBuilding(name: "Sample Workshop")
        container.mainContext.insert(workshop)
        
        let toolArea = Container.createDynamic(
            name: "Tool Area",
            level: 2,
            parentContainer: workshop,
            hierarchyManager: hierarchyManager
        )
        if let toolArea = toolArea {
            container.mainContext.insert(toolArea)
        }
        
        return NavigationStack {
            ContainerListView()
                .environmentObject(hierarchyManager)
                .modelContainer(container)
        }
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
