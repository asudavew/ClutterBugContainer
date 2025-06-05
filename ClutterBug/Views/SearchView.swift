import Foundation
import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .padding()
            Text("Search")
                .font(.largeTitle)
            Text("Find your treasures! (Coming Soon)")
                .font(.title3)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .navigationTitle("Search Inventory")
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
