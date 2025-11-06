//
//  KeychainManager.swift
//  ShadowsocksX-NG
//
//  Secure password storage using macOS Keychain
//
import Cocoa
import Foundation
import Security

class KeychainManager {

    static let shared = KeychainManager()

    private let service = "com.qiuyuzhou.ShadowsocksX-NG"

    private init() {}

    // MARK: - Save Password

    /// Saves a password to Keychain for a given account (server UUID)
    /// - Parameters:
    ///   - password: The password to save
    ///   - account: The account identifier (server UUID)
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func savePassword(_ password: String, forAccount account: String) -> Bool {
        guard let passwordData = password.data(using: .utf8) else {
            ErrorHandler.shared.warning(
                "Failed to convert password to data", context: "KeychainManager")
            return false
        }

        // First, try to delete any existing entry
        deletePassword(forAccount: account)

        // Create new keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            ErrorHandler.shared.debug(
                "Successfully saved password for account: \(account)", context: "KeychainManager")
            return true
        } else {
            ErrorHandler.shared.warning(
                "Failed to save password. Status: \(status)", context: "KeychainManager")
            return false
        }
    }

    // MARK: - Retrieve Password

    /// Retrieves a password from Keychain for a given account
    /// - Parameter account: The account identifier (server UUID)
    /// - Returns: The password string, or nil if not found
    func getPassword(forAccount account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            if let passwordData = result as? Data,
                let password = String(data: passwordData, encoding: .utf8)
            {
                return password
            }
        } else if status == errSecItemNotFound {
            ErrorHandler.shared.debug(
                "Password not found for account: \(account)", context: "KeychainManager")
        } else {
            ErrorHandler.shared.warning(
                "Failed to retrieve password. Status: \(status)", context: "KeychainManager")
        }

        return nil
    }

    // MARK: - Update Password

    /// Updates an existing password in Keychain
    /// - Parameters:
    ///   - password: The new password
    ///   - account: The account identifier (server UUID)
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func updatePassword(_ password: String, forAccount account: String) -> Bool {
        guard let passwordData = password.data(using: .utf8) else {
            ErrorHandler.shared.warning(
                "Failed to convert password to data", context: "KeychainManager")
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecSuccess {
            ErrorHandler.shared.debug(
                "Successfully updated password for account: \(account)", context: "KeychainManager")
            return true
        } else if status == errSecItemNotFound {
            // If item doesn't exist, create it
            ErrorHandler.shared.debug(
                "Password not found, creating new entry", context: "KeychainManager")
            return savePassword(password, forAccount: account)
        } else {
            ErrorHandler.shared.warning(
                "Failed to update password. Status: \(status)", context: "KeychainManager")
            return false
        }
    }

    // MARK: - Delete Password

    /// Deletes a password from Keychain
    /// - Parameter account: The account identifier (server UUID)
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func deletePassword(forAccount account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            if status == errSecSuccess {
                ErrorHandler.shared.debug(
                    "Successfully deleted password for account: \(account)",
                    context: "KeychainManager")
            }
            return true
        } else {
            ErrorHandler.shared.warning(
                "Failed to delete password. Status: \(status)", context: "KeychainManager")
            return false
        }
    }

    // MARK: - Migration Helper

    /// Migrates a password from UserDefaults to Keychain
    /// - Parameters:
    ///   - password: The password from UserDefaults
    ///   - account: The account identifier (server UUID)
    /// - Returns: True if migration successful
    @discardableResult
    func migratePassword(_ password: String, forAccount account: String) -> Bool {
        // Only migrate if password is not empty
        guard !password.isEmpty else {
            return false
        }

        // Check if password already exists in Keychain
        if getPassword(forAccount: account) != nil {
            ErrorHandler.shared.debug(
                "Password already exists in Keychain for account: \(account)",
                context: "KeychainManager")
            return true
        }

        // Save to Keychain
        return savePassword(password, forAccount: account)
    }

    // MARK: - Diagnostics

    /// Check if Keychain is accessible
    /// - Returns: True if Keychain is accessible
    func isKeychainAccessible() -> Bool {
        let testAccount = "keychain.test.\(UUID().uuidString)"
        let testPassword = "test"

        // Try to save
        guard savePassword(testPassword, forAccount: testAccount) else {
            return false
        }

        // Try to retrieve
        guard let retrieved = getPassword(forAccount: testAccount),
            retrieved == testPassword
        else {
            deletePassword(forAccount: testAccount)
            return false
        }

        // Cleanup
        deletePassword(forAccount: testAccount)
        return true
    }
}
