//
//  AppDelegate.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa
import Carbon
import RxCocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    var shareWinCtrl: ShareServerProfilesWindowController!
    var qrcodeWinCtrl: SWBQRCodeWindowController!
    var preferencesWinCtrl: PreferencesWindowController!
    var editUserRulesWinCtrl: UserRulesController!
    var allInOnePreferencesWinCtrl: PreferencesWinController!
    var toastWindowCtrl: ToastWindowController!
    var importWinCtrl: ImportWindowController!

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var runningStatusMenuItem: NSMenuItem!
    @IBOutlet weak var toggleRunningMenuItem: NSMenuItem!
    @IBOutlet weak var autoModeMenuItem: NSMenuItem!
    @IBOutlet weak var globalModeMenuItem: NSMenuItem!
    @IBOutlet weak var manualModeMenuItem: NSMenuItem!
    @IBOutlet weak var externalPACModeMenuItem: NSMenuItem!

    @IBOutlet weak var serversMenuItem: NSMenuItem!
    @IBOutlet var showQRCodeMenuItem: NSMenuItem!
    @IBOutlet var scanQRCodeMenuItem: NSMenuItem!
    @IBOutlet var serverProfilesBeginSeparatorMenuItem: NSMenuItem!
    @IBOutlet var serverProfilesEndSeparatorMenuItem: NSMenuItem!

    @IBOutlet weak var copyHttpProxyExportCmdLineMenuItem: NSMenuItem!

    @IBOutlet weak var lanchAtLoginMenuItem: NSMenuItem!

    @IBOutlet weak var hudWindow: NSPanel!
    @IBOutlet weak var panelView: NSView!
    @IBOutlet weak var isNameTextField: NSTextField!

    let kProfileMenuItemIndexBase = 100

    var statusItem: NSStatusItem!
    static let StatusItemIconWidth: CGFloat = NSStatusItem.variableLength

    /// Ensures the LaunchAgents directory in the user's Library is owned by the current user.
    /// 
    /// If ~/Library/LaunchAgents exists and its owner differs from the current user, attempts to run the bundled `fix_dir_owner.sh` script with administrator privileges via AppleScript to change ownership. Logs warnings if the directory owner cannot be determined or the script is missing; forwards filesystem or execution errors to `ErrorHandler`.
    func ensureLaunchAgentsDirOwner () {
        let dirPath = NSHomeDirectory() + "/Library/LaunchAgents"
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: dirPath) {
            do {
                let attrs = try fileMgr.attributesOfItem(atPath: dirPath)

                // Safe unwrap of owner name
                guard let owner = attrs[FileAttributeKey.ownerAccountName] as? String else {
                    ErrorHandler.shared.warning("Could not determine directory owner for \(dirPath)")
                    return
                }

                if owner != NSUserName() {
                    // Safe unwrap of script path
                    guard let bashFilePath = Bundle.main.path(forResource: "fix_dir_owner.sh", ofType: nil) else {
                        ErrorHandler.shared.warning("fix_dir_owner.sh script not found in bundle")
                        return
                    }

                    let script = "do shell script \"bash \\\"\(bashFilePath)\\\" \(NSUserName()) \" with administrator privileges"
                    if let appleScript = NSAppleScript(source: script) {
                        var err: NSDictionary? = nil
                        appleScript.executeAndReturnError(&err)
                        if let error = err {
                            ErrorHandler.shared.warning("AppleScript error: \(error)")
                        }
                    }
                }
            }
            catch {
                ErrorHandler.shared.handle(
                    error,
                    context: "Ensure LaunchAgents Directory Owner",
                    showAlert: false
                )
            }
        }
    }

    /// Perform global initialization for the application at launch.
    /// 
    /// Sets up launch-on-login, ensures LaunchAgents ownership, installs required helper binaries and proxy helpers, registers user defaults, configures the status bar item and menus, registers runtime notification observers and URL handling, applies the current proxy configuration, and binds global shortcuts.
    /// - Parameter aNotification: The notification sent by the system when the application has finished launching.
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        _ = LaunchAtLoginController()// Ensure set when launch

        NSUserNotificationCenter.default.delegate = self

        self.ensureLaunchAgentsDirOwner()

        // Prepare ss-local
        installSSLocal()
        installPrivoxy()
        installSimpleObfs()
        installKcptun()
        installV2rayPlugin()

        // Prepare defaults
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "ShadowsocksOn": true,
            "ShadowsocksRunningMode": "auto",
            "LocalSocks5.ListenPort": NSNumber(value: 1086 as UInt16),
            "LocalSocks5.ListenAddress": "127.0.0.1",
            "PacServer.BindToLocalhost": NSNumber(value: true as Bool),
            "PacServer.ListenPort":NSNumber(value: 1089 as UInt16),
            "LocalSocks5.Timeout": NSNumber(value: 60 as UInt),
            "LocalSocks5.EnableUDPRelay": NSNumber(value: false as Bool),
            "LocalSocks5.EnableVerboseMode": NSNumber(value: false as Bool),
            "GFWListURL": "https://cdn.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt",
            "AutoConfigureNetworkServices": NSNumber(value: true as Bool),
            "LocalHTTP.ListenAddress": "127.0.0.1",
            "LocalHTTP.ListenPort": NSNumber(value: 1087 as UInt16),
            "LocalHTTPOn": true,
            "LocalHTTP.FollowGlobal": false,
            "ProxyExceptions": "127.0.0.1, localhost, 192.168.0.0/16, 10.0.0.0/8, FE80::/64, ::1, FD00::/8",
            "ExternalPACURL": "",
            "EnableSwitchMode.PAC": true,
            "EnableSwitchMode.Global": true,
            "EnableSwitchMode.Manual": false,
            "EnableSwitchMode.ExternalPAC": false,
            ])

        statusItem = NSStatusBar.system.statusItem(withLength: AppDelegate.StatusItemIconWidth)
        guard let image = NSImage(named: "menu_icon") else {
            ErrorHandler.shared.warning("menu_icon image not found")
            return
        }
        image.isTemplate = true
        statusItem.image = image
        statusItem.menu = statusMenu

        let notifyCenter = NotificationCenter.default

        _ = notifyCenter.rx.notification(NOTIFY_CONF_CHANGED)
            .subscribe(onNext: { noti in
                self.applyConfig()
                self.updateRunningModeMenu()
                self.updateCopyHttpProxyExportMenu()
            })

        notifyCenter.addObserver(forName: NOTIFY_SERVER_PROFILES_CHANGED, object: nil, queue: nil
            , using: {
                (note) in
                let profileMgr = ServerProfileManager.instance
                if profileMgr.activeProfileId == nil &&
                    profileMgr.profiles.count > 0{
                    if profileMgr.profiles[0].isValid(){
                        profileMgr.setActiveProfiledId(profileMgr.profiles[0].uuid)
                    }
                }
                self.updateServersMenu()
                self.updateRunningModeMenu()
                syncSSLocal()
            }
        )
        _ = notifyCenter.rx.notification(NOTIFY_TOGGLE_RUNNING_SHORTCUT)
            .subscribe(onNext: { noti in
                self.doToggleRunning(showToast: true)
            })
        _ = notifyCenter.rx.notification(NOTIFY_SWITCH_PROXY_MODE_SHORTCUT)
            .subscribe(onNext: { noti in
                guard let mode = defaults.string(forKey: "ShadowsocksRunningMode") else {
                    return
                }

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
                if defaults.bool(forKey: "EnableSwitchMode.ExternalPAC")
                    && self.externalPACModeMenuItem.isEnabled {
                    enabledModeList.append("externalPAC")
                }

                if enabledModeList.isEmpty {
                    return
                }

                var nextMode = ""
                if enabledModeList.contains(mode),
                   let i = enabledModeList.firstIndex(of: mode) {
                    if i + 1 == enabledModeList.count {
                        nextMode = enabledModeList[0]
                    } else {
                        nextMode = enabledModeList[i+1]
                    }
                } else {
                    nextMode = enabledModeList[0]
                }

                defaults.setValue(nextMode, forKey: "ShadowsocksRunningMode")

                self.updateRunningModeMenu()
                self.applyConfig()

                // Show toast message
                let toastMessages = [
                    "auto": "Auto Mode By PAC".localized,
                    "global": "Global Mode".localized,
                    "manual": "Manual Mode".localized,
                    "externalPAC": "Auto Mode By External PAC".localized,
                ]
                self.makeToast(toastMessages[nextMode]!)
            })

        _ = notifyCenter.rx.notification(NOTIFY_FOUND_SS_URL)
            .subscribe(onNext: { noti in
                self.handleFoundSSURL(noti)
            })

        // Handle ss url scheme
        NSAppleEventManager.shared().setEventHandler(self
            , andSelector: #selector(self.handleURLEvent)
            , forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        updateMainMenu()
        updateCopyHttpProxyExportMenu()
        updateServersMenu()
        updateRunningModeMenu()

        ProxyConfHelper.install()
        ProxyConfHelper.startMonitorPAC()
        applyConfig()

        // Register global hotkey
        ShortcutsController.bindShortcuts()
    }

    /// Performs final teardown when the application is about to terminate.
    /// 
    /// Stops background networking components and disables the system proxy before exit.
    /// - Parameter aNotification: The termination notification sent by the system.
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        stopSSLocal()
        stopPrivoxy()
        ProxyConfHelper.disableProxy()
    }

    /// Applies the current persistent Shadowsocks configuration to the system.
    /// 
    /// Synchronizes the local ss-local state and sets the system proxy mode based on stored user defaults:
    /// - Uses `ShadowsocksOn` to determine whether the proxy should be enabled.
    /// - Uses `ShadowsocksRunningMode` to choose between `auto`, `global`, `manual`, or `externalPAC` proxy modes.
    func applyConfig() {
        syncSSLocal()

        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")

        if isOn {
            if mode == "auto" {
                ProxyConfHelper.enablePACProxy()
            } else if mode == "global" {
                ProxyConfHelper.enableGlobalProxy()
            } else if mode == "manual" {
                ProxyConfHelper.disableProxy()
            } else if mode == "externalPAC" {
                ProxyConfHelper.enableExternalPACProxy()
            }
        } else {
            ProxyConfHelper.disableProxy()
        }
    }

    /// Toggle the Shadowsocks running state and apply the resulting configuration without showing a toast.
    /// - Parameter sender: The menu item that invoked this action.
    @IBAction func toggleRunning(_ sender: NSMenuItem) {
        self.doToggleRunning(showToast: false)
    }

    /// Toggles the Shadowsocks running state, persists the new setting, updates the UI, and applies the configuration.
    /// - Parameters:
    ///   - showToast: If `true`, displays a brief toast indicating the new on/off state.
    func doToggleRunning(showToast: Bool) {
        let defaults = UserDefaults.standard
        var isOn = UserDefaults.standard.bool(forKey: "ShadowsocksOn")
        isOn = !isOn
        defaults.set(isOn, forKey: "ShadowsocksOn")

        self.updateMainMenu()
        self.applyConfig()

        if showToast {
            if isOn {
                self.makeToast("Shadowsocks: On".localized)
            }
            else {
                self.makeToast("Shadowsocks: Off".localized)
            }
        }
    }

    /// Triggers an update of the PAC configuration using the latest GFWList.
    @IBAction func updateGFWList(_ sender: NSMenuItem) {
        UpdatePACFromGFWList()
    }

    /// Presents the User Rules editor for PAC, closing any existing editor window and bringing the new window to the front.
    /// 
    /// This closes a previously opened User Rules window controller if present, instantiates a new `UserRulesController`,
    /// shows its window, and activates the app so the window is key and frontmost.
    @IBAction func editUserRulesForPAC(_ sender: NSMenuItem) {
        if editUserRulesWinCtrl != nil {
            editUserRulesWinCtrl.close()
        }
        let ctrl = UserRulesController(windowNibName: "UserRulesController")
        editUserRulesWinCtrl = ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }

    /// Presents the Share Server Profiles window.
    /// 
    /// Closes any existing ShareServerProfilesWindowController, creates and shows a new one, activates the app, and brings the window to the front.
    @IBAction func showShareServerProfiles(_ sender: NSMenuItem) {
        if shareWinCtrl != nil {
            shareWinCtrl.close()
        }
        shareWinCtrl = ShareServerProfilesWindowController(windowNibName: "ShareServerProfilesWindowController")
        shareWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        shareWinCtrl.window?.makeKeyAndOrderFront(nil)
    }

    /// Presents the import window for adding server profiles.
    /// 
    /// Closes any existing import window controller, creates and shows a new ImportWindowController, and brings the app and its window to the foreground.
    @IBAction func showImportWindow(_ sender: NSMenuItem) {
        if importWinCtrl != nil {
            importWinCtrl.close()
        }
        importWinCtrl = ImportWindowController(windowNibName: "ImportWindowController")
        importWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        importWinCtrl.window?.makeKeyAndOrderFront(nil)
    }

    /// Initiates a QR code scan of the screen.
    /// - Parameter sender: The menu item that triggered this action.
    @IBAction func scanQRCodeFromScreen(_ sender: NSMenuItem) {
        ScanQRCodeOnScreen()
    }

    /// Import Shadowsocks profile URLs from the system pasteboard and post a notification with the found URLs.
    /// 
    /// Reads the pasteboard URL type (on macOS 10.13+) and the plain string type, parses any URLs found, and posts a `NOTIFY_FOUND_SS_URL` notification with `userInfo` containing:
    /// - `"urls"`: an array of `URL` objects parsed from the pasteboard
    /// - `"source"`: the string `"pasteboard"`
    ///
    /// For plain text, lines are split on newlines, trimmed of whitespace, converted to `URL`, and filtered to include only URLs with the `ss` scheme.
    @IBAction func importProfileURLFromPasteboard(_ sender: NSMenuItem) {
        let pb = NSPasteboard.general
        if #available(OSX 10.13, *) {
            if let text = pb.string(forType: NSPasteboard.PasteboardType.URL) {
                if let url = URL(string: text) {
                    NotificationCenter.default.post(
                        name: NOTIFY_FOUND_SS_URL, object: nil
                        , userInfo: [
                            "urls": [url],
                            "source": "pasteboard",
                            ])
                }
            }
        }
        if let text = pb.string(forType: NSPasteboard.PasteboardType.string) {
            var urls = text.split(separator: "\n")
                .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .compactMap { URL(string: $0) }  // compactMap automatically unwraps non-nil values
            urls = urls.filter { $0.scheme == "ss" }

            NotificationCenter.default.post(
                name: NOTIFY_FOUND_SS_URL, object: nil
                , userInfo: [
                    "urls": urls,
                    "source": "pasteboard",
                    ])
        }
    }

    /// Selects the automatic (PAC) proxy mode.
    /// 
    /// Sets the saved running mode to `"auto"`, updates the running-mode UI, and applies the current configuration.
    @IBAction func selectPACMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("auto", forKey: "ShadowsocksRunningMode")
        updateRunningModeMenu()
        applyConfig()
    }

    /// Sets the Shadowsocks running mode to global, updates the running-mode UI, and applies the new configuration.
    /// - Parameter sender: The menu item that triggered the action.
    @IBAction func selectGlobalMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("global", forKey: "ShadowsocksRunningMode")
        updateRunningModeMenu()
        applyConfig()
    }

    /// Selects the manual proxy mode for Shadowsocks.
    /// Sets the running mode to "manual", refreshes the running-mode UI, and applies the updated configuration.
    @IBAction func selectManualMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("manual", forKey: "ShadowsocksRunningMode")
        updateRunningModeMenu()
        applyConfig()
    }

    /// Switches the app to the External PAC proxy mode.
    /// 
    /// Persists "externalPAC" to `ShadowsocksRunningMode` in user defaults, updates the running-mode menu state, and applies the new proxy configuration.
    @IBAction func selectExternalPACMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("externalPAC", forKey: "ShadowsocksRunningMode")
        updateRunningModeMenu()
        applyConfig()
    }

    /// Opens the server preferences window.
    /// 
    /// If a preferences window already exists it is closed first; then a new PreferencesWindowController is created, its window shown, and the app is activated.
    @IBAction func editServerPreferences(_ sender: NSMenuItem) {
        if preferencesWinCtrl != nil {
            preferencesWinCtrl.close()
        }
        preferencesWinCtrl = PreferencesWindowController(windowNibName: "PreferencesWindowController")

        preferencesWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Presents the consolidated preferences window, closing any existing instance before creating and showing a new one.
    /// Ensures the app becomes active and brings the preferences window to the front.
    @IBAction func showAllInOnePreferences(_ sender: NSMenuItem) {
        if allInOnePreferencesWinCtrl != nil {
            allInOnePreferencesWinCtrl.close()
        }

        allInOnePreferencesWinCtrl = PreferencesWinController(windowNibName: "PreferencesWinController")

        allInOnePreferencesWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        allInOnePreferencesWinCtrl.window?.makeKeyAndOrderFront(self)
    }

    /// Selects the server profile represented by the given menu item and activates it.
    /// If the selected profile differs from the current active profile, sets it active, updates the servers menu, synchronizes ss-local, and applies the configuration. Always updates the running-mode menu afterwards.
    /// - Parameters:
    ///   - sender: The server menu item. Its `tag` is expected to equal `kProfileMenuItemIndexBase + profileIndex`, where `profileIndex` is the index in `ServerProfileManager.instance.profiles`.
    @IBAction func selectServer(_ sender: NSMenuItem) {
        let index = sender.tag - kProfileMenuItemIndexBase
        let spMgr = ServerProfileManager.instance
        let newProfile = spMgr.profiles[index]
        if newProfile.uuid != spMgr.activeProfileId {
            spMgr.setActiveProfiledId(newProfile.uuid)
            updateServersMenu()
            syncSSLocal()
            applyConfig()
        }
        updateRunningModeMenu()
    }

    /// Copies a shell export command for the configured local HTTP proxy to the pasteboard and shows a confirmation toast.
    /// Reads `LocalHTTP.ListenAddress` and `LocalHTTP.ListenPort` from UserDefaults, formats a shell string like
    /// `export http_proxy=http://<address>:<port>;export https_proxy=http://<address>:<port>;`, places it on the general pasteboard,
    /// and displays a transient toast saying the command was copied. If `LocalHTTP.ListenAddress` is not set, logs a warning and returns without copying.
    @IBAction func copyExportCommand(_ sender: NSMenuItem) {
        // Get the Http proxy config.
        let defaults = UserDefaults.standard
        guard let address = defaults.string(forKey: "LocalHTTP.ListenAddress") else {
            ErrorHandler.shared.warning("HTTP proxy address not configured")
            return
        }
        let port = defaults.integer(forKey: "LocalHTTP.ListenPort")

        // Format an export string.
        let command = "export http_proxy=http://\(address):\(port);export https_proxy=http://\(address):\(port);"

        // Copy to paste board.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)

        // Show a toast notification.
        self.makeToast("Export Command Copied.".localized)
    }

    /// Opens the Console app and attempts to display the ss-local log file.
    /// - Parameters:
    ///   - sender: The menu item that triggered this action.
    /// - Note: If launching Console or opening the log fails, the error is reported to `ErrorHandler.shared` (which may present an alert).
    @IBAction func showLogs(_ sender: NSMenuItem) {
        let ws = NSWorkspace.shared
        if let appUrl = ws.urlForApplication(withBundleIdentifier: "com.apple.Console") {
            do {
                try ws.launchApplication(at: appUrl
                    ,options: NSWorkspace.LaunchOptions.default
                    ,configuration: [NSWorkspace.LaunchConfigurationKey.arguments: "~/Library/Logs/ss-local.log"])
            } catch {
                ErrorHandler.shared.handle(
                    error,
                    context: "Open Console.app",
                    showAlert: true
                )
            }
        }
    }

    /// Open the project's GitHub issues page in the default browser.
    /// 
    /// If the feedback URL cannot be constructed, logs a warning via `ErrorHandler` and takes no action.
    @IBAction func feedback(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://github.com/qiuyuzhou/ShadowsocksX-NG/issues") else {
            ErrorHandler.shared.warning("Invalid feedback URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Opens the application's releases page on GitHub in the default web browser.
    /// If the releases URL cannot be constructed, logs a warning and does nothing.
    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://github.com/shadowsocks/ShadowsocksX-NG/releases") else {
            ErrorHandler.shared.warning("Invalid update URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Presents a Save dialog to export the application's diagnostic information to a text file.
    /// 
    /// Shows a save panel prefilled with a timestamped filename, writes the output of `diagnose()` to the chosen file encoded as UTF-8, and reports any write failures via `ErrorHandler`.
    @IBAction func exportDiagnosis(_ sender: NSMenuItem) {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Diagnosis to File".localized
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        savePanel.isExtensionHidden = false

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = formatter.string(from: Date())

        savePanel.nameFieldStringValue = "ShadowsocksX-NG_diagnose_\(dateString)"

        savePanel.becomeKey()
        let result = savePanel.runModal()
        if (result.rawValue == NSFileHandlingPanelOKButton) {
            if let url = savePanel.url {
                let diagnosisText = diagnose()
                do {
                    try diagnosisText.write(to: url, atomically: false, encoding: String.Encoding.utf8)
                } catch {
                    ErrorHandler.shared.handle(
                        error,
                        context: "Save Diagnosis File",
                        showAlert: true,
                        critical: true
                    )
                }
            }
        }
    }

    /// Opens the application's online help wiki in the default web browser.
    /// If the help URL is invalid, logs a warning and does not attempt to open it.
    @IBAction func showHelp(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://github.com/shadowsocks/ShadowsocksX-NG/wiki") else {
            ErrorHandler.shared.warning("Invalid help URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Shows the standard About panel and brings the application to the foreground.
    /// - Parameter sender: The menu item that triggered this action.
    @IBAction func showAbout(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender);
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Update the running-mode menu items and the servers menu title to reflect current settings.
    /// 
    /// Reads the external PAC URL and running mode from user defaults to:
    /// - enable or disable the External PAC menu item,
    /// - set the checked state for Auto, Global, Manual, or External PAC mode menu items,
    /// - refresh the status item image to match the current mode,
    /// and updates the Servers menu title to show the active profile's remark (truncated to 24 characters) or host, or a localized "(No Selected)" label when none is active.
    func updateRunningModeMenu() {
        let defaults = UserDefaults.standard

        if let pacURL = defaults.string(forKey: "ExternalPACURL") {
            if pacURL != "" {
                externalPACModeMenuItem.isEnabled = true
            } else {
                externalPACModeMenuItem.isEnabled = false
            }
        }

        // Update running mode state
        autoModeMenuItem.state = .off
        globalModeMenuItem.state = .off
        manualModeMenuItem.state = .off
        externalPACModeMenuItem.state = .off

        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        if mode == "auto" {
            autoModeMenuItem.state = .on
        } else if mode == "global" {
            globalModeMenuItem.state = .on
        } else if mode == "manual" {
            manualModeMenuItem.state = .on
        } else if mode == "externalPAC" {
            externalPACModeMenuItem.state = .on
        }
        updateStatusMenuImage()

        // Update selected server name
        var serverMenuText = "Servers - (No Selected)".localized

        let mgr = ServerProfileManager.instance
        for p in mgr.profiles {
            if mgr.activeProfileId == p.uuid {
                var profileName :String
                if !p.remark.isEmpty {
                    profileName = String(p.remark.prefix(24))
                } else {
                    profileName = p.serverHost
                }
                serverMenuText = "Servers".localized + " - \(profileName)"
                break
            }
        }
        serversMenuItem.title = serverMenuText
    }

    /// Update the status bar icon to reflect whether Shadowsocks is on and which running mode is active.
    /// 
    /// When Shadowsocks is enabled, sets the status item image to one of the mode-specific icons:
    /// - `"auto"` -> `menu_p_icon`
    /// - `"global"` -> `menu_g_icon`
    /// - `"manual"` -> `menu_m_icon`
    /// - `"externalPAC"` -> `menu_e_icon`
    /// When Shadowsocks is disabled, sets the image to `menu_icon_disabled`.
    /// The selected image is marked as a template to allow system tinting.
    func updateStatusMenuImage() {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        if isOn {
            if let m = mode {
                switch m {
                    case "auto":
                        statusItem.image = NSImage(named: "menu_p_icon")
                    case "global":
                        statusItem.image = NSImage(named: "menu_g_icon")
                    case "manual":
                        statusItem.image = NSImage(named: "menu_m_icon")
                    case "externalPAC":
                        statusItem.image = NSImage(named: "menu_e_icon")
                default: break
                }
                statusItem.image?.isTemplate = true
            }
        } else {
            statusItem.image = NSImage(named: "menu_icon_disabled")
            statusItem.image?.isTemplate = true
        }
    }

    /// Updates the status bar menu and related menu items to reflect the current Shadowsocks running state.
    /// 
    /// Reads the `ShadowsocksOn` setting from `UserDefaults` and sets the running status title, toggle menu title,
    /// the running status image, and the status item image accordingly. Marks the status item image as a template
    /// and then refreshes the status-mode-specific icon by calling `updateStatusMenuImage()`.
    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        if isOn {
            runningStatusMenuItem.title = "Shadowsocks: On".localized
            runningStatusMenuItem.image = NSImage(named: "NSStatusAvailable")
            toggleRunningMenuItem.title = "Turn Shadowsocks Off".localized
            let image = NSImage(named: "menu_icon")
            statusItem.image = image
        } else {
            runningStatusMenuItem.title = "Shadowsocks: Off".localized
            toggleRunningMenuItem.title = "Turn Shadowsocks On".localized
            runningStatusMenuItem.image = NSImage(named: "NSStatusNone")
            let image = NSImage(named: "menu_icon_disabled")
            statusItem.image = image
        }
        statusItem.image?.isTemplate = true

        updateStatusMenuImage()
    }

    /// Update the "Copy Export Command" menu item's visibility according to the "LocalHTTPOn" user preference.
    func updateCopyHttpProxyExportMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "LocalHTTPOn")
        copyHttpProxyExportCmdLineMenuItem.isHidden = !isOn
    }

    /// Rebuilds the Servers submenu to reflect the current server profiles.
    /// 
    /// Recreates menu items placed between the configured begin/end separators. Each menu item is:
    /// - tagged with the profile index plus the menu base offset,
    /// - titled using the profile's title,
    /// - set to `.on` when it is the active profile and `.off` otherwise,
    /// - enabled only if the profile is valid,
    /// - assigned a key equivalent for quick selection (keys `1`–`9` and `0` for the tenth item) for the first ten profiles,
    /// - connected to the `selectServer` action.
    /// Hides the end separator when there are no profiles.
    func updateServersMenu() {
        guard let menu = serversMenuItem.submenu else { return }

        let mgr = ServerProfileManager.instance
        let profiles = mgr.profiles

        // Remove all profile menu items
        let beginIndex = menu.index(of: serverProfilesBeginSeparatorMenuItem) + 1
        let endIndex = menu.index(of: serverProfilesEndSeparatorMenuItem)
        // Remove from end to begin, so the index won't change :)
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

    /// Handles an Apple Event containing a URL and posts a `NOTIFY_FOUND_SS_URL` notification when a valid URL is found.
    /// - Parameters:
    ///   - event: The Apple Event descriptor expected to contain a URL string in its direct object.
    ///   - replyEvent: The reply Apple Event descriptor (ignored).
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            if let url = URL(string: urlString) {
                NotificationCenter.default.post(
                    name: NOTIFY_FOUND_SS_URL, object: nil
                    , userInfo: [
                        "urls": [url],
                        "source": "url",
                        ])
            }
        }
    }

    /// Handles a notification that contains one or more Shadowsocks URLs and imports them as server profiles.
    /// - Parameters:
    ///   - note: A notification whose `userInfo` may include:
    ///     - `"urls"`: an array of `URL` objects to import (required).
    ///     - `"title"`, `"subtitle"`, `"body"`: optional `String` values used for the user-facing notification.
    ///     - `"error"`: an optional `String` error message; if present, a failure notification is shown and import is aborted.
    /// - Notes: Posts a local user notification to report success or failure and invokes the server profile manager to add any valid URLs. If the `"urls"` entry is missing or empty, a warning is recorded and no notification is delivered.
    func handleFoundSSURL(_ note: Notification) {
        let sendNotify = { (title: String, subtitle: String, infoText: String) in
            let userNote = NSUserNotification()
            userNote.title = title
            userNote.subtitle = subtitle
            userNote.informativeText = infoText
            userNote.soundName = NSUserNotificationDefaultSoundName

            NSUserNotificationCenter.default.deliver(userNote)
        }

        if let userInfo = (note as NSNotification).userInfo {
            // 检查错误
            if let error = userInfo["error"] as? String {
                sendNotify("Scan Failed", "", error.localized)
                return
            }

            // 使用新的通知信息
            let title = (userInfo["title"] as? String) ?? ""
            let subtitle = (userInfo["subtitle"] as? String) ?? ""
            let body = (userInfo["body"] as? String) ?? ""

            // Safe cast of URLs array
            guard let urls = userInfo["urls"] as? [URL], !urls.isEmpty else {
                ErrorHandler.shared.warning("Invalid or empty URLs in notification")
                return
            }

            let addCount = ServerProfileManager.instance.addServerProfileByURL(urls: urls)

            if addCount > 0 {
                sendNotify(
                    title.localized,
                    subtitle.localized,
                    "Successfully added \(addCount) server configuration(s)".localized
                )
            } else {
                sendNotify(
                    title.localized,
                    subtitle.localized,
                    body.localized
                )
            }
        }
    }

    //------------------------------------------------------------
    /// Always allows the system to present the given user notification.
    /// - Returns: `true` to present the notification, `false` otherwise.

    func userNotificationCenter(_ center: NSUserNotificationCenter
        , shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }


    /// Displays a transient HUD-style toast with the given message, replacing any existing toast.
    /// - Parameter message: The text to show in the toast. The current toast (if any) is closed before the new one is shown.
    func makeToast(_ message: String) {
        if toastWindowCtrl != nil {
            toastWindowCtrl.close()
        }
        toastWindowCtrl = ToastWindowController(windowNibName: "ToastWindowController")
        toastWindowCtrl.message = message
        toastWindowCtrl.showWindow(self)
        //NSApp.activate(ignoringOtherApps: true)
        //toastWindowCtrl.window?.makeKeyAndOrderFront(self)
        toastWindowCtrl.fadeInHud()
    }
}