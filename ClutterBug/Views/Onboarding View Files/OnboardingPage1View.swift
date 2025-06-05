
import SwiftUI

struct OnboardingPage1View: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "questionmark.circle.fill") // Placeholder for a confused/lost graphic
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.orange) // Example color
            
            Text("Lost me? Where am I?!")
                .font(.largeTitle) // Apply custom font later
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Welcome to ClutterBug! \nReady to conquer your workshop chaos?")
                .font(.title2) // Apply custom font later
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 100) // Push content down a bit
        .padding()
    }
}

#Preview {
    OnboardingPage1View()
}
