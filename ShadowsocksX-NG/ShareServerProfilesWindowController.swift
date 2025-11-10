//
//  ShareServerProfilesWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 2018/9/16.
//  Copyright © 2018年 qiuyuzhou. All rights reserved.
//

import Cocoa

class ShareServerProfilesWindowController: NSWindowController
    , NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var profilesTableView: NSTableView!

    @IBOutlet weak var qrCodeImageView: NSImageView!

    @IBOutlet weak var copyAllServerURLsButton: NSButton!
    @IBOutlet weak var saveAllServerURLsAsFileButton: NSButton!

    @IBOutlet weak var copyURLButton: NSButton!
    @IBOutlet weak var copyQRCodeButton: NSButton!
    @IBOutlet weak var saveQRCodeAsFileButton: NSButton!

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

    override func windowDidLoad() {
        super.windowDidLoad()

        if profileManager == nil {
            profileManager = ServerProfileManager.instance
        }
        profilesTableView.reloadData()

        if !serverProfileManager.profiles.isEmpty {
            let index = IndexSet(integer: 0)
            profilesTableView.selectRowIndexes(index, byExtendingSelection: false)
        } else {
            copyAllServerURLsButton.isEnabled = false
            saveAllServerURLsAsFileButton.isEnabled = false
            copyURLButton.isEnabled = false
            copyQRCodeButton.isEnabled = false
            saveQRCodeAsFileButton.isEnabled = false
        }
    }

    @IBAction func copyURL(_ sender: NSButton) {
        let profile = getSelectedProfile()
        if profile.isValid(), let url = profile.URL() {
            let pb = NSPasteboard.general
            pb.clearContents()
            if pb.writeObjects([url.absoluteString as NSPasteboardWriting]) {
                ErrorHandler.shared.debug("Copy URL to clipboard", context: "ShareProfiles")
            } else {
                ErrorHandler.shared.warning("Failed to copy URL to clipboard", context: "ShareProfiles")
            }
        }
    }

    @IBAction func copyQRCode(_ sender: NSButton) {
        if let img = qrCodeImageView.image {
            let pb = NSPasteboard.general
            pb.clearContents()
            if pb.writeObjects([img as NSPasteboardWriting]) {
                ErrorHandler.shared.debug("Copy QRCode to clipboard", context: "ShareProfiles")
            } else {
                ErrorHandler.shared.warning("Failed to copy QRCode to clipboard", context: "ShareProfiles")
            }
        }
    }

    @IBAction func saveQRCodeAsFile(_ sender: NSButton) {
        if let img = qrCodeImageView.image {
            let savePanel = NSSavePanel()
            savePanel.title = "Save QRCode As File".localized
            savePanel.canCreateDirectories = true
            savePanel.allowedFileTypes = ["gif"]
            savePanel.isExtensionHidden = false

            let profile = getSelectedProfile()
            if profile.remark.isEmpty {
                savePanel.nameFieldStringValue = "shadowsocks_qrcode.gif"
            } else {
                savePanel.nameFieldStringValue = "shadowsocks_qrcode_\(profile.remark).gif"
            }

            savePanel.becomeKey()
            let result = savePanel.runModal()
            if (result == .OK && (savePanel.url) != nil) {
                guard let tiffData = img.tiffRepresentation,
                      let imgRep = NSBitmapImageRep(data: tiffData),
                      let data = imgRep.representation(using: NSBitmapImageRep.FileType.gif, properties: [:]),
                      let url = savePanel.url else {
                    ErrorHandler.shared.warning("Failed to prepare QR code image for saving")
                    return
                }
                do {
                    try data.write(to: url)
                } catch {
                    ErrorHandler.shared.handle(
                        FileSystemError.writeFailed(path: url.path, error: error),
                        context: "Save QR Code",
                        showAlert: true
                    )
                }
            }
        }
    }

    @IBAction func copyAllServerURLs(_ sender: NSButton) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if pb.writeObjects([getAllServerURLs() as NSPasteboardWriting]) {
            ErrorHandler.shared.debug("Copy all server URLs to clipboard", context: "ShareProfiles")
        } else {
            ErrorHandler.shared.warning("Failed to all server URLs to clipboard", context: "ShareProfiles")
        }
    }

    @IBAction func saveAllServerURLsAsFile(_ sender: NSButton) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let date_string = formatter.string(from: Date())

        let savePanel = NSSavePanel()
        savePanel.title = "Save All Server URLs To File".localized
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "shadowsocks_profiles_\(date_string).txt"
        savePanel.becomeKey()
        let result = savePanel.runModal()
        if (result == .OK) {
            guard let url = savePanel.url else {
                ErrorHandler.shared.warning("No URL selected for saving")
                return
            }
            let urls = getAllServerURLs()
            do {
                try urls.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                ErrorHandler.shared.handle(
                    FileSystemError.writeFailed(path: url.path, error: error),
                    context: "Export Server URLs",
                    showAlert: true
                )
            }
        }
    }

    func getAllServerURLs() -> String {
        let urls = serverProfileManager.profiles.filter({ (profile) -> Bool in
            return profile.isValid()
        }).compactMap { (profile) -> String? in
            return profile.URL()?.absoluteString
        }
        return urls.joined(separator: "\n")
    }

    func getSelectedProfile() -> ServerProfile {
        let i = profilesTableView.selectedRow
        return serverProfileManager.profiles[i]
    }

    func getDataAtRow(_ index:Int) -> String {
        let profile = serverProfileManager.profiles[index]
        if !profile.remark.isEmpty {
            return profile.remark
        } else {
            return profile.serverHost
        }
    }

    //--------------------------------------------------
    // For NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return serverProfileManager.profiles.count
    }

    //--------------------------------------------------
    // For NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let colId = NSUserInterfaceItemIdentifier(rawValue: "cellTitle")
        if let cell = tableView.makeView(withIdentifier: colId, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = getDataAtRow(row)
            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if profilesTableView.selectedRow >= 0 {
            let profile = getSelectedProfile()
            if profile.isValid(), let url = profile.URL() {
                let img = createQRImage(url.absoluteString, NSMakeSize(250, 250))
                qrCodeImageView.image = img

                copyURLButton.isEnabled = true
                copyQRCodeButton.isEnabled = true
                saveQRCodeAsFileButton.isEnabled = true
                return
            }
        }
        qrCodeImageView.image = nil

        copyURLButton.isEnabled = false
        copyQRCodeButton.isEnabled = false
        saveQRCodeAsFileButton.isEnabled = false
    }
}
