//
//  ProxyCoordinator.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2
//

import Foundation

/// Manages proxy configuration and mode switching
class ProxyCoordinator {
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

        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")

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
        let defaults = UserDefaults.standard
        defaults.setValue(mode.rawValue, forKey: "ShadowsocksRunningMode")
    }

    func switchToNextEnabledMode() -> ProxyMode? {
        let defaults = UserDefaults.standard
        guard let currentMode = defaults.string(forKey: "ShadowsocksRunningMode") else {
            return nil
        }

        let enabledModeList = buildEnabledModeList(from: defaults)

        guard !enabledModeList.isEmpty else {
            return nil
        }

        let nextModeString = determineNextMode(
            current: currentMode,
            from: enabledModeList
        )

        defaults.setValue(nextModeString, forKey: "ShadowsocksRunningMode")

        return ProxyMode(rawValue: nextModeString)
    }

    // MARK: - Private Helpers

    private func buildEnabledModeList(from defaults: UserDefaults) -> [String] {
        var enabledModeList: [String] = []

        if defaults.bool(forKey: "EnableSwitchMode.PAC") {
            enabledModeList.append("auto")
        }
        if defaults.bool(forKey: "EnableSwitchMode.Global") {
            enabledModeList.append("global")
        }
        if defaults.bool(forKey: "EnableSwitchMode.Manual") {
            enabledModeList.append("manual")
        }
        if defaults.bool(forKey: "EnableSwitchMode.ExternalPAC"),
           let externalPACURL = defaults.string(forKey: "ExternalPACURL"),
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
        let defaults = UserDefaults.standard
        var isOn = defaults.bool(forKey: "ShadowsocksOn")
        isOn.toggle()
        defaults.set(isOn, forKey: "ShadowsocksOn")
        return isOn
    }

    private func syncSSLocal() {
        // This is a global function from existing codebase
        ShadowsocksX_NG.syncSSLocal()
    }
}
