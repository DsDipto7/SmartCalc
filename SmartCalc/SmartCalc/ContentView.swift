import SwiftUI

struct ContentView: View {
    
    @AppStorage("uid") var userID: String = ""
    
    var body: some View {
        
        if userID == "" {
            AuthView()
        }
        else {
            CalculatorView()
        }
    }
}

#Preview {
    ContentView()
}
