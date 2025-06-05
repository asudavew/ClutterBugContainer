import SwiftUI

struct OnboardingPage3View: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "camera.fill.badge.ellipsis") // Placeholder for photo/measure graphic
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)

            Text("Snap, Measure, Stash!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Easily add items with photos and measurements. No more guessing dimensions!")
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 100)
        .padding()
    }
}

#Preview {
    OnboardingPage3View()
}
