import SwiftUI
import SwiftData

struct OnboardingPage2View: View {
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @State private var selectedConfiguration: HierarchyConfiguration?
    @State private var showingCustomBuilder = false
    @State private var isLoading = false
    
    // Get all available configurations
    private var availableConfigurations: [HierarchyConfiguration] {
        hierarchyManager.getAllConfigurations()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.indent")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)

            Text("Choose Your Organization Style")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("How do you want to organize your inventory? Pick a preset or create your own custom style.")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView("Loading styles...")
                    .padding()
            } else if availableConfigurations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title)
                    
                    Text("No organization styles found")
                        .font(.headline)
                    
                    Text("This shouldn't happen. Please restart the app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Custom Builder - Make it prominent
                        VStack(spacing: 12) {
                            Text("Create Your Own")
                                .font(.headline)
                                .foregroundColor(.purple)
                            
                            Button {
                                showingCustomBuilder = true
                            } label: {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.purple)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Build Custom Hierarchy")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text("Choose your level count and name each level")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.title2)
                                            .foregroundColor(.purple)
                                    }
                                    
                                    // Feature highlights
                                    HStack(spacing: 16) {
                                        FeatureHighlight(icon: "slider.horizontal.3", text: "2-6 Levels")
                                        FeatureHighlight(icon: "textformat", text: "Custom Names")
                                        FeatureHighlight(icon: "paintbrush", text: "Pick Colors")
                                        FeatureHighlight(icon: "square.grid.3x3", text: "Choose Icons")
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.purple.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.purple, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Divider with "OR"
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        
                        // Preset configurations
                        VStack(spacing: 12) {
                            Text("Choose a Preset")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(availableConfigurations.prefix(4), id: \.id) { config in
                                OnboardingHierarchyOption(
                                    config: config,
                                    isSelected: selectedConfiguration?.id == config.id,
                                    onSelect: {
                                        selectedConfiguration = config
                                        hierarchyManager.switchToConfiguration(config)
                                        print("✅ Selected configuration: \(config.name)")
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if let selected = selectedConfiguration {
                VStack(spacing: 8) {
                    Text("✅ Selected: \(selected.name)")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("You can change this anytime in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal)
        .sheet(isPresented: $showingCustomBuilder) {
            NavigationStack {
                EnhancedCustomHierarchyBuilderView()
                    .environmentObject(hierarchyManager)
            }
        }
        .onAppear {
            setupPage()
        }
        .onChange(of: availableConfigurations.count) { oldValue, newValue in
            // If configurations were added (e.g., from custom builder), update selection
            if newValue > oldValue {
                updateSelectionIfNeeded()
            }
        }
    }
    
    private func setupPage() {
        print("📄 Setting up Page 2 (Hierarchy Selection)")
        isLoading = true
        
        // Ensure configurations are loaded
        hierarchyManager.createDefaultIfNeeded()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            updateSelectionIfNeeded()
        }
    }
    
    private func updateSelectionIfNeeded() {
        // Set initial selection to active configuration or first default
        if selectedConfiguration == nil {
            if let active = hierarchyManager.activeConfiguration {
                selectedConfiguration = active
                print("🎯 Using active configuration: \(active.name)")
            } else if let defaultConfig = availableConfigurations.first(where: { $0.isDefault }) {
                selectedConfiguration = defaultConfig
                hierarchyManager.switchToConfiguration(defaultConfig)
                print("🎯 Using default configuration: \(defaultConfig.name)")
            } else if let firstConfig = availableConfigurations.first {
                selectedConfiguration = firstConfig
                hierarchyManager.switchToConfiguration(firstConfig)
                print("🎯 Using first available configuration: \(firstConfig.name)")
            }
        }
    }
}

// MARK: - Feature Highlight View
struct FeatureHighlight: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.purple)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Updated Hierarchy Option (Cleaner Design)
struct OnboardingHierarchyOption: View {
    let config: HierarchyConfiguration
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(config.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(config.maxLevels) levels")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    } else {
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
                
                // Show level progression with icons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(config.sortedLevels, id: \.id) { level in
                            HStack(spacing: 4) {
                                Image(systemName: level.icon)
                                    .font(.caption)
                                    .foregroundColor(level.colorEnum?.color ?? .gray)
                                Text(level.name)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(level.colorEnum?.color.opacity(0.1) ?? Color.gray.opacity(0.1))
                            .foregroundColor(level.colorEnum?.color ?? .gray)
                            .clipShape(Capsule())
                            
                            if level.order < config.maxLevels {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                
                // Description based on config
                Text(getDescription(for: config))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(16)
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
    
    private func getDescription(for config: HierarchyConfiguration) -> String {
        switch config.name {
        case let name where name.contains("Workshop"):
            return "Perfect for workshops, garages, and maker spaces with detailed organization"
        case let name where name.contains("Simple"):
            return "Great for basic organization - easy to set up and maintain"
        case let name where name.contains("Home"):
            return "Ideal for organizing household items, furniture, and personal belongings"
        case let name where name.contains("Warehouse"):
            return "Professional organization for businesses and large inventories"
        case let name where name.contains("Office"):
            return "Streamlined organization for office spaces and work environments"
        default:
            return "Custom organization style with \(config.maxLevels) levels of hierarchy"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self, configurations: config)
    let hierarchyManager = HierarchyManager(modelContext: container.mainContext)
    
    return OnboardingPage2View()
        .environmentObject(hierarchyManager)
}
