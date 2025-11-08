//
//  MenuBarManager.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2
//

import Cocoa

/// Delegate protocol for MenuBarManager to communicate menu actions
protocol MenuBarManagerDelegate: AnyObject {
    /// Called when user selects a server from the menu
    /// - Parameters:
    ///   - manager: The MenuBarManager instance
    ///   - index: The index of selected server in profiles array
    func menuBarManager(_ manager: MenuBarManager, didSelectServerAt index: Int)
}

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

    weak var delegate: MenuBarManagerDelegate?

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
                let iconName: String
                switch currentMode {
                case "auto":
                    iconName = "menu_p_icon"
                case "global":
                    iconName = "menu_g_icon"
                case "manual":
                    iconName = "menu_m_icon"
                case "externalPAC":
                    iconName = "menu_e_icon"
                default:
                    iconName = "menu_icon"
                }

                if let image = loadIconWithFallback(named: iconName) {
                    statusItem.button?.image = image
                    statusItem.button?.image?.isTemplate = true
                }
            }
        } else {
            if let image = loadIconWithFallback(named: "menu_icon_disabled") {
                statusItem.button?.image = image
                statusItem.button?.image?.isTemplate = true
            }
        }
    }

    private func loadIconWithFallback(named name: String, fallback: String = "menu_icon_disabled") -> NSImage? {
        if let image = NSImage(named: name) {
            return image
        } else {
            ErrorHandler.shared.warning(
                "Missing status bar icon asset: \(name), using fallback: \(fallback)",
                context: "MenuBarManager"
            )
            return NSImage(named: fallback)
        }
    }

    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")

        if isOn {
            runningStatusMenuItem.title = "Shadowsocks: On".localized
            runningStatusMenuItem.image = NSImage(named: "NSStatusAvailable")
            toggleRunningMenuItem.title = "Turn Shadowsocks Off".localized
        } else {
            runningStatusMenuItem.title = "Shadowsocks: Off".localized
            toggleRunningMenuItem.title = "Turn Shadowsocks On".localized
            runningStatusMenuItem.image = NSImage(named: "NSStatusNone")
        }

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
            item.target = self
            item.action = #selector(handleServerSelection(_:))

            menu.insertItem(item, at: beginIndex)
        }

        // End separator is redundant if profile section is empty
        serverProfilesEndSeparatorMenuItem.isHidden = profiles.isEmpty
    }

    @objc private func handleServerSelection(_ sender: NSMenuItem) {
        let index = sender.tag - kProfileMenuItemIndexBase
        delegate?.menuBarManager(self, didSelectServerAt: index)
    }

    // MARK: - Private Helpers

    private func updateSelectedServerName() {
        var serverMenuText = "Servers - (No Selected)".localized

        let mgr = ServerProfileManager.instance
        for profile in mgr.profiles where mgr.activeProfileId == profile.uuid {
            // Use profile.title() directly - it already handles truncation correctly
            let profileName = profile.title()
            serverMenuText = "Servers".localized + " - \(profileName)"
            break
        }
        serversMenuItem.title = serverMenuText
    }
}
