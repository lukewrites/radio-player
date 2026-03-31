import SwiftUI
import RadioPlayer

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Radio Player")
                .font(.largeTitle)
                .navigationTitle("Radio Player")
        }
    }
}

#Preview {
    ContentView()
}
