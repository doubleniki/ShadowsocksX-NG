//
//  PreferencesWinController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 2017/3/11.
//  Copyright © 2017年 qiuyuzhou. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift

class PreferencesWinController: NSWindowController {

    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var tabView: NSTabView!

    /// Configures the window after loading by selecting the "general" toolbar item, making the window resizable, enforcing a minimum size of 500×400, and ensuring the window width is at least 600 to accommodate toolbar items.
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "general")

        // Make window resizable
        if let window = window {
            var styleMask = window.styleMask
            styleMask.insert(.resizable)
            window.styleMask = styleMask

            // Set minimum window size to ensure usability
            window.minSize = NSSize(width: 500, height: 400)

            // Increase default window width to display all toolbar items
            var frame = window.frame
            if frame.size.width < 600 {
                frame.size.width = 600
                window.setFrame(frame, display: true)
            }
        }
    }

    /// Called when the window is about to close and posts the `NOTIFY_CONF_CHANGED` notification.
    /// - Parameter notification: The `Notification` delivered by the system for the window close event.
    @objc func windowWillClose(_ notification: Notification) {
        NotificationCenter.default
            .post(name: NOTIFY_CONF_CHANGED, object: nil)
    }

    /// Selects the tab whose identifier matches the provided toolbar item's identifier.
    /// - Parameter sender: The toolbar item whose `itemIdentifier` is used to select the corresponding tab.
    @IBAction func toolbarAction(sender: NSToolbarItem) {
        tabView.selectTabViewItem(withIdentifier: sender.itemIdentifier)
    }

    /// Clears the saved proxy exception list from user defaults.
    /// - Parameter sender: The button that triggered this action.
    @IBAction func resetProxyExceptions(sender: NSButton) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "ProxyExceptions")
    }

    /// Presents a confirmation alert to reset all application preferences to their defaults and, if confirmed, triggers the preferences reset.
    /// - Parameters:
    ///   - sender: The button that initiated the action.
    @IBAction func resetAllPreferences(sender: NSButton) {
        let alert = NSAlert.init()
        alert.alertStyle = .warning;
        alert.messageText = "Are you sure you want to reset the preferences to defaults?".localized
        alert.informativeText = "All your changes of preferences will be lost.".localized
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            self.resetUserDefaults()
        }
    }

    /// Resets the application's user defaults while preserving server profile data.
    /// 
    /// Removes the app's persistent domain from UserDefaults, then restores the
    /// values for the "ServerProfiles" and "ActiveServerProfileId" keys so server
    /// profile configuration is retained. If the app bundle identifier cannot be
    /// obtained, a warning is logged and no changes are made.
    func resetUserDefaults() {
        guard let domain = Bundle.main.bundleIdentifier else {
            ErrorHandler.shared.warning("Failed to get bundle identifier")
            return
        }
        let defaults = UserDefaults.standard

        // Don't reset server profiles, restore them later.
        let profiles = defaults.array(forKey: "ServerProfiles")
        let activeProfileId = defaults.string(forKey: "ActiveServerProfileId")

        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        // Restore server profiles.
        defaults.set(profiles, forKey: "ServerProfiles")
        defaults.set(activeProfileId, forKey: "ActiveServerProfileId")
        defaults.synchronize()
    }
}