import Foundation
import Security

enum ClaudeAccount: String, CaseIterable, Identifiable {
    case personal
    case work

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .work: return "Laboral"
        }
    }

    var callsign: String {
        switch self {
        case .personal: return "UNIDAD-01 · PERSONAL"
        case .work: return "UNIDAD-02 · BETTERBITES"
        }
    }

    var iconName: String {
        switch self {
        case .personal: return "house.fill"
        case .work: return "briefcase.fill"
        }
    }
}

/// Guarda y lee los tokens de `claude setup-token` en el Keychain de macOS usando
/// Security.framework directamente (SecItemAdd/SecItemCopyMatching), nunca vía
/// shell-out a `security`, para que el token no pase por argumentos de proceso.
enum KeychainStore {
    private static let service = "cl.fsoto.claude-account-switcher"

    private static func query(for account: ClaudeAccount) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
        ]
    }

    static func save(token: String, for account: ClaudeAccount) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        var attributes = query(for: account)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        // Si ya existe, actualiza el valor en vez de fallar con errSecDuplicateItem.
        let updateStatus = SecItemUpdate(
            query(for: account) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        if updateStatus == errSecItemNotFound {
            attributes[kSecValueData as String] = data
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            return addStatus == errSecSuccess
        }

        return updateStatus == errSecSuccess
    }

    static func load(for account: ClaudeAccount) -> String? {
        var query = query(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }

        return token
    }

    static func delete(for account: ClaudeAccount) {
        SecItemDelete(query(for: account) as CFDictionary)
    }

    static func hasToken(for account: ClaudeAccount) -> Bool {
        load(for: account) != nil
    }
}
