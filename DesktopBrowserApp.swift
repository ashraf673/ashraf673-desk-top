import SwiftUI

@main
struct DesktopBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(nil) // Respect system dark/light mode
        }
    }
}
