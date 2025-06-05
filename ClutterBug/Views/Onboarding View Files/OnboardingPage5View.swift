import SwiftUI

struct OnboardingPage5View: View {
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "barcode.viewfinder") // Placeholder for UPC scan graphic
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.teal)

            Text("Scan It, Sort It!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Quickly add items by scanning their UPC barcodes. So satisfying!")
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                // Action to complete onboarding
                isOnboardingComplete = true
            } label: {
                Text("Let's Get Organizing!")
                    .font(.title2) // Apply custom font later
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50) // Push button up from the very bottom
        }
        .padding(.top, 100)
        .padding()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var isComplete: Bool = false
        var body: some View {
            OnboardingPage5View(isOnboardingComplete: $isComplete)
        }
    }
    return PreviewWrapper()
}
