import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private let serviceName = "com.doctorapp.auth"

    enum KeychainKey: String {
        case accessToken = "accessToken"
        case refreshToken = "refreshToken"
        case userEmail = "userEmail"
        case userId = "userId"
    }

    // MARK: - Save to Keychain
    func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing value
        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve from Keychain
    func get(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    // MARK: - Delete from Keychain
    func delete(for key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear all authentication data
    func clearAll() {
        delete(for: .accessToken)
        delete(for: .refreshToken)
        delete(for: .userEmail)
        delete(for: .userId)
    }

    // MARK: - Check if user is logged in
    var isUserLoggedIn: Bool {
        return get(for: .accessToken) != nil
    }

    // MARK: - Save tokens
    func saveTokens(_ tokens: AuthTokens) {
        _ = save(tokens.accessToken, for: .accessToken)
        _ = save(tokens.refreshToken, for: .refreshToken)
    }

    // MARK: - Get tokens
    func getTokens() -> (access: String?, refresh: String?) {
        return (get(for: .accessToken), get(for: .refreshToken))
    }
}
