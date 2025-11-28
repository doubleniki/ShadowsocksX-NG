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

        // Add vibrancy effect to window (Phase 3 UI modernization)
        setupWindowVibrancy()
    }

    // MARK: - Vibrancy Effects (Phase 3 UI Modernization)

    /// Setup vibrancy effect for the entire preferences window
    /// Provides subtle background depth similar to System Settings
    private func setupWindowVibrancy() {
        guard let window = self.window,
              let contentView = window.contentView else {
            return
        }

        // Create visual effect view for content area
        let visualEffectView = NSVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.material = .contentBackground  // Content background material
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active

        // Insert behind existing content
        let existingSubviews = contentView.subviews
        if let firstSubview = existingSubviews.first {
            contentView.addSubview(visualEffectView, positioned: .below, relativeTo: firstSubview)
        } else {
            contentView.addSubview(visualEffectView)
        }

        // Pin visual effect view to content view edges
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Configure window for vibrancy
        window.backgroundColor = .clear
    }

    @objc func windowWillClose(_ notification: Notification) {
        NotificationCenter.default
            .post(name: Constants.Notification.configChanged, object: nil)
    }

    @IBAction func toolbarAction(sender: NSToolbarItem) {
        tabView.selectTabViewItem(withIdentifier: sender.itemIdentifier)
    }

    @IBAction func resetProxyExceptions(sender: NSButton) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "ProxyExceptions")
    }

    @IBAction func resetAllPreferences(sender: NSButton) {
        let alert = NSAlert.init()
        alert.alertStyle = .warning
        alert.messageText = "Are you sure you want to reset the preferences to defaults?".localized
        alert.informativeText = "All your changes of preferences will be lost.".localized
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            self.resetUserDefaults()
        }
    }

    func resetUserDefaults() {
        guard let domain = Bundle.main.bundleIdentifier else {
            ErrorHandler.shared.warning("Failed to get bundle identifier")
            showResetFailureAlert()
            return
        }
        let defaults = UserDefaults.standard

        // Don't reset server profiles, restore them later.
        let profiles = defaults.array(forKey: Constants.UserDefaults.serverProfiles)
        let activeProfileId = defaults.string(forKey: Constants.UserDefaults.activeServerProfileId)

        defaults.removePersistentDomain(forName: domain)

        // Restore server profiles.
        defaults.set(profiles, forKey: Constants.UserDefaults.serverProfiles)
        defaults.set(activeProfileId, forKey: Constants.UserDefaults.activeServerProfileId)

        showResetSuccessAlert()
    }

    private func showResetFailureAlert() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Failed to Reset Preferences".localized
        alert.informativeText =
            "Unable to reset preferences due to a system error. Please try restarting the application."
            .localized
        alert.addButton(withTitle: "OK".localized)
        alert.runModal()
    }

    private func showResetSuccessAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Preferences Reset Successfully".localized
        alert.informativeText =
            "Your preferences have been reset to defaults. Server profiles have been preserved."
            .localized
        alert.addButton(withTitle: "OK".localized)
        alert.runModal()
    }
}
