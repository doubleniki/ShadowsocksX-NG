//
//  DependencyContainer.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2.3
//

import Cocoa

/// Simple dependency container that centralizes service singletons and factory helpers.
class DependencyContainer {
    // MARK: - Shared Instance

    static let shared = DependencyContainer()

    // MARK: - Services

    let preferences: PreferencesManaging
    let profileManager: ServerProfileManaging
    let keychain: KeychainManaging
    let launchAgent: LaunchAgentManaging
    let fileSystem: FileSystemManaging

    // MARK: - Initialization

    init(
        preferences: PreferencesManaging? = nil,
        profileManager: ServerProfileManaging? = nil,
        keychain: KeychainManaging? = nil,
        launchAgent: LaunchAgentManaging? = nil,
        fileSystem: FileSystemManaging? = nil
    ) {
        self.preferences = preferences ?? UserDefaultsPreferences()
        self.profileManager = profileManager ?? ServerProfileManager.instance
        self.keychain = keychain ?? KeychainManager.shared
        self.launchAgent = launchAgent ?? LaunchAgentManager.shared
        self.fileSystem = fileSystem ?? FileSystemManager()
    }

    // MARK: - Factory Helpers

    // swiftlint:disable:next function_parameter_count
    func makeMenuBarManager(
        statusMenu: NSMenu,
        runningStatusMenuItem: NSMenuItem,
        toggleRunningMenuItem: NSMenuItem,
        autoModeMenuItem: NSMenuItem,
        globalModeMenuItem: NSMenuItem,
        manualModeMenuItem: NSMenuItem,
        externalPACModeMenuItem: NSMenuItem,
        serversMenuItem: NSMenuItem,
        serverProfilesBeginSeparatorMenuItem: NSMenuItem,
        serverProfilesEndSeparatorMenuItem: NSMenuItem,
        copyHttpProxyExportCmdLineMenuItem: NSMenuItem
    ) -> MenuBarManager {
        return MenuBarManager(
            statusMenu: statusMenu,
            runningStatusMenuItem: runningStatusMenuItem,
            toggleRunningMenuItem: toggleRunningMenuItem,
            autoModeMenuItem: autoModeMenuItem,
            globalModeMenuItem: globalModeMenuItem,
            manualModeMenuItem: manualModeMenuItem,
            externalPACModeMenuItem: externalPACModeMenuItem,
            serversMenuItem: serversMenuItem,
            serverProfilesBeginSeparatorMenuItem: serverProfilesBeginSeparatorMenuItem,
            serverProfilesEndSeparatorMenuItem: serverProfilesEndSeparatorMenuItem,
            copyHttpProxyExportCmdLineMenuItem: copyHttpProxyExportCmdLineMenuItem,
            preferences: preferences,
            profileManager: profileManager
        )
    }

    func makeProxyCoordinator() -> ProxyCoordinator {
        return ProxyCoordinator(
            preferences: preferences,
            launchAgent: launchAgent,
            profileManager: profileManager
        )
    }

    func makeWindowCoordinator() -> WindowCoordinator {
        return WindowCoordinator(profileManager: profileManager)
    }
}
