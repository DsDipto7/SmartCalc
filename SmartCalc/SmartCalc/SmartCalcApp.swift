import SwiftUI
import FirebaseCore

@main
struct SmartCalcApp: App {
    
    init () {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
