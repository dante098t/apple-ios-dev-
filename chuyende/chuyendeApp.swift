import SwiftUI
import FirebaseCore


@main
struct ChuyendeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authVM = AuthViewModel()
    @StateObject var productVM = ProductViewModel()
    @StateObject var cartVM = CartViewModel()

    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(productVM)
                .environmentObject(cartVM)
        }
    }
}
