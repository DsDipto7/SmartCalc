import SwiftUI

struct AuthView: View {
    
    @State private var currentViewShowing: String = "login"
    var body: some View {
        
        if(currentViewShowing == "login"){
            LoginView(currentShowingView: $currentViewShowing)
        }
        else {
            SignupView(currentShowingView: $currentViewShowing)
        }
    }
}

#Preview {
    AuthView()
}
