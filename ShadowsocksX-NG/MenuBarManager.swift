//
//  MenuBarManager.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2
//

import Cocoa

/// Manages the status bar item and menu updates
class MenuBarManager {
    // MARK: - Properties

    private(set) var statusItem: NSStatusItem
    private let statusMenu: NSMenu

    // Menu items
    private let runningStatusMenuItem: NSMenuItem
    private let toggleRunningMenuItem: NSMenuItem
    private let autoModeMenuItem: NSMenuItem
    private let globalModeMenuItem: NSMenuItem
    private let manualModeMenuItem: NSMenuItem
    private let externalPACModeMenuItem: NSMenuItem
    private let serversMenuItem: NSMenuItem
    private let serverProfilesBeginSeparatorMenuItem: NSMenuItem
    private let serverProfilesEndSeparatorMenuItem: NSMenuItem
    private let copyHttpProxyExportCmdLineMenuItem: NSMenuItem

    private let kProfileMenuItemIndexBase = 100
    static let StatusItemIconWidth: CGFloat = NSStatusItem.variableLength

    // MARK: - Initialization

    init(
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
    ) {
        self.statusMenu = statusMenu
        self.runningStatusMenuItem = runningStatusMenuItem
        self.toggleRunningMenuItem = toggleRunningMenuItem
        self.autoModeMenuItem = autoModeMenuItem
        self.globalModeMenuItem = globalModeMenuItem
        self.manualModeMenuItem = manualModeMenuItem
        self.externalPACModeMenuItem = externalPACModeMenuItem
        self.serversMenuItem = serversMenuItem
        self.serverProfilesBeginSeparatorMenuItem = serverProfilesBeginSeparatorMenuItem
        self.serverProfilesEndSeparatorMenuItem = serverProfilesEndSeparatorMenuItem
        self.copyHttpProxyExportCmdLineMenuItem = copyHttpProxyExportCmdLineMenuItem

        // Create status item
        self.statusItem = NSStatusBar.system.statusItem(withLength: MenuBarManager.StatusItemIconWidth)

        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        guard let image = NSImage(named: "menu_icon") else {
            ErrorHandler.shared.warning("menu_icon image not found")
            return
        }
        image.isTemplate = true
        statusItem.button?.image = image
        statusItem.menu = statusMenu
    }

    // MARK: - Menu Updates

    func updateRunningModeMenu() {
        let defaults = UserDefaults.standard

        // Update external PAC menu item availability
        if let pacURL = defaults.string(forKey: "ExternalPACURL") {
            externalPACModeMenuItem.isEnabled = !pacURL.isEmpty
        }

        // Reset all mode states
        autoModeMenuItem.state = .off
        globalModeMenuItem.state = .off
        manualModeMenuItem.state = .off
        externalPACModeMenuItem.state = .off

        // Set current mode
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        switch mode {
        case "auto":
            autoModeMenuItem.state = .on
        case "global":
            globalModeMenuItem.state = .on
        case "manual":
            manualModeMenuItem.state = .on
        case "externalPAC":
            externalPACModeMenuItem.state = .on
        default:
            break
        }

        updateStatusMenuImage()
        updateSelectedServerName()
    }

    func updateStatusMenuImage() {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        let isOn = defaults.bool(forKey: "ShadowsocksOn")

        if isOn {
            if let currentMode = mode {
                switch currentMode {
                case "auto":
                    statusItem.button?.image = NSImage(named: "menu_p_icon")
                case "global":
                    statusItem.button?.image = NSImage(named: "menu_g_icon")
                case "manual":
                    statusItem.button?.image = NSImage(named: "menu_m_icon")
                case "externalPAC":
                    statusItem.button?.image = NSImage(named: "menu_e_icon")
                default:
                    break
                }
                statusItem.button?.image?.isTemplate = true
            }
        } else {
            statusItem.button?.image = NSImage(named: "menu_icon_disabled")
            statusItem.button?.image?.isTemplate = true
        }
    }

    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")

        if isOn {
            runningStatusMenuItem.title = "Shadowsocks: On".localized
            runningStatusMenuItem.image = NSImage(named: "NSStatusAvailable")
            toggleRunningMenuItem.title = "Turn Shadowsocks Off".localized
            let image = NSImage(named: "menu_icon")
            statusItem.button?.image = image
        } else {
            runningStatusMenuItem.title = "Shadowsocks: Off".localized
            toggleRunningMenuItem.title = "Turn Shadowsocks On".localized
            runningStatusMenuItem.image = NSImage(named: "NSStatusNone")
            let image = NSImage(named: "menu_icon_disabled")
            statusItem.button?.image = image
        }
        statusItem.button?.image?.isTemplate = true

        updateStatusMenuImage()
    }

    func updateCopyHttpProxyExportMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "LocalHTTPOn")
        copyHttpProxyExportCmdLineMenuItem.isHidden = !isOn
    }

    func updateServersMenu() {
        guard let menu = serversMenuItem.submenu else { return }

        let mgr = ServerProfileManager.instance
        let profiles = mgr.profiles

        // Remove all profile menu items
        let beginIndex = menu.index(of: serverProfilesBeginSeparatorMenuItem) + 1
        let endIndex = menu.index(of: serverProfilesEndSeparatorMenuItem)

        // Remove from end to begin, so the index won't change
        for index in (beginIndex..<endIndex).reversed() {
            menu.removeItem(at: index)
        }

        // Insert all profile menu items
        for (i, profile) in profiles.enumerated().reversed() {
            let item = NSMenuItem()
            item.tag = i + kProfileMenuItemIndexBase
            item.title = profile.title()
            item.state = (mgr.activeProfileId == profile.uuid) ? .on : .off
            item.isEnabled = profile.isValid()

            // Use number keys for faster switch between the first 10 servers from main menu
            if i < 10 {
                var key = i + 1
                if key == 10 {
                    key = 0
                }
                item.keyEquivalent = String(key)
                item.keyEquivalentModifierMask = .init()
            }
            item.action = #selector(AppDelegate.selectServer)

            menu.insertItem(item, at: beginIndex)
        }

        // End separator is redundant if profile section is empty
        serverProfilesEndSeparatorMenuItem.isHidden = profiles.isEmpty
    }

    // MARK: - Private Helpers

    private func updateSelectedServerName() {
        var serverMenuText = "Servers - (No Selected)".localized

        let mgr = ServerProfileManager.instance
        for profile in mgr.profiles where mgr.activeProfileId == profile.uuid {
            var profileName: String
            if !profile.remark.isEmpty {
                profileName = String(profile.remark.prefix(24))
            } else {
                profileName = profile.serverHost
            }
            serverMenuText = "Servers".localized + " - \(profileName)"
            break
        }
        serversMenuItem.title = serverMenuText
    }
}
