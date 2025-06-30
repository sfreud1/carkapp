import SwiftUI
import FirebaseCore
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct carkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Sürekli bağlantı ve spin için yöneticiler
    @StateObject private var peer = PeerManager.shared
    @StateObject private var spin = SpinCoordinator()
    @State private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                WheelSpinView(userName: "", profileImageURL: nil)
                    .environmentObject(peer)
                    .environmentObject(spin)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
                    .environmentObject(peer)
                    .environmentObject(spin)
            }
        }
    }
}
