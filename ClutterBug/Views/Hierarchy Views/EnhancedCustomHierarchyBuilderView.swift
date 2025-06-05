import SwiftUI
import SwiftData

struct EnhancedCustomHierarchyBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var hierarchyName: String = ""
    @State private var numberOfLevels: Int = 3
    @State private var levels: [CustomLevel] = []
    @State private var showingPreview = false
    @State private var currentStep = 1
    
    // Available icons organized by category
    private let iconCategories: [IconCategory] = [
        IconCategory(name: "Buildings & Spaces", icons: [
            "building.2.fill", "house.fill", "door.left.hand.open", "rectangle.fill",
            "square.grid.3x3.fill", "building.fill"
        ]),
        IconCategory(name: "Storage & Containers", icons: [
            "shippingbox.fill", "archivebox.fill", "tray.fill", "cabinet.fill",
            "tray.2.fill", "square.stack.3d.up.fill"
        ]),
        IconCategory(name: "Organization", icons: [
            "folder.fill", "doc.fill", "tag.fill", "bookmark.fill",
            "flag.fill", "star.fill"
        ]),
        IconCategory(name: "Tools & Equipment", icons: [
            "wrench.fill", "hammer.fill", "screwdriver.fill", "gear",
            "desktopcomputer", "printer.fill"
        ])
    ]
    
    private let availableColors = PlacedShape.ShapeColor.allCases
    
    private var canSave: Bool {
        !hierarchyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        levels.count == numberOfLevels &&
        levels.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private var progress: Double {
        Double(currentStep) / 3.0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
            
            // Step indicator
            HStack {
                ForEach(1...3, id: \.self) { step in
                    HStack {
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        if step < 3 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Main content
            TabView(selection: $currentStep) {
                step1NameAndLevels.tag(1)
                step2DefineEachLevel.tag(2)
                step3ReviewAndSave.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                if currentStep > 1 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button("Next") {
                        withAnimation {
                            if currentStep == 1 {
                                setupLevelsForCount()
                            }
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceedFromCurrentStep())
                } else {
                    Button("Create My Hierarchy") {
                        saveCustomHierarchy()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .padding()
        }
        .navigationTitle("Create Custom Organization")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Preview") {
                    showingPreview = true
                }
                .disabled(levels.isEmpty)
            }
        }
        .sheet(isPresented: $showingPreview) {
            NavigationStack {
                HierarchyPreviewView(hierarchyName: hierarchyName, levels: levels)
            }
        }
        .onAppear {
            setupDefaultName()
        }
    }
    
    // MARK: - Step 1: Name and Level Count
    
    private var step1NameAndLevels: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step 1: Basic Setup")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Give your organization style a name and choose how many levels you need.")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Organization Name")
                            .font(.headline)
                        TextField("e.g., My Workshop, Home Storage, Office Setup", text: $hierarchyName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Number of Levels")
                            .font(.headline)
                        
                        Text("How many levels do you need? Each level contains the next level down.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Level selection with visual examples
                        VStack(spacing: 12) {
                            ForEach(2...6, id: \.self) { count in
                                LevelCountOption(
                                    count: count,
                                    isSelected: numberOfLevels == count,
                                    onSelect: { numberOfLevels = count }
                                )
                            }
                        }
                    }
                }
                
                // Example hierarchy
                if numberOfLevels > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Hierarchy Will Look Like:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(1...numberOfLevels, id: \.self) { level in
                                HStack {
                                    ForEach(0..<(level-1), id: \.self) { _ in
                                        Text("  ")
                                    }
                                    Text("• Level \(level)")
                                        .foregroundColor(level == numberOfLevels ? .green : .primary)
                                    if level == numberOfLevels {
                                        Text("(Items stored here)")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Define Each Level
    
    private var step2DefineEachLevel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step 2: Name Your Levels")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Give each level a name, icon, and color that makes sense for your organization.")
                        .foregroundColor(.secondary)
                }
                
                LazyVStack(spacing: 20) {
                    ForEach(levels.indices, id: \.self) { index in
                        EnhancedLevelBuilderRow(
                            level: $levels[index],
                            levelNumber: index + 1,
                            isLastLevel: index == numberOfLevels - 1,
                            iconCategories: iconCategories,
                            availableColors: availableColors
                        )
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Step 3: Review and Save
    
    private var step3ReviewAndSave: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Step 3: Review & Create")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Review your custom organization style before creating it.")
                        .foregroundColor(.secondary)
                }
                
                // Summary card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hierarchyName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("\(numberOfLevels) levels")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    Text("Your Levels:")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 12)
                    ], spacing: 12) {
                        ForEach(levels.indices, id: \.self) { index in
                            let level = levels[index]
                            HStack(spacing: 8) {
                                Image(systemName: level.icon)
                                    .foregroundColor(level.colorEnum?.color ?? .gray)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Level \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(level.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(level.colorEnum?.color.opacity(0.1) ?? Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example Path:")
                            .font(.headline)
                        Text(examplePath)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            return !hierarchyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && numberOfLevels >= 2
        case 2:
            return levels.count == numberOfLevels && levels.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case 3:
            return canSave
        default:
            return false
        }
    }
    
    private func setupDefaultName() {
        if hierarchyName.isEmpty {
            hierarchyName = "My Custom Organization"
        }
    }
    
    private func setupLevelsForCount() {
        let defaultNames = ["Location", "Area", "Zone", "Container", "Section", "Shelf", "Compartment", "Drawer"]
        let defaultIcons = ["building.2.fill", "rectangle.fill", "square.grid.3x3.fill", "shippingbox.fill", "tray.fill", "archivebox.fill", "tray.2.fill", "folder.fill"]
        let defaultColors = ["blue", "green", "orange", "purple", "red", "blue", "green", "orange"]
        
        levels = []
        for i in 0..<numberOfLevels {
            let name = i < defaultNames.count ? defaultNames[i] : "Level \(i + 1)"
            let icon = i < defaultIcons.count ? defaultIcons[i] : "square.fill"
            let color = i < defaultColors.count ? defaultColors[i] : "blue"
            let unit = i < 2 ? "ft" : "in"
            
            levels.append(CustomLevel(name: name, icon: icon, color: color, dimensionUnit: unit))
        }
    }
    
    private var examplePath: String {
        levels.map { $0.name }.joined(separator: " → ") + " → Your Items"
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
            
            // Switch to the new configuration
            hierarchyManager.switchToConfiguration(config)
            
            dismiss()
        } catch {
            print("❌ Error saving custom hierarchy: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct LevelCountOption: View {
    let count: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count) Levels")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(getDescription(for: count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getDescription(for count: Int) -> String {
        switch count {
        case 2: return "Simple: Location → Storage (perfect for small spaces)"
        case 3: return "Basic: Location → Container → Section (good for home use)"
        case 4: return "Detailed: Building → Room → Furniture → Storage (comprehensive home)"
        case 5: return "Advanced: Building → Room → Area → Unit → Detail (workshop/garage)"
        case 6: return "Professional: Maximum detail for complex organizations"
        default: return "Custom organization with \(count) levels"
        }
    }
}

struct EnhancedLevelBuilderRow: View {
    @Binding var level: CustomLevel
    let levelNumber: Int
    let isLastLevel: Bool
    let iconCategories: [IconCategory]
    let availableColors: [PlacedShape.ShapeColor]
    
    @State private var showingIconPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(level.colorEnum?.color ?? .blue)
                    .frame(width: 8, height: 8)
                
                Text("Level \(levelNumber)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if levelNumber == 1 {
                    Text("Top Level")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                } else if isLastLevel {
                    Text("Items stored here")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }
            
            TextField("Level Name (e.g., Workshop, Cabinet, Shelf)", text: $level.name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
            
            HStack(spacing: 12) {
                // Icon Picker
                Button(action: { showingIconPicker = true }) {
                    HStack {
                        Image(systemName: level.icon)
                            .foregroundColor(level.colorEnum?.color ?? .gray)
                            .font(.title2)
                        Text("Choose Icon")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Color Picker
                Menu {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: { level.color = color.rawValue }) {
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                Text(color.displayName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(level.colorEnum?.color ?? .gray)
                            .frame(width: 20, height: 20)
                        Text("Color")
                            .font(.subheadline)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Dimension Unit
            Picker("Default Unit", selection: $level.dimensionUnit) {
                Text("Feet (ft)").tag("ft")
                Text("Inches (in)").tag("in")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .sheet(isPresented: $showingIconPicker) {
            CategorizedIconPickerView(selectedIcon: $level.icon, iconCategories: iconCategories)
        }
    }
}

struct IconCategory {
    let name: String
    let icons: [String]
}

struct CategorizedIconPickerView: View {
    @Binding var selectedIcon: String
    let iconCategories: [IconCategory]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(iconCategories, id: \.name) { category in
                    Section(category.name) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(category.icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                    dismiss()
                                }) {
                                    VStack {
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                            .frame(width: 40, height: 40)
                                            .background(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                            .clipShape(Circle())
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
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
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
        let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
        
        return NavigationStack {
            EnhancedCustomHierarchyBuilderView()
                .environmentObject(hierarchyManager)
                .modelContainer(container)
        }
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
