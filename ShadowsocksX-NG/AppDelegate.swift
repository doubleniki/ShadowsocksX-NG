//
//  AppDelegate.swift
//  ShadowsocksX-NG
//
//  Created by Qiu Yuzhou on 16/6/5.
//  Copyright © 2016 qiuyuzhou. All rights reserved.
//

import Carbon
import Cocoa
import RxCocoa
import RxSwift
import UserNotifications

// TODO: Refactor AppDelegate - split into smaller controllers (Phase 2)
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Coordinators

    private var menuBarManager: MenuBarManager!
    private var windowCoordinator: WindowCoordinator!
    private var proxyCoordinator: ProxyCoordinator!
    private let disposeBag = DisposeBag()

    // MARK: - IBOutlets

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

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Validate minimum macOS version
        guard OSVersion.validateMinimumVersion() else {
            let alert = NSAlert()
            alert.messageText = "Unsupported macOS Version"
            alert.informativeText = """
                ShadowsocksX-NG requires macOS 11.0 (Big Sur) or later.
                Your current version: \(OSVersion.fullVersionString)

                Please upgrade your macOS or download an older version of the app.
                """
            alert.alertStyle = .critical
            alert.runModal()
            NSApp.terminate(nil)
            return
        }

        // Print system info for debugging (can be disabled in production)
        #if DEBUG
            OSVersion.printSystemInfo()
        #endif

        _ = LaunchAtLoginController.shared()  // Initialize singleton and ensure LaunchAtLogin is set

        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                ErrorHandler.shared.handle(
                    error,
                    context: "Request Notification Authorization",
                    showAlert: false
                )
            }
        }
        UNUserNotificationCenter.current().delegate = self

        ensureLaunchAgentsDirOwner()

        // Prepare ss-local
        installSSLocal()
        installPrivoxy()
        installSimpleObfs()
        installKcptun()
        installV2rayPlugin()

        registerDefaultSettings()
        setupCoordinators()
        setupNotificationObservers()

        // Handle ss url scheme
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(self.handleURLEvent),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        menuBarManager.updateMainMenu()
        menuBarManager.updateCopyHttpProxyExportMenu()
        menuBarManager.updateServersMenu()
        menuBarManager.updateRunningModeMenu()

        ProxyConfHelper.install()
        ProxyConfHelper.startMonitorPAC()
        proxyCoordinator.applyConfig()

        // Register global hotkey
        ShortcutsController.bindShortcuts()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        stopSSLocal()
        stopPrivoxy()
        ProxyConfHelper.disableProxy()
    }

    // MARK: - Setup Methods

    private func registerDefaultSettings() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "ShadowsocksOn": true,
            "ShadowsocksRunningMode": "auto",
            "LocalSocks5.ListenPort": NSNumber(value: 1086 as UInt16),
            "LocalSocks5.ListenAddress": "127.0.0.1",
            "PacServer.BindToLocalhost": NSNumber(value: true as Bool),
            "PacServer.ListenPort": NSNumber(value: 1089 as UInt16),
            "LocalSocks5.Timeout": NSNumber(value: 60 as UInt),
            "LocalSocks5.EnableUDPRelay": NSNumber(value: false as Bool),
            "LocalSocks5.EnableVerboseMode": NSNumber(value: false as Bool),
            "GFWListURL": "https://cdn.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt",
            "AutoConfigureNetworkServices": NSNumber(value: true as Bool),
            "LocalHTTP.ListenAddress": "127.0.0.1",
            "LocalHTTP.ListenPort": NSNumber(value: 1087 as UInt16),
            "LocalHTTPOn": true,
            "LocalHTTP.FollowGlobal": false,
            "ProxyExceptions":
                "127.0.0.1, localhost, 192.168.0.0/16, 10.0.0.0/8, FE80::/64, ::1, FD00::/8",
            "ExternalPACURL": "",
            "EnableSwitchMode.PAC": true,
            "EnableSwitchMode.Global": true,
            "EnableSwitchMode.Manual": false,
            "EnableSwitchMode.ExternalPAC": false
        ])
    }

    private func setupCoordinators() {
        // Initialize WindowCoordinator
        windowCoordinator = WindowCoordinator()

        // Initialize ProxyCoordinator
        proxyCoordinator = ProxyCoordinator()

        // Initialize MenuBarManager with all required menu items
        menuBarManager = MenuBarManager(
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
            copyHttpProxyExportCmdLineMenuItem: copyHttpProxyExportCmdLineMenuItem
        )
    }

    private func setupNotificationObservers() {
        let notifyCenter = NotificationCenter.default

        notifyCenter.rx.notification(NOTIFY_CONF_CHANGED)
            .subscribe(onNext: { _ in
                self.proxyCoordinator.applyConfig()
                self.menuBarManager.updateRunningModeMenu()
                self.menuBarManager.updateCopyHttpProxyExportMenu()
            })
            .disposed(by: disposeBag)

        notifyCenter.addObserver(
            forName: NOTIFY_SERVER_PROFILES_CHANGED, object: nil, queue: nil
        ) { _ in
            let profileMgr = ServerProfileManager.instance
            if profileMgr.activeProfileId == nil && !profileMgr.profiles.isEmpty {
                if profileMgr.profiles[0].isValid() {
                    profileMgr.setActiveProfiledId(profileMgr.profiles[0].uuid)
                }
            }
            self.menuBarManager.updateServersMenu()
            self.menuBarManager.updateRunningModeMenu()
            syncSSLocal()
        }

        notifyCenter.rx.notification(NOTIFY_TOGGLE_RUNNING_SHORTCUT)
            .subscribe(onNext: { _ in
                self.doToggleRunning(showToast: true)
            })
            .disposed(by: disposeBag)

        notifyCenter.rx.notification(NOTIFY_SWITCH_PROXY_MODE_SHORTCUT)
            .subscribe(onNext: { _ in
                self.handleSwitchProxyModeShortcut()
            })
            .disposed(by: disposeBag)

        notifyCenter.rx.notification(NOTIFY_FOUND_SS_URL)
            .subscribe(onNext: { notification in
                self.handleFoundSSURL(notification)
            })
            .disposed(by: disposeBag)
    }

    private func handleSwitchProxyModeShortcut() {
        guard let nextMode = proxyCoordinator.switchToNextEnabledMode() else {
            return
        }

        menuBarManager.updateRunningModeMenu()
        proxyCoordinator.applyConfig()

        // Show toast message
        windowCoordinator.showToast(nextMode.localizedName)
    }

    // MARK: - UI Methods
    @IBAction func toggleRunning(_ sender: NSMenuItem) {
        doToggleRunning(showToast: false)
    }

    func doToggleRunning(showToast: Bool) {
        let isOn = proxyCoordinator.toggleShadowsocks()

        menuBarManager.updateMainMenu()
        proxyCoordinator.applyConfig()

        if showToast {
            let message = isOn ? "Shadowsocks: On".localized : "Shadowsocks: Off".localized
            windowCoordinator.showToast(message)
        }
    }

    @IBAction func updateGFWList(_ sender: NSMenuItem) {
        updatePACFromGFWList()
    }

    @IBAction func editUserRulesForPAC(_ sender: NSMenuItem) {
        windowCoordinator.editUserRulesForPAC()
    }

    @IBAction func showShareServerProfiles(_ sender: NSMenuItem) {
        windowCoordinator.showShareServerProfiles()
    }

    @IBAction func showImportWindow(_ sender: NSMenuItem) {
        windowCoordinator.showImportWindow()
    }

    @IBAction func scanQRCodeFromScreen(_ sender: NSMenuItem) {
        ScanQRCodeOnScreen()
    }

    @IBAction func importProfileURLFromPasteboard(_ sender: NSMenuItem) {
        let pb = NSPasteboard.general

        // Check for URL type (version check removed as minimum deployment is macOS 11.0)
        if let text = pb.string(forType: NSPasteboard.PasteboardType.URL) {
            if let url = URL(string: text) {
                NotificationCenter.default.post(
                    name: NOTIFY_FOUND_SS_URL, object: nil,
                    userInfo: [
                        "urls": [url],
                        "source": "pasteboard"
                    ])
            }
        }

        // Check for string type
        if let text = pb.string(forType: NSPasteboard.PasteboardType.string) {
            var urls = text.split(separator: "\n")
                .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .compactMap { URL(string: $0) }  // compactMap automatically unwraps non-nil values
            urls = urls.filter { $0.scheme == "ss" }

            NotificationCenter.default.post(
                name: NOTIFY_FOUND_SS_URL, object: nil,
                userInfo: [
                    "urls": urls,
                    "source": "pasteboard"
                ])
        }
    }

    @IBAction func selectPACMode(_ sender: NSMenuItem) {
        proxyCoordinator.switchMode(to: .auto)
        menuBarManager.updateRunningModeMenu()
        proxyCoordinator.applyConfig()
    }

    @IBAction func selectGlobalMode(_ sender: NSMenuItem) {
        proxyCoordinator.switchMode(to: .global)
        menuBarManager.updateRunningModeMenu()
        proxyCoordinator.applyConfig()
    }

    @IBAction func selectManualMode(_ sender: NSMenuItem) {
        proxyCoordinator.switchMode(to: .manual)
        menuBarManager.updateRunningModeMenu()
        proxyCoordinator.applyConfig()
    }

    @IBAction func selectExternalPACMode(_ sender: NSMenuItem) {
        proxyCoordinator.switchMode(to: .externalPAC)
        menuBarManager.updateRunningModeMenu()
        proxyCoordinator.applyConfig()
    }

    @IBAction func editServerPreferences(_ sender: NSMenuItem) {
        windowCoordinator.editServerPreferences()
    }

    @IBAction func showAllInOnePreferences(_ sender: NSMenuItem) {
        windowCoordinator.showAllInOnePreferences()
    }

    @IBAction func selectServer(_ sender: NSMenuItem) {
        let index = sender.tag - kProfileMenuItemIndexBase
        let spMgr = ServerProfileManager.instance
        let newProfile = spMgr.profiles[index]
        if newProfile.uuid != spMgr.activeProfileId {
            spMgr.setActiveProfiledId(newProfile.uuid)
            menuBarManager.updateServersMenu()
            syncSSLocal()
            proxyCoordinator.applyConfig()
        }
        menuBarManager.updateRunningModeMenu()
    }

    @IBAction func copyExportCommand(_ sender: NSMenuItem) {
        // Get the Http proxy config.
        let defaults = UserDefaults.standard
        guard let address = defaults.string(forKey: "LocalHTTP.ListenAddress") else {
            ErrorHandler.shared.warning("HTTP proxy address not configured")
            return
        }
        let port = defaults.integer(forKey: "LocalHTTP.ListenPort")

        // Format an export string.
        let command =
            "export http_proxy=http://\(address):\(port);export https_proxy=http://\(address):\(port);"

        // Copy to paste board.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)

        // Show a toast notification.
        windowCoordinator.showToast("Export Command Copied.".localized)
    }

    @IBAction func showLogs(_ sender: NSMenuItem) {
        let ws = NSWorkspace.shared
        if let appUrl = ws.urlForApplication(withBundleIdentifier: "com.apple.Console") {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.arguments = ["~/Library/Logs/ss-local.log"]

            ws.openApplication(at: appUrl, configuration: configuration) { _, error in
                if let error = error {
                    ErrorHandler.shared.handle(
                        error,
                        context: "Open Console.app",
                        showAlert: true
                    )
                }
            }
        }
    }

    @IBAction func feedback(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://github.com/qiuyuzhou/ShadowsocksX-NG/issues") else {
            ErrorHandler.shared.warning("Invalid feedback URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://github.com/shadowsocks/ShadowsocksX-NG/releases")
        else {
            ErrorHandler.shared.warning("Invalid update URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    @IBAction func exportDiagnosis(_ sender: NSMenuItem) {
        showDiagnosisExportPanel()
    }

    @IBAction func showHelp(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://github.com/shadowsocks/ShadowsocksX-NG/wiki") else {
            ErrorHandler.shared.warning("Invalid help URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    @IBAction func showAbout(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender)
        NSApp.activate(ignoringOtherApps: true)
    }


    @objc func handleURLEvent(
        _ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            if let url = URL(string: urlString) {
                NotificationCenter.default.post(
                    name: NOTIFY_FOUND_SS_URL, object: nil,
                    userInfo: [
                        "urls": [url],
                        "source": "url"
                    ])
            }
        }
    }

    func handleFoundSSURL(_ note: Notification) {
        guard let userInfo = (note as NSNotification).userInfo else { return }

        // Check for errors
        if let error = userInfo["error"] as? String {
            sendUserNotification(title: "Scan Failed", subtitle: "", body: error.localized)
            return
        }

        // Use new notification information
        let title = (userInfo["title"] as? String) ?? ""
        let subtitle = (userInfo["subtitle"] as? String) ?? ""
        let body = (userInfo["body"] as? String) ?? ""

        // Safe cast of URLs array - allow empty array for informative notifications
        guard let urls = userInfo["urls"] as? [URL] else {
            ErrorHandler.shared.warning("Invalid URLs format in notification")
            return
        }

        let addCount = ServerProfileManager.instance.addServerProfileByURL(urls: urls)

        if addCount > 0 {
            sendUserNotification(
                title: title.localized,
                subtitle: subtitle.localized,
                body: "Successfully added \(addCount) server configuration(s)".localized
            )
        } else {
            sendUserNotification(
                title: title.localized,
                subtitle: subtitle.localized,
                body: body.localized
            )
        }
    }
}

// MARK: - Helper Methods
extension AppDelegate {
    private func ensureLaunchAgentsDirOwner() {
        let dirPath = NSHomeDirectory() + "/Library/LaunchAgents"
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: dirPath) {
            do {
                let attrs = try fileMgr.attributesOfItem(atPath: dirPath)

                // Safe unwrap of owner name
                guard let owner = attrs[FileAttributeKey.ownerAccountName] as? String else {
                    ErrorHandler.shared.warning(
                        "Could not determine directory owner for \(dirPath)")
                    return
                }

                if owner != NSUserName() {
                    // Safe unwrap of script path
                    guard
                        let bashFilePath = Bundle.main.path(
                            forResource: "fix_dir_owner.sh", ofType: nil)
                    else {
                        ErrorHandler.shared.warning("fix_dir_owner.sh script not found in bundle")
                        return
                    }

                    let script = """
                        do shell script "bash \\"\(bashFilePath)\\" \(NSUserName()) " \
                        with administrator privileges
                        """
                    if let appleScript = NSAppleScript(source: script) {
                        var err: NSDictionary?
                        appleScript.executeAndReturnError(&err)
                        if let error = err {
                            ErrorHandler.shared.warning("AppleScript error: \(error)")
                        }
                    }
                }
            } catch {
                ErrorHandler.shared.handle(
                    error,
                    context: "Ensure LaunchAgents Directory Owner",
                    showAlert: false
                )
            }
        }
    }

    private func showDiagnosisExportPanel() {
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
        if result == .OK {
            if let url = savePanel.url {
                let diagnosisText = diagnose()
                do {
                    try diagnosisText.write(
                        to: url, atomically: false, encoding: String.Encoding.utf8)
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

    private func sendUserNotification(title: String, subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                ErrorHandler.shared.handle(
                    error,
                    context: "Send Notification",
                    showAlert: false
                )
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
