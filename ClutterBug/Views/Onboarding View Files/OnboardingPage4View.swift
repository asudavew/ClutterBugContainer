import SwiftUI

struct OnboardingPage4View: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "map.fill") // Placeholder for map graphic
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.purple)

            Text("Where Did I Put That...?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Visualize your space with a 2D floorplan. Find your gear at a glance!")
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
    OnboardingPage4View()
}
