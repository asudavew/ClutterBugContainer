import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @EnvironmentObject var hierarchyManager: HierarchyManager
    @Environment(\.modelContext) private var modelContext

    @State private var currentPage = 0
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let totalPages = 5

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPage1View()
                    .tag(0)
                
                OnboardingPage2View()
                    .environmentObject(hierarchyManager)
                    .tag(1)
                
                OnboardingPage3View()
                    .tag(2)
                
                OnboardingPage4View()
                    .tag(3)
                
                OnboardingPage5View(isOnboardingComplete: $isOnboardingComplete)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            
            HStack {
                Button("Previous") {
                    withAnimation(.easeInOut) {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    }
                }
                .opacity(currentPage > 0 ? 1 : 0)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                if currentPage < totalPages - 1 {
                    Button("Next") {
                        withAnimation(.easeInOut) {
                            currentPage += 1
                        }
                    }
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            setupOnboarding()
        }
        .alert("Setup Issue", isPresented: $showingError) {
            Button("OK") { }
            Button("Try Again") { setupOnboarding() }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func setupOnboarding() {
        print("🎯 Setting up onboarding...")
        
        do {
            // Ensure hierarchy manager has default configurations
            hierarchyManager.createDefaultIfNeeded()
            
            // Validate that we have configurations
            let configs = hierarchyManager.getAllConfigurations()
            if configs.isEmpty {
                throw OnboardingError.noConfigurations
            }
            
            // Ensure we have an active configuration
            if hierarchyManager.activeConfiguration == nil {
                if let defaultConfig = configs.first(where: { $0.isDefault }) {
                    hierarchyManager.switchToConfiguration(defaultConfig)
                } else if let firstConfig = configs.first {
                    hierarchyManager.switchToConfiguration(firstConfig)
                } else {
                    throw OnboardingError.noActiveConfiguration
                }
            }
            
            print("✅ Onboarding setup complete")
            print("   - Configurations: \(configs.count)")
            print("   - Active: \(hierarchyManager.activeConfiguration?.name ?? "None")")
            
        } catch {
            print("❌ Onboarding setup failed: \(error)")
            errorMessage = "Failed to set up organization styles. Please try again."
            showingError = true
        }
    }
    
    private func completeOnboarding() {
        print("🎉 Completing onboarding...")
        
        // Final validation before completing
        guard hierarchyManager.activeConfiguration != nil else {
            errorMessage = "Please select an organization style before continuing."
            showingError = true
            currentPage = 1 // Go back to hierarchy selection
            return
        }
        
        // Mark onboarding as complete
        isOnboardingComplete = true
        print("✅ Onboarding completed successfully!")
    }
}

// MARK: - Onboarding Error Types
enum OnboardingError: LocalizedError {
    case noConfigurations
    case noActiveConfiguration
    
    var errorDescription: String? {
        switch self {
        case .noConfigurations:
            return "No hierarchy configurations found"
        case .noActiveConfiguration:
            return "No active configuration set"
        }
    }
}

// MARK: - Preview
#Preview {
    struct OnboardingPreviewContainer: View {
        @State private var isComplete = false
        
        var body: some View {
            let resultView: AnyView
            
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(
                    for: Container.self, Item.self, HierarchyConfiguration.self, HierarchyLevel.self,
                    configurations: config
                )
                let hierarchyManager = HierarchyManager.safeInitialize(modelContext: container.mainContext)
                
                resultView = AnyView(
                    OnboardingView(isOnboardingComplete: $isComplete)
                        .environmentObject(hierarchyManager)
                        .modelContainer(container)
                )
            } catch {
                resultView = AnyView(Text("Preview failed: \(error.localizedDescription)"))
            }
            
            return resultView
        }
    }
    
    return OnboardingPreviewContainer()
}
