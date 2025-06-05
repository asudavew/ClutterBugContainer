import SwiftUI

struct UPCScanView: View {
    var body: some View {
        VStack {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .padding()
            Text("UPC Scan")
                .font(.largeTitle)
            Text("Scan it, sort it! (Coming Soon)")
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .navigationTitle("Scan Barcode")
    }
}

#Preview {
    NavigationStack {
        UPCScanView()
    }
}
