//
//  PreferencesWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift

class PreferencesWindowController: NSWindowController
    , NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var profilesTableView: NSTableView!

    @IBOutlet weak var profileBox: NSBox!

    @IBOutlet weak var hostTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var methodTextField: NSComboBox!

    @IBOutlet weak var passwordTabView: NSTabView!
    @IBOutlet weak var passwordTextField: NSTextField!
    @IBOutlet weak var passwordSecureTextField: NSSecureTextField!
    @IBOutlet weak var togglePasswordVisibleButton: NSButton!
    @IBOutlet weak var pluginTextField: NSTextField!
    @IBOutlet weak var pluginOptionsTextField: NSTextField!
    @IBOutlet weak var remarkTextField: NSTextField!
    @IBOutlet weak var removeButton: NSButton!

    let tableViewDragType: String = "ss.server.profile.data"

    var defaults: UserDefaults!
    var profileMgr: ServerProfileManager!

    var editingProfile: ServerProfile!


    /// Performs initial setup after the window has been loaded.
    /// 
    /// Initializes user defaults and the shared server profile manager, populates the encryption method popup with supported methods, reloads the profiles table view, and updates the profile box visibility.
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

        defaults = UserDefaults.standard
        profileMgr = ServerProfileManager.instance

        methodTextField.addItems(withObjectValues: [
            "aes-128-gcm",
            "aes-192-gcm",
            "aes-256-gcm",
            "aes-128-cfb",
            "aes-192-cfb",
            "aes-256-cfb",
            "aes-128-ctr",
            "aes-192-ctr",
            "aes-256-ctr",
            "camellia-128-cfb",
            "camellia-192-cfb",
            "camellia-256-cfb",
            "bf-cfb",
            "chacha20-ietf-poly1305",
            "xchacha20-ietf-poly1305",
            "salsa20",
            "chacha20",
            "chacha20-ietf",
            "rc4-md5",
            ])

        profilesTableView.reloadData()
        updateProfileBoxVisible()
    }

    /// Performs initial setup after the view is loaded from the nib, configuring the profiles table for drag-and-drop and allowing multiple selection.
    /// - Note: Registers the custom pasteboard drag type used for profile row dragging and enables multiple row selection on the table view.
    override func awakeFromNib() {
        profilesTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: tableViewDragType)])
        profilesTableView.allowsMultipleSelection = true
    }

    /// Adds a new server profile, inserts it into the table, selects it, and updates the UI.
    /// 
    /// If there is an active editing profile that is invalid, the window is shaken and the operation is aborted.
    /// - Parameter sender: The button that triggered the action.
    @IBAction func addProfile(_ sender: NSButton) {
        if editingProfile != nil && !editingProfile.isValid(){
            shakeWindows()
            return
        }
        profilesTableView.beginUpdates()
        let profile = ServerProfile()
        profile.remark = "New Server".localized
        profileMgr.profiles.append(profile)

        let index = IndexSet(integer: profileMgr.profiles.count-1)
        profilesTableView.insertRows(at: index, withAnimation: NSTableView.AnimationOptions.effectFade)

        self.profilesTableView.scrollRowToVisible(self.profileMgr.profiles.count-1)
        self.profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
        profilesTableView.endUpdates()
        updateProfileBoxVisible()
    }

    /// Removes the currently selected server profiles and their stored passwords, updating the table view and selection.
    /// 
    /// Deletes each selected profile (removing its password from the Keychain first), removes the corresponding rows from the profiles table with a fade animation, then selects and scrolls to the previous row if available. If no row is selected, the method does nothing.
    @IBAction func removeProfile(_ sender: NSButton) {
        guard let firstIndex = profilesTableView.selectedRowIndexes.first else {
            return
        }
        let index = Int(firstIndex)
        var deleteCount = 0
        if index >= 0 {
            profilesTableView.beginUpdates()
            for (_, toDeleteIndex) in profilesTableView.selectedRowIndexes.enumerated() {
                print(profileMgr.profiles.count)
                let profile = profileMgr.profiles[toDeleteIndex - deleteCount]
                // Remove password from Keychain before deleting profile
                profile.removePasswordFromKeychain()
                profileMgr.profiles.remove(at: toDeleteIndex - deleteCount)
                profilesTableView.removeRows(
                    at: IndexSet(integer: toDeleteIndex - deleteCount),
                    withAnimation: NSTableView.AnimationOptions.effectFade
                )
                deleteCount += 1
            }
            profilesTableView.endUpdates()
        }
        self.profilesTableView.scrollRowToVisible(index-1)
        self.profilesTableView.selectRowIndexes(IndexSet(integer: index-1), byExtendingSelection: false)
        updateProfileBoxVisible()
    }

    /// Save current server profiles, close the preferences window, and notify observers of the change.
    /// 
    /// If there is an active editing profile and it is invalid, the window is shaken and the save is aborted.
    /// On success, the profiles are persisted, the preferences window is closed, and a notification named
    /// `NOTIFY_SERVER_PROFILES_CHANGED` is posted to notify observers of the update.
    @IBAction func ok(_ sender: NSButton) {
        if editingProfile != nil {
            if !editingProfile.isValid() {
                // TODO Shake window?
                shakeWindows()
                return
            }
        }
        profileMgr.save()
        window?.performClose(nil)

        NotificationCenter.default
            .post(name: NOTIFY_SERVER_PROFILES_CHANGED, object: nil)
    }

    /// Reverts any unsaved profile changes and closes the preferences window.
    @IBAction func cancel(_ sender: NSButton) {
        profileMgr.reload()
        window?.performClose(self)
    }

    /// Duplicates each selected server profile and inserts the copies immediately after their originals, updating the table view and selection.
    /// 
    /// If a profile cannot be copied, that profile is skipped and a warning is logged; duplication continues for other selections. Each duplicated profile receives a new UUID before insertion. The table view is updated to show and select each inserted copy, and the profile box visibility is refreshed afterward.
    @IBAction func duplicate(_ sender: Any) {
        var copyCount = 0
        for (_, toDuplicateIndex) in profilesTableView.selectedRowIndexes.enumerated() {
            print(profileMgr.profiles.count)
            let profile = profileMgr.profiles[toDuplicateIndex + copyCount]
            guard let duplicateProfile = profile.copy() as? ServerProfile else {
                ErrorHandler.shared.warning("Failed to copy server profile")
                continue
            }
            duplicateProfile.uuid = UUID().uuidString
            profileMgr.profiles.insert(duplicateProfile, at:toDuplicateIndex + copyCount)

            profilesTableView.beginUpdates()
            let index = IndexSet(integer: toDuplicateIndex + copyCount)
            profilesTableView.insertRows(at: index, withAnimation: NSTableView.AnimationOptions.effectFade)
            self.profilesTableView.scrollRowToVisible(toDuplicateIndex + copyCount)
            self.profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
            profilesTableView.endUpdates()

            copyCount += 1
        }
        updateProfileBoxVisible()
    }

    /// Toggles the password field between secure and insecure views and updates the toggle button image.
    /// If the current tab identifier is `"secure"` this selects the `"insecure"` tab and sets the button image to `"icons8-Eye Filled-50"`; otherwise it selects the `"secure"` tab and sets the button image to `"icons8-Blind Filled-50"`.
    /// Logs a warning and returns without changing state if the current password tab identifier cannot be determined.
    @IBAction func togglePasswordVisible(_ sender: Any) {
        guard let identifier = passwordTabView.selectedTabViewItem?.identifier as? String else {
            ErrorHandler.shared.warning("Could not determine password tab identifier")
            return
        }

        if identifier == "secure" {
            passwordTabView.selectTabViewItem(withIdentifier: "insecure")
            togglePasswordVisibleButton.image = NSImage(named: "icons8-Eye Filled-50")
        } else {
            passwordTabView.selectTabViewItem(withIdentifier: "secure")
            togglePasswordVisibleButton.image = NSImage(named: "icons8-Blind Filled-50")
        }
    }

    /// Opens the SIP003 plugin help page in the user's default browser.
    /// If the help URL is invalid, logs a warning via `ErrorHandler` and does not attempt to open it.
    @IBAction func openPluginHelp(_ sender: Any) {
        guard let url = URL(string: "https://github.com/shadowsocks/ShadowsocksX-NG/wiki/SIP003-Plugin") else {
            ErrorHandler.shared.warning("Invalid plugin help URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Opens the application's plugins folder in Finder.
    /// 
    /// The folder opened is the "plugins" directory inside the application's Application Support path within the current user's home directory.
    @IBAction func openPluginFolder(_ sender: Any) {
        let folderPath = NSHomeDirectory() + APP_SUPPORT_DIR + "plugins/"
        let url = URL(fileURLWithPath: folderPath, isDirectory: true)
        NSWorkspace.shared.open(url)
    }

    /// Copies the currently selected server profile's URL to the general pasteboard.
    /// 
    /// If a table row is selected and the corresponding profile produces a URL, that URL is written to the general pasteboard. If no row is selected or the profile does not produce a URL, the method has no effect. The operation logs success or failure.
    @IBAction func copyCurrentProfileURL2Pasteboard(_ sender: NSButton) {
        let index = profilesTableView.selectedRow
        if  index >= 0 {
            let profile = profileMgr.profiles[index]
            let ssURL = profile.URL()
            if let url = ssURL {
                // Then copy url to pasteboard
                // TODO Why it not working?? It's ok in objective-c
                let pboard = NSPasteboard.general
                pboard.clearContents()
                let rs = pboard.writeObjects([url as NSPasteboardWriting])
                if rs {
                    NSLog("copy to pasteboard success")
                } else {
                    NSLog("copy to pasteboard failed")
                }
            }
        }
    }

    /// Updates profile-related UI to reflect whether any profiles exist.
    /// 
    /// Enables the remove button when there is at least one profile and disables it when there are none.
    /// Shows the profile box when there is at least one profile and hides it when the profile list is empty.
    func updateProfileBoxVisible() {
        if profileMgr.profiles.count <= 0 {
            removeButton.isEnabled = false
        }else{
            removeButton.isEnabled = true
        }

        if profileMgr.profiles.isEmpty {
            profileBox.isHidden = true
        } else {
            profileBox.isHidden = false
        }
    }

    /// Bind UI fields to the server profile at the specified index, or clear bindings if the index is invalid.
    /// - Parameter index: The index of the profile to bind. If the index is out of range, all relevant UI bindings are removed and the controller's `editingProfile` is cleared.
    func bindProfile(_ index:Int) {
        NSLog("bind profile \(index)")

        if index >= 0 && index < profileMgr.profiles.count {
            let editingProfile = profileMgr.profiles[index]

            hostTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "serverHost"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])
            portTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "serverPort"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])

            methodTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "method"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])
            passwordTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "password"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])
            passwordSecureTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "password"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])

            pluginTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "plugin"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])
            pluginOptionsTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "pluginOptions"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])

            remarkTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile, withKeyPath: "remark"
                , options: [NSBindingOption.continuouslyUpdatesValue: true])
        } else {
            editingProfile = nil
            hostTextField.unbind(NSBindingName(rawValue: "value"))
            portTextField.unbind(NSBindingName(rawValue: "value"))

            methodTextField.unbind(NSBindingName(rawValue: "value"))
            passwordTextField.unbind(NSBindingName(rawValue: "value"))

            remarkTextField.unbind(NSBindingName(rawValue: "value"))
        }
    }

    /// Provides the display title and active state for the profile at the given row.
    /// - Parameters:
    ///   - index: The row index of the profile in `profileMgr.profiles`.
    /// - Returns: A tuple whose first element is the display title (the profile's `remark` truncated to 24 characters if non-empty, otherwise the `serverHost`) and whose second element is `true` if that profile is the active profile, `false` otherwise.
    func getDataAtRow(_ index:Int) -> (String, Bool) {
        let profile = profileMgr.profiles[index]
        let isActive = (profileMgr.activeProfileId == profile.uuid)
        if !profile.remark.isEmpty {
            return (String(profile.remark.prefix(24)), isActive)
        } else {
            return (profile.serverHost, isActive)
        }
    }

    //--------------------------------------------------
    /// Returns the number of server profiles.
    /// - Parameters:
    ///   - tableView: The table view requesting the row count.
    /// - Returns: The count of profiles, or 0 if the profile manager is unavailable.

    func numberOfRows(in tableView: NSTableView) -> Int {
        if let mgr = profileMgr {
            return mgr.profiles.count
        }
        return 0
    }

    /// Provides the value displayed for a given cell in the profiles table.
    /// - Parameters:
    ///   - tableView: The table view requesting the value.
    ///   - tableColumn: The column for which the value is requested; recognized identifiers are `"main"` and `"status"`.
    ///   - row: The row index of the requested item.
    /// - Returns: For the `"main"` column, the profile title `String`; for the `"status"` column, an `NSImage` named `"NSMenuOnStateTemplate"` when the profile is active and `nil` when inactive; an empty `String` for any other column.
    func tableView(_ tableView: NSTableView
        , objectValueFor tableColumn: NSTableColumn?
        , row: Int) -> Any? {

        let (title, isActive) = getDataAtRow(row)

        if tableColumn?.identifier == NSUserInterfaceItemIdentifier("main") {
            return title
        } else if tableColumn?.identifier == NSUserInterfaceItemIdentifier("status") {
            if isActive {
                return NSImage(named: "NSMenuOnStateTemplate")
            } else {
                return nil
            }
        }
        return ""
    }

    /// Provides a pasteboard writer for dragging the specified table row.
    /// - Parameters:
    ///   - tableView: The table view requesting the pasteboard writer.
    ///   - row: The index of the row being dragged.
    /// - Returns: An `NSPasteboardWriting` that encodes the row index as a string under the view's custom drag type.

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: tableViewDragType))
        return item
    }

    /// Decides whether a proposed drop into the table view is allowed and which operation to perform.
    /// - Returns: `.move` when the proposed drop operation is `.above`, an empty `NSDragOperation` otherwise.
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int
        , proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return NSDragOperation()
    }

    /// Accepts a drop onto the profiles table, reorders the underlying profiles array to match the dropped items, and updates the table view to reflect the new order.
    /// - Parameters:
    ///   - tableView: The table view receiving the drop.
    ///   - info: The dragging info whose pasteboard items must contain source row indexes under the controller's custom drag type; those indexes will be used to determine which profiles to move.
    ///   - row: The target insertion row for the drop (the position at which items should be placed).
    ///   - dropOperation: The proposed drop operation (not used by this implementation).
    /// - Returns: `true` if the drop was accepted and items were moved, `false` otherwise.
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo
        , row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if let mgr = profileMgr {
            var oldIndexes = [Int]()
            info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:], using: {
                (draggingItem: NSDraggingItem, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                guard let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                      let str = pasteboardItem.string(forType: NSPasteboard.PasteboardType(rawValue: self.tableViewDragType)),
                      let index = Int(str) else {
                    return
                }
                oldIndexes.append(index)
            })

            var oldIndexOffset = 0
            var newIndexOffset = 0

            // For simplicity, the code below uses `tableView.moveRowAtIndex` to move rows around directly.
            // You may want to move rows in your content array and then call `tableView.reloadData()` instead.
            tableView.beginUpdates()
            for oldIndex in oldIndexes {
                if oldIndex < row {
                    let o = mgr.profiles.remove(at: oldIndex + oldIndexOffset)
                    mgr.profiles.insert(o, at:row - 1)
                    tableView.moveRow(at: oldIndex + oldIndexOffset, to: row - 1)
                    oldIndexOffset -= 1
                } else {
                    let o = mgr.profiles.remove(at: oldIndex)
                    mgr.profiles.insert(o, at:row + newIndexOffset)
                    tableView.moveRow(at: oldIndex, to: row + newIndexOffset)
                    newIndexOffset += 1
                }
            }
            tableView.endUpdates()

            return true
        }
        return false
    }

    //--------------------------------------------------
    /// Prevents in-place editing of table cells.
    /// - Returns: `false` to disallow editing and prevent the cell from entering edit mode.

    func tableView(_ tableView: NSTableView
        , shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }

    /// Determines whether the specified table row may be selected.
    /// 
    /// If `row` is less than 0, clears the current `editingProfile` and allows selection.
    /// If there is an existing `editingProfile` that is invalid, selection is disallowed.
    /// - Parameters:
    ///   - tableView: The table view requesting the selection change.
    ///   - row: The index of the row that is about to be selected.
    /// - Returns: `true` if the row may be selected, `false` otherwise.
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if row < 0 {
            editingProfile = nil
            return true
        }
        if editingProfile != nil {
            if !editingProfile.isValid() {
                return false
            }
        }

        return true
    }

    /// Updates the editing profile when the table selection changes by binding the newly selected profile or, if no row is selected, selecting the last profile when one exists.
    /// - Parameter notification: Notification sent by the table view when its selection changes.
    func tableViewSelectionDidChange(_ notification: Notification) {
        if profilesTableView.selectedRow >= 0 {
            bindProfile(profilesTableView.selectedRow)
        } else {
            if !profileMgr.profiles.isEmpty {
                let index = IndexSet(integer: profileMgr.profiles.count - 1)
                profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
            }
        }
    }

    /// Performs a horizontal shake animation on the window to draw the user's attention.
    /// Does nothing if the window or its frame is unavailable.
    func shakeWindows(){
        let numberOfShakes:Int = 8
        let durationOfShake:Float = 0.5
        let vigourOfShake:Float = 0.05

        guard let frame = window?.frame else {
            return
        }
        let shakeAnimation = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x:NSMinX(frame), y:NSMinY(frame)))

        for _ in 1...numberOfShakes{
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) - frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) + frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
        }

        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        window?.animations = ["frameOrigin":shakeAnimation]
        if let windowFrame = window?.frame {
            window?.animator().setFrameOrigin(windowFrame.origin)
        }
    }
}