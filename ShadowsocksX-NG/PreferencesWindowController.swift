//
//  PreferencesWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa
import Foundation
import RxCocoa
import RxSwift

class PreferencesWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

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

    private var profileManager: ServerProfileManaging?
    private var serverProfileManager: ServerProfileManaging {
        get {
            if let profileManager = profileManager {
                return profileManager
            }
            let fallback = ServerProfileManager.instance
            self.profileManager = fallback
            return fallback
        }
        set {
            profileManager = newValue
        }
    }

    func configure(profileManager: ServerProfileManaging) {
        self.profileManager = profileManager
    }

    var editingProfile: ServerProfile?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

        if profileManager == nil {
            profileManager = ServerProfileManager.instance
        }

        // Populate encryption methods from enum
        methodTextField.addItems(withObjectValues: EncryptionMethod.allCases.map { $0.rawValue })

        profilesTableView.reloadData()
        updateProfileBoxVisible()
    }

    override func awakeFromNib() {
        profilesTableView.registerForDraggedTypes([
            NSPasteboard.PasteboardType(rawValue: tableViewDragType)
        ])
        profilesTableView.allowsMultipleSelection = true
    }

    @IBAction func addProfile(_ sender: NSButton) {
        if let profile = editingProfile, !profile.isValid() {
            shakeWindows()
            return
        }
        profilesTableView.beginUpdates()
        let profile = ServerProfile()
        profile.remark = "New Server".localized
        serverProfileManager.profiles.append(profile)

        let index = IndexSet(integer: serverProfileManager.profiles.count - 1)
        profilesTableView.insertRows(
            at: index, withAnimation: NSTableView.AnimationOptions.effectFade)

        self.profilesTableView.scrollRowToVisible(self.serverProfileManager.profiles.count - 1)
        self.profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
        profilesTableView.endUpdates()
        updateProfileBoxVisible()
    }

    @IBAction func removeProfile(_ sender: NSButton) {
        guard let firstIndex = profilesTableView.selectedRowIndexes.first else {
            return
        }
        var deleteCount = 0
        profilesTableView.beginUpdates()
        for (_, toDeleteIndex) in profilesTableView.selectedRowIndexes.enumerated() {
            ErrorHandler.shared.debug(
                "Profile count before deletion: \(serverProfileManager.profiles.count)",
                context: "PreferencesWindowController.removeProfile")
            let profile = serverProfileManager.profiles[toDeleteIndex - deleteCount]
            // Remove password from Keychain before deleting profile
            profile.removePasswordFromKeychain()
            serverProfileManager.profiles.remove(at: toDeleteIndex - deleteCount)
            profilesTableView.removeRows(
                at: IndexSet(integer: toDeleteIndex - deleteCount),
                withAnimation: NSTableView.AnimationOptions.effectFade
            )
            deleteCount += 1
        }
        profilesTableView.endUpdates()

        // Clear stale editing state so delegate logic allows reselection.
        editingProfile = nil

        // Select the row before the first deleted row, or 0 if we deleted from the start
        let newSelectedIndex = max(0, firstIndex - 1)
        if !serverProfileManager.profiles.isEmpty {
            self.profilesTableView.scrollRowToVisible(newSelectedIndex)
            self.profilesTableView.selectRowIndexes(
                IndexSet(integer: newSelectedIndex), byExtendingSelection: false)
        }
        updateProfileBoxVisible()
    }

    @IBAction func ok(_ sender: NSButton) {
        if let profile = editingProfile, !profile.isValid() {
            // TODO Shake window?
            shakeWindows()
            return
        }
        serverProfileManager.save()
        window?.performClose(nil)

        NotificationCenter.default
            .post(name: Constants.Notification.serverProfilesChanged, object: nil)
    }

    @IBAction func cancel(_ sender: NSButton) {
        serverProfileManager.reload()
        window?.performClose(self)
    }

    @IBAction func duplicate(_ sender: Any) {
        // Process indices in reverse order so that insertions don't affect unprocessed indices
        let selectedIndices = Array(profilesTableView.selectedRowIndexes).sorted(by: >)
        var newSelectionIndices = IndexSet()

        for originalIndex in selectedIndices {
            ErrorHandler.shared.debug(
                "Duplicating profile at index \(originalIndex), total profiles count: \(serverProfileManager.profiles.count)"
            )

            guard originalIndex < serverProfileManager.profiles.count else {
                ErrorHandler.shared.warning("Invalid profile index \(originalIndex)")
                continue
            }

            let profile = serverProfileManager.profiles[originalIndex]

            // Copy profile (password is cached but not saved to Keychain yet)
            guard let duplicateProfile = profile.copy() as? ServerProfile else {
                ErrorHandler.shared.warning("Failed to copy server profile")
                continue
            }

            // Set new UUID
            duplicateProfile.uuid = UUID().uuidString

            // Password is already in cache from copy(), so when we access it via the getter,
            // it will return the cached value. Setting it explicitly ensures it's saved to
            // Keychain under the new UUID
            let passwordToSave = duplicateProfile.password
            duplicateProfile.password = passwordToSave

            // Insert immediately after the source profile
            let insertIndex = originalIndex + 1
            serverProfileManager.profiles.insert(duplicateProfile, at: insertIndex)

            profilesTableView.beginUpdates()
            let index = IndexSet(integer: insertIndex)
            profilesTableView.insertRows(
                at: index, withAnimation: NSTableView.AnimationOptions.effectFade)
            profilesTableView.endUpdates()

            // Adjust previously collected indices that were shifted by this insertion
            // When inserting at insertIndex, all indices >= insertIndex shift up by 1
            newSelectionIndices = IndexSet(
                newSelectionIndices.map { $0 >= insertIndex ? $0 + 1 : $0 })
            newSelectionIndices.insert(insertIndex)
        }

        // Select all duplicated profiles and scroll to the first one
        if let firstIndex = newSelectionIndices.min() {
            profilesTableView.selectRowIndexes(newSelectionIndices, byExtendingSelection: false)
            profilesTableView.scrollRowToVisible(firstIndex)
        }

        updateProfileBoxVisible()
    }

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

    @IBAction func openPluginHelp(_ sender: Any) {
        guard
            let url = URL(
                string: "https://github.com/shadowsocks/ShadowsocksX-NG/wiki/SIP003-Plugin")
        else {
            ErrorHandler.shared.warning("Invalid plugin help URL")
            return
        }
        NSWorkspace.shared.open(url)
    }

    @IBAction func openPluginFolder(_ sender: Any) {
        let folderPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/ShadowsocksX-NG")
            .appendingPathComponent("plugins")
        NSWorkspace.shared.open(folderPath)
    }

    @IBAction func copyCurrentProfileURL2Pasteboard(_ sender: NSButton) {
        let index = profilesTableView.selectedRow
        if index >= 0 {
            let profile = serverProfileManager.profiles[index]
            let ssURL = profile.URL()
            if let url = ssURL {
                // Then copy url to pasteboard
                // TODO Why it not working?? It's ok in objective-c
                let pboard = NSPasteboard.general
                pboard.clearContents()
                let rs = pboard.writeObjects([url as NSPasteboardWriting])
                if rs {
                    ErrorHandler.shared.debug("copy to pasteboard success", context: "Preferences")
                } else {
                    ErrorHandler.shared.warning("copy to pasteboard failed", context: "Preferences")
                }
            }
        }
    }

    func updateProfileBoxVisible() {
        if serverProfileManager.profiles.isEmpty {
            removeButton.isEnabled = false
        } else {
            removeButton.isEnabled = true
        }

        if serverProfileManager.profiles.isEmpty {
            profileBox.isHidden = true
        } else {
            profileBox.isHidden = false
        }
    }

    func bindProfile(_ index: Int) {
        ErrorHandler.shared.debug("bind profile \(index)", context: "Preferences")

        if index >= 0 && index < serverProfileManager.profiles.count {
            let selectedProfile = serverProfileManager.profiles[index]
            self.editingProfile = selectedProfile

            hostTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "serverHost",
                options: [NSBindingOption.continuouslyUpdatesValue: true])
            portTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "serverPort",
                options: [NSBindingOption.continuouslyUpdatesValue: true])

            methodTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "method",
                options: [NSBindingOption.continuouslyUpdatesValue: true])
            passwordTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "password",
                options: [NSBindingOption.continuouslyUpdatesValue: true])
            passwordSecureTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "password",
                options: [NSBindingOption.continuouslyUpdatesValue: true])

            pluginTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "plugin",
                options: [NSBindingOption.continuouslyUpdatesValue: true])
            pluginOptionsTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "pluginOptions",
                options: [NSBindingOption.continuouslyUpdatesValue: true])

            remarkTextField.bind(
                NSBindingName(rawValue: "value"), to: selectedProfile, withKeyPath: "remark",
                options: [NSBindingOption.continuouslyUpdatesValue: true])
        } else {
            self.editingProfile = nil
            hostTextField.unbind(NSBindingName(rawValue: "value"))
            portTextField.unbind(NSBindingName(rawValue: "value"))

            methodTextField.unbind(NSBindingName(rawValue: "value"))
            passwordTextField.unbind(NSBindingName(rawValue: "value"))
            passwordSecureTextField.unbind(NSBindingName(rawValue: "value"))

            pluginTextField.unbind(NSBindingName(rawValue: "value"))
            pluginOptionsTextField.unbind(NSBindingName(rawValue: "value"))

            remarkTextField.unbind(NSBindingName(rawValue: "value"))
        }
    }

    func getDataAtRow(_ index: Int) -> (String, Bool) {
        let profile = serverProfileManager.profiles[index]
        let isActive = (serverProfileManager.activeProfileId == profile.uuid)
        if !profile.remark.isEmpty {
            return (String(profile.remark.prefix(24)), isActive)
        } else {
            return (profile.serverHost, isActive)
        }
    }

    //--------------------------------------------------
    // For NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return serverProfileManager.profiles.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int)
        -> Any?
    {

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

    // Drag & Drop reorder rows

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int)
        -> NSPasteboardWriting?
    {
        let item = NSPasteboardItem()
        item.setString(
            String(row), forType: NSPasteboard.PasteboardType(rawValue: tableViewDragType))
        return item
    }

    func tableView(
        _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return NSDragOperation()
    }

    func tableView(
        _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        var mgr = serverProfileManager
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(
            options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:],
            using: {
                (draggingItem: NSDraggingItem, _, _) in
                guard let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                    let str = pasteboardItem.string(
                        forType: NSPasteboard.PasteboardType(rawValue: self.tableViewDragType)),
                    let index = Int(str)
                else {
                    return
                }
                oldIndexes.append(index)
            })

        var oldIndexOffset = 0
        var newIndexOffset = 0

        tableView.beginUpdates()
        for oldIndex in oldIndexes {
            if oldIndex < row {
                let o = mgr.profiles.remove(at: oldIndex + oldIndexOffset)
                mgr.profiles.insert(o, at: row - 1)
                tableView.moveRow(at: oldIndex + oldIndexOffset, to: row - 1)
                oldIndexOffset -= 1
            } else {
                let o = mgr.profiles.remove(at: oldIndex)
                mgr.profiles.insert(o, at: row + newIndexOffset)
                tableView.moveRow(at: oldIndex, to: row + newIndexOffset)
                newIndexOffset += 1
            }
        }
        tableView.endUpdates()

        return true
    }

    //--------------------------------------------------
    // For NSTableViewDelegate

    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int)
        -> Bool
    {
        return false
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if row < 0 {
            editingProfile = nil
            return true
        }
        if let profile = editingProfile, !profile.isValid() {
            return false
        }

        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if profilesTableView.selectedRow >= 0 {
            bindProfile(profilesTableView.selectedRow)
        } else if !serverProfileManager.profiles.isEmpty {
            let index = IndexSet(integer: serverProfileManager.profiles.count - 1)
            profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
        }
    }

    func shakeWindows() {
        let numberOfShakes: Int = 8
        let durationOfShake: Float = 0.5
        let vigourOfShake: Float = 0.05

        guard let frame = window?.frame else {
            return
        }
        let shakeAnimation = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: NSMinX(frame), y: NSMinY(frame)))

        for _ in 1...numberOfShakes {
            shakePath.addLine(
                to: CGPoint(
                    x: NSMinX(frame) - frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
            shakePath.addLine(
                to: CGPoint(
                    x: NSMinX(frame) + frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
        }

        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        window?.animations = ["frameOrigin": shakeAnimation]
        if let windowFrame = window?.frame {
            window?.animator().setFrameOrigin(windowFrame.origin)
        }
    }
}
