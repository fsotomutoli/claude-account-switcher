import SwiftUI

@main
struct ClaudeAccountSwitcherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Claude Switcher", systemImage: "person.2.badge.key.fill") {
            TacticalMenuView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Window("Configurar cuentas de Claude", id: "setup") {
            SetupView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
    }
}
