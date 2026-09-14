import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var lastLaunched: ClaudeAccount?
    @Published var launchErrorMessage: String?
    @Published var tokenPresence: [ClaudeAccount: Bool] = [:]

    private static let lastLaunchedKey = "lastLaunchedAccount"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.lastLaunchedKey) {
            lastLaunched = ClaudeAccount(rawValue: raw)
        }
        refreshTokenPresence()
    }

    func refreshTokenPresence() {
        for account in ClaudeAccount.allCases {
            tokenPresence[account] = KeychainStore.hasToken(for: account)
        }
    }

    func launch(_ account: ClaudeAccount) {
        guard tokenPresence[account] == true else {
            launchErrorMessage = "No hay un token guardado para \(account.displayName). Configúralo primero."
            return
        }

        do {
            try SessionLauncher.launch(account: account)
            lastLaunched = account
            UserDefaults.standard.set(account.rawValue, forKey: Self.lastLaunchedKey)
        } catch {
            launchErrorMessage = "No se pudo abrir la sesión de \(account.displayName): \(error)"
        }
    }

    func saveToken(_ token: String, for account: ClaudeAccount) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let ok = KeychainStore.save(token: trimmed, for: account)
        refreshTokenPresence()
        return ok
    }

    func clearToken(for account: ClaudeAccount) {
        KeychainStore.delete(for: account)
        refreshTokenPresence()
    }
}
