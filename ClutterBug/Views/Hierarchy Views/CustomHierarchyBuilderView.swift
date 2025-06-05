import SwiftUI
import SwiftData

struct CustomHierarchyBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var hierarchyName: String = ""
    @State private var numberOfLevels: Int = 3
    @State private var levels: [CustomLevel] = []
    @State private var showingPreview = false
    
    // Available icons for users to choose from
    private let availableIcons = [
        "building.2.fill", "house.fill", "door.left.hand.open", "rectangle.fill",
        "shippingbox.fill", "archivebox.fill", "tray.fill", "cabinet.fill",
        "bed.double.fill", "square.stack.3d.up.fill", "tray.2.fill",
        "desktopcomputer", "square.grid.3x3.fill", "arrow.left.arrow.right",
        "square.dashed", "square.fill", "circle.fill", "triangle.fill"
    ]
    
    private let availableColors = PlacedShape.ShapeColor.allCases
    
    private var canSave: Bool {
        !hierarchyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        levels.count == numberOfLevels &&
        levels.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    var body: some View {
        Form {
            basicInfoSection
            levelsSection
            previewSection
        }
        .navigationTitle("Create Custom Style")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveCustomHierarchy() }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            setupDefaultLevels()
        }
        .onChange(of: numberOfLevels) { oldValue, newValue in
            adjustLevelsForCount(newValue)
        }
        .sheet(isPresented: $showingPreview) {
            NavigationStack {
                HierarchyPreviewView(hierarchyName: hierarchyName, levels: levels)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var basicInfoSection: some View {
        Section("Style Details") {
            TextField("Name (e.g., My Workshop Setup)", text: $hierarchyName)
            
            Picker("Number of Levels", selection: $numberOfLevels) {
                ForEach(2...6, id: \.self) { count in
                    Text("\(count) Levels").tag(count)
                }
            }
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Items will be stored in Level \(numberOfLevels)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Each level can only contain the next level down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var levelsSection: some View {
        Section("Define Your Levels") {
            ForEach(levels.indices, id: \.self) { index in
                LevelBuilderRow(
                    level: $levels[index],
                    levelNumber: index + 1,
                    isLastLevel: index == numberOfLevels - 1,
                    availableIcons: availableIcons,
                    availableColors: availableColors
                )
            }
        }
    }
    
    private var previewSection: some View {
        Section("Preview") {
            if !levels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Hierarchy:")
                        .font(.headline)
                    
                    ForEach(levels.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            ForEach(0..<index, id: \.self) { _ in
                                Text("  ")
                            }
                            
                            Image(systemName: levels[index].icon)
                                .foregroundColor(levels[index].colorEnum?.color ?? .gray)
                            
                            Text("Level \(index + 1): \(levels[index].name)")
                                .font(.subheadline)
                            
                            if index == levels.count - 1 {
                                Text("(Items go here)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Text("Example: \(examplePath)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.vertical, 4)
            }
            
            Button("Preview in Action") {
                showingPreview = true
            }
            .disabled(levels.isEmpty)
        }
    }
    
    private var examplePath: String {
        levels.map { $0.name }.joined(separator: " → ") + " → Your Items"
    }
    
    // MARK: - Helper Functions
    
    private func setupDefaultLevels() {
        let defaults = [
            CustomLevel(name: "Location", icon: "building.2.fill", color: "blue", dimensionUnit: "ft"),
            CustomLevel(name: "Area", icon: "rectangle.fill", color: "green", dimensionUnit: "ft"),
            CustomLevel(name: "Container", icon: "shippingbox.fill", color: "orange", dimensionUnit: "in"),
            CustomLevel(name: "Section", icon: "tray.fill", color: "purple", dimensionUnit: "in"),
            CustomLevel(name: "Shelf", icon: "archivebox.fill", color: "red", dimensionUnit: "in"),
            CustomLevel(name: "Compartment", icon: "tray.2.fill", color: "blue", dimensionUnit: "in")
        ]
        
        levels = Array(defaults.prefix(numberOfLevels))
    }
    
    private func adjustLevelsForCount(_ count: Int) {
        if count > levels.count {
            let defaultNames = ["Location", "Area", "Container", "Section", "Shelf", "Compartment"]
            let defaultIcons = ["building.2.fill", "rectangle.fill", "shippingbox.fill", "tray.fill", "archivebox.fill", "tray.2.fill"]
            let defaultColors = ["blue", "green", "orange", "purple", "red", "blue"]
            
            for i in levels.count..<count {
                let name = i < defaultNames.count ? defaultNames[i] : "Level \(i + 1)"
                let icon = i < defaultIcons.count ? defaultIcons[i] : "square.fill"
                let color = i < defaultColors.count ? defaultColors[i] : "gray"
                let unit = i < 2 ? "ft" : "in"
                
                levels.append(CustomLevel(name: name, icon: icon, color: color, dimensionUnit: unit))
            }
        } else if count < levels.count {
            levels = Array(levels.prefix(count))
        }
    }
    
    private func saveCustomHierarchy() {
        let config = HierarchyConfiguration(
            name: hierarchyName,
            maxLevels: numberOfLevels
        )
        
        config.levels = levels.enumerated().map { index, customLevel in
            let level = HierarchyLevel(
                order: index + 1,
                name: customLevel.name,
                pluralName: customLevel.pluralName,
                icon: customLevel.icon,
                color: customLevel.color,
                defaultDimensionUnit: customLevel.dimensionUnit
            )
            level.configuration = config
            return level
        }
        
        modelContext.insert(config)
        
        do {
            try modelContext.save()
            print("✅ Custom hierarchy '\(hierarchyName)' saved with \(numberOfLevels) levels")
            dismiss()
        } catch {
            print("❌ Error saving custom hierarchy: \(error)")
        }
    }
}

// MARK: - Custom Level Model (for building)
struct CustomLevel {
    var name: String
    var icon: String
    var color: String
    var dimensionUnit: String
    
    var pluralName: String {
        // Simple pluralization
        if name.hasSuffix("y") && name.count > 2 {
            return String(name.dropLast()) + "ies"
        } else if name.hasSuffix("s") || name.hasSuffix("sh") || name.hasSuffix("ch") {
            return name + "es"
        } else {
            return name + "s"
        }
    }
    
    var colorEnum: PlacedShape.ShapeColor? {
        PlacedShape.ShapeColor(rawValue: color)
    }
}

// MARK: - Level Builder Row
struct LevelBuilderRow: View {
    @Binding var level: CustomLevel
    let levelNumber: Int
    let isLastLevel: Bool
    let availableIcons: [String]
    let availableColors: [PlacedShape.ShapeColor]
    
    @State private var showingIconPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Level \(levelNumber)")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                if levelNumber == 1 {
                    Text("Top Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if isLastLevel {
                    Text("Items stored here")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            TextField("Level Name (e.g., Workshop, Cabinet, Shelf)", text: $level.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                // Icon Picker
                Button(action: { showingIconPicker = true }) {
                    HStack {
                        Image(systemName: level.icon)
                            .foregroundColor(level.colorEnum?.color ?? .gray)
                            .font(.title2)
                        Text("Icon")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Color Picker
                Picker("Color", selection: $level.color) {
                    ForEach(availableColors, id: \.self) { color in
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 16, height: 16)
                            Text(color.displayName)
                        }
                        .tag(color.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 120)
            }
            
            // Dimension Unit
            Picker("Default Unit", selection: $level.dimensionUnit) {
                Text("Feet (ft)").tag("ft")
                Text("Inches (in)").tag("in")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $level.icon, availableIcons: availableIcons)
        }
    }
}

// MARK: - Icon Picker View
struct IconPickerView: View {
    @Binding var selectedIcon: String
    let availableIcons: [String]
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                    .clipShape(Circle())
                                
                                Text(iconName(icon))
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func iconName(_ icon: String) -> String {
        return icon.replacingOccurrences(of: ".fill", with: "")
                    .replacingOccurrences(of: ".", with: " ")
                    .capitalized
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
        
        return CustomHierarchyBuilderView()
            .environmentObject(hierarchyManager)
            .modelContainer(container)
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
