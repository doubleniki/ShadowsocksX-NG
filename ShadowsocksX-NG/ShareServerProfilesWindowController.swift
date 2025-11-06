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

    var defaults: UserDefaults!
    var profileMgr: ServerProfileManager!

    /// Initializes the window controller: loads user defaults and the shared profile manager, refreshes the profiles table, selects the first profile if any exist, and updates related UI controls (enables actions when profiles are present; disables copy/save buttons when none).
    override func windowDidLoad() {
        super.windowDidLoad()

        defaults = UserDefaults.standard
        profileMgr = ServerProfileManager.instance
        profilesTableView.reloadData()

        if !profileMgr.profiles.isEmpty {
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

    /// Copies the selected profile's server URL string to the general pasteboard.
    /// Does nothing if there is no selected profile or the selected profile does not provide a URL.
    @IBAction func copyURL(_ sender: NSButton) {
        let profile = getSelectedProfile()
        if profile.isValid(), let url = profile.URL() {
            let pb = NSPasteboard.general
            pb.clearContents()
            if pb.writeObjects([url.absoluteString as NSPasteboardWriting]) {
                NSLog("Copy URL to clipboard")
            } else {
                NSLog("Failed to copy URL to clipboard")
            }
        }
    }

    /// Copies the QR code currently displayed in `qrCodeImageView` to the general pasteboard.
    /// 
    /// If `qrCodeImageView` has an image, the image is written to the general pasteboard; if there is no image, the method does nothing.
    @IBAction func copyQRCode(_ sender: NSButton) {
        if let img = qrCodeImageView.image {
            let pb = NSPasteboard.general
            pb.clearContents()
            if pb.writeObjects([img as NSPasteboardWriting]) {
                NSLog("Copy QRCode to clipboard")
            } else {
                NSLog("Failed to copy QRCode to clipboard")
            }
        }
    }

    /// Presents a save dialog to export the displayed QR code image as a GIF file.
    /// 
    /// If a QR code image is present, a save panel is shown with a default filename derived from the selected profile's remark. The image is converted to GIF data and written to the chosen file URL. Failures preparing the image or writing the file are reported via the shared ErrorHandler.
    — Parameters:
      - sender: The button that initiated the save action.
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
            if (result.rawValue == NSFileHandlingPanelOKButton && (savePanel.url) != nil) {
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

    /// Copies all saved server profile URLs to the general pasteboard.
    /// Writes a newline-separated list of all server profile URLs to the general pasteboard and logs whether the copy succeeded or failed.
    @IBAction func copyAllServerURLs(_ sender: NSButton) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if pb.writeObjects([getAllServerURLs() as NSPasteboardWriting]) {
            NSLog("Copy all server URLs to clipboard")
        } else {
            NSLog("Failed to all server URLs to clipboard")
        }
    }

    /// Presents a Save panel to export all server profile URLs to a TXT file named "shadowsocks_profiles_yyyyMMdd.txt".
    /// If the user confirms a destination, collects all server URLs, writes them as UTF-8 text to the selected file, and reports any write failures to `ErrorHandler.shared` with the context "Export Server URLs".
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
        if (result.rawValue == NSFileHandlingPanelOKButton) {
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

    /// Collects the absolute URL strings of all valid server profiles and joins them with newline characters.
    /// Profiles that are invalid or do not have a URL are skipped.
    /// - Returns: A single string containing each profile URL's `absoluteString` separated by `\n`; an empty string if no URLs are available.
    func getAllServerURLs() -> String {
        let urls = profileMgr.profiles.filter({ (profile) -> Bool in
            return profile.isValid()
        }).compactMap { (profile) -> String? in
            return profile.URL()?.absoluteString
        }
        return urls.joined(separator: "\n")
    }

    /// Get the ServerProfile for the currently selected table row.
    /// - Returns: The `ServerProfile` at the table view's selected row. Assumes a valid selection; if no row is selected or the index is out of range, accessing this may trigger a runtime error.
    func getSelectedProfile() -> ServerProfile {
        let i = profilesTableView.selectedRow
        return profileMgr.profiles[i]
    }

    /// Provide the display text for the profile at the given table row.
    /// - Parameters:
    ///   - index: The table row index of the profile.
    /// - Returns: The profile's `remark` if it is not empty, otherwise the profile's `serverHost`.
    func getDataAtRow(_ index:Int) -> String {
        let profile = profileMgr.profiles[index]
        if !profile.remark.isEmpty {
            return profile.remark
        } else {
            return profile.serverHost
        }
    }

    //--------------------------------------------------
    /// Provides the number of server profiles available to display in the table view.
    /// - Returns: The count of profiles managed by `profileMgr`, or `0` if the manager is unavailable.

    func numberOfRows(in tableView: NSTableView) -> Int {
        if let mgr = profileMgr {
            return mgr.profiles.count
        }
        return 0
    }

    //--------------------------------------------------
    /// Provides the table cell view that displays the profile title for a given row.
    /// - Parameters:
    ///   - tableView: The table view requesting the view.
    ///   - tableColumn: The column for which the view is requested (ignored; single-column layout).
    ///   - row: The row index whose data will be displayed.
    /// - Returns: An `NSTableCellView` with its text field set to the profile title for `row`, or `nil` if a view could not be created.

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let colId = NSUserInterfaceItemIdentifier(rawValue: "cellTitle")
        if let cell = tableView.makeView(withIdentifier: colId, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = getDataAtRow(row)
            return cell
        }
        return nil
    }

    /// Updates the QR code preview and related action buttons when the table selection changes.
    /// 
    /// If the newly selected profile is valid and has a URL, generates a 250×250 QR code for that URL,
    /// assigns it to `qrCodeImageView`, and enables the copy/save buttons. Otherwise clears the image
    /// and disables those buttons.
    /// - Parameter notification: The selection-change `Notification` issued by the table view.
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