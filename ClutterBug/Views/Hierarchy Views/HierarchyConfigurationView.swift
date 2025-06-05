import SwiftUI
import SwiftData

struct HierarchyConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allConfigurations: [HierarchyConfiguration]
    @State private var showingCustomBuilder = false
    @State private var showingDeleteAlert = false
    @State private var configToDelete: HierarchyConfiguration?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose how you want to organize your inventory. You can switch between different styles anytime.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } header: {
                    Text("Organization Style")
                }
                
                Section("Built-in Styles") {
                    ForEach(allConfigurations.filter { $0.isDefault }) { config in
                        HierarchyConfigRow(
                            config: config,
                            isActive: config.id == hierarchyManager.activeConfiguration?.id,
                            onSelect: {
                                hierarchyManager.switchToConfiguration(config)
                            },
                            onDelete: nil // Built-in styles cannot be deleted
                        )
                    }
                }
                
                if !customConfigurations.isEmpty {
                    Section("Your Custom Styles") {
                        ForEach(customConfigurations) { config in
                            HierarchyConfigRow(
                                config: config,
                                isActive: config.id == hierarchyManager.activeConfiguration?.id,
                                onSelect: {
                                    hierarchyManager.switchToConfiguration(config)
                                },
                                onDelete: {
                                    configToDelete = config
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                }
                
                Section {
                    Button("Create Custom Organization") {
                        showingCustomBuilder = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Organization Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCustomBuilder) {
                NavigationStack {
                    CustomHierarchyBuilderView()
                        .environmentObject(hierarchyManager)
                }
            }
            .alert("Delete Custom Style", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    configToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let config = configToDelete {
                        deleteConfiguration(config)
                    }
                    configToDelete = nil
                }
            } message: {
                if let config = configToDelete {
                    Text("Are you sure you want to delete '\(config.name)'? This cannot be undone.")
                }
            }
        }
        .onAppear {
            hierarchyManager.createDefaultIfNeeded()
        }
    }
    
    private var customConfigurations: [HierarchyConfiguration] {
        return allConfigurations.filter { !$0.isDefault }
    }
    
    private func deleteConfiguration(_ config: HierarchyConfiguration) {
        hierarchyManager.deleteConfiguration(config)
    }
}

struct HierarchyConfigRow: View {
    let config: HierarchyConfiguration
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: (() -> Void)? // Optional delete action for custom configs
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(config.name)
                        .font(.headline)
                        .foregroundColor(isActive ? .blue : .primary)
                    
                    if config.isDefault {
                        Text("BUILT-IN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                Text("\(config.maxLevels) Levels")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Show level names in a flow layout
                LevelTagsView(levels: config.sortedLevels)
            }
            
            Spacer()
            
            VStack {
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
                
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

struct LevelTagsView: View {
    let levels: [HierarchyLevel]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: 4)
        ], alignment: .leading, spacing: 4) {
            ForEach(levels, id: \.id) { level in
                HStack(spacing: 4) {
                    Image(systemName: level.icon)
                        .font(.caption2)
                    Text(level.name)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(level.colorEnum?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                .foregroundColor(level.colorEnum?.color ?? .gray)
                .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
        
        return HierarchyConfigurationView()
            .environmentObject(hierarchyManager)
            .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
