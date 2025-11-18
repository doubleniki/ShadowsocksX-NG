//
//  ProxyCoordinator.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2
//

import Foundation

/// Manages proxy configuration and mode switching
class ProxyCoordinator {
    private let preferences: PreferencesManaging
    private let launchAgent: LaunchAgentManaging
    private let profileManager: ServerProfileManaging

    init(
        preferences: PreferencesManaging,
        launchAgent: LaunchAgentManaging,
        profileManager: ServerProfileManaging
    ) {
        self.preferences = preferences
        self.launchAgent = launchAgent
        self.profileManager = profileManager
    }
    // MARK: - Proxy Modes

    enum ProxyMode: String {
        case auto
        case global
        case manual
        case externalPAC

        var localizedName: String {
            switch self {
            case .auto:
                return "Auto Mode By PAC".localized
            case .global:
                return "Global Mode".localized
            case .manual:
                return "Manual Mode".localized
            case .externalPAC:
                return "Auto Mode By External PAC".localized
            }
        }
    }

    // MARK: - Public Methods

    func applyConfig() {
        syncSSLocal()

        let isOn = preferences.bool(forKey: Constants.UserDefaults.shadowsocksOn)
        let mode = preferences.string(forKey: "ShadowsocksRunningMode")

        if isOn {
            switch mode {
            case "auto":
                ProxyConfHelper.enablePACProxy()
            case "global":
                ProxyConfHelper.enableGlobalProxy()
            case "manual":
                ProxyConfHelper.disableProxy()
            case "externalPAC":
                ProxyConfHelper.enableExternalPACProxy()
            default:
                break
            }
        } else {
            ProxyConfHelper.disableProxy()
        }
    }

    func switchMode(to mode: ProxyMode) {
        preferences.set(mode.rawValue, forKey: "ShadowsocksRunningMode")
    }

    func switchToNextEnabledMode() -> ProxyMode? {
        guard let currentMode = preferences.string(forKey: "ShadowsocksRunningMode") else {
            return nil
        }

        let enabledModeList = buildEnabledModeList()

        guard !enabledModeList.isEmpty else {
            return nil
        }

        let nextModeString = determineNextMode(
            current: currentMode,
            from: enabledModeList
        )

        preferences.set(nextModeString, forKey: "ShadowsocksRunningMode")

        return ProxyMode(rawValue: nextModeString)
    }

    // MARK: - Private Helpers

    private func buildEnabledModeList() -> [String] {
        var enabledModeList: [String] = []

        if preferences.bool(forKey: "EnableSwitchMode.PAC") {
            enabledModeList.append("auto")
        }
        if preferences.bool(forKey: "EnableSwitchMode.Global") {
            enabledModeList.append("global")
        }
        if preferences.bool(forKey: "EnableSwitchMode.Manual") {
            enabledModeList.append("manual")
        }
        if preferences.bool(forKey: "EnableSwitchMode.ExternalPAC"),
           let externalPACURL = preferences.string(forKey: "ExternalPACURL"),
           !externalPACURL.isEmpty {
            enabledModeList.append("externalPAC")
        }

        return enabledModeList
    }

    private func determineNextMode(current: String, from enabledModes: [String]) -> String {
        guard enabledModes.contains(current),
              let currentIndex = enabledModes.firstIndex(of: current) else {
            return enabledModes[0]
        }

        let nextIndex = (currentIndex + 1) % enabledModes.count
        return enabledModes[nextIndex]
    }

    func toggleShadowsocks() -> Bool {
        var isOn = preferences.bool(forKey: Constants.UserDefaults.shadowsocksOn)
        isOn.toggle()
        preferences.set(isOn, forKey: Constants.UserDefaults.shadowsocksOn)
        return isOn
    }

    private func syncSSLocal() {
        // This is a global function from existing codebase
        ShadowsocksX_NG.syncSSLocal()
    }
}
