//
//  WindowCoordinator.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2
//

import Cocoa

/// Manages window controllers lifecycle and presentation
class WindowCoordinator {
    // MARK: - Window Controllers

    private var shareWinCtrl: ShareServerProfilesWindowController?
    private var qrcodeWinCtrl: SWBQRCodeWindowController?
    private var preferencesWinCtrl: PreferencesWindowController?
    private var editUserRulesWinCtrl: UserRulesController?
    private var allInOnePreferencesWinCtrl: PreferencesWinController?
    private var toastWindowCtrl: ToastWindowController?
    private var importWinCtrl: ImportWindowController?

    // MARK: - Public Methods

    func showShareServerProfiles() {
        if shareWinCtrl != nil {
            shareWinCtrl?.close()
        }
        shareWinCtrl = ShareServerProfilesWindowController(
            windowNibName: "ShareServerProfilesWindowController")
        shareWinCtrl?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        shareWinCtrl?.window?.makeKeyAndOrderFront(nil)
    }

    func showImportWindow() {
        if importWinCtrl != nil {
            importWinCtrl?.close()
        }
        importWinCtrl = ImportWindowController(windowNibName: "ImportWindowController")
        importWinCtrl?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        importWinCtrl?.window?.makeKeyAndOrderFront(nil)
    }

    func editUserRulesForPAC() {
        if editUserRulesWinCtrl != nil {
            editUserRulesWinCtrl?.close()
        }
        let ctrl = UserRulesController(windowNibName: "UserRulesController")
        editUserRulesWinCtrl = ctrl

        ctrl.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(nil)
    }

    func editServerPreferences() {
        if preferencesWinCtrl != nil {
            preferencesWinCtrl?.close()
        }
        preferencesWinCtrl = PreferencesWindowController(
            windowNibName: "PreferencesWindowController")

        preferencesWinCtrl?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showAllInOnePreferences() {
        if allInOnePreferencesWinCtrl != nil {
            allInOnePreferencesWinCtrl?.close()
        }

        allInOnePreferencesWinCtrl = PreferencesWinController(
            windowNibName: "PreferencesWinController")

        allInOnePreferencesWinCtrl?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        allInOnePreferencesWinCtrl?.window?.makeKeyAndOrderFront(nil)
    }

    func showQRCodeWindow() {
        if qrcodeWinCtrl != nil {
            qrcodeWinCtrl?.close()
        }
        qrcodeWinCtrl = SWBQRCodeWindowController(windowNibName: "SWBQRCodeWindowController")
        qrcodeWinCtrl?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showToast(_ message: String) {
        if toastWindowCtrl != nil {
            toastWindowCtrl?.close()
        }
        toastWindowCtrl = ToastWindowController(windowNibName: "ToastWindowController")
        toastWindowCtrl?.message = message
        toastWindowCtrl?.showWindow(nil)
        toastWindowCtrl?.fadeInHud()
    }

    // MARK: - Cleanup

    func closeAllWindows() {
        shareWinCtrl?.close()
        qrcodeWinCtrl?.close()
        preferencesWinCtrl?.close()
        editUserRulesWinCtrl?.close()
        allInOnePreferencesWinCtrl?.close()
        toastWindowCtrl?.close()
        importWinCtrl?.close()
    }
}
