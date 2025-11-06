//
//  PACUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/9.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation
import Alamofire

let OldErrorPACRulesDirPath = NSHomeDirectory() + "/.ShadowsocksX-NE/"

let PACRulesDirPath = NSHomeDirectory() + "/.ShadowsocksX-NG/"
let PACUserRuleFilePath = PACRulesDirPath + "user-rule.txt"
let PACFilePath = PACRulesDirPath + "gfwlist.js"
let GFWListFilePath = PACRulesDirPath + "gfwlist.txt"


/// Checks whether the PAC file needs to be regenerated and triggers generation when required.
/// 
/// This updates stored previous SOCKS5 listen address and port in UserDefaults, checks for the presence of the generated PAC file, and invokes GeneratePACFile() if any change or missing file requires regeneration. If generation fails, a failure message is logged.
func SyncPac() {
    var needGenerate = false

    let nowSocks5Address = UserDefaults.standard.string(forKey: "LocalSocks5.ListenAddress")
    let oldSocks5Address = UserDefaults.standard.string(forKey: "LocalSocks5.ListenAddress.Old")
    if nowSocks5Address != oldSocks5Address {
        needGenerate = true
        UserDefaults.standard.set(nowSocks5Address, forKey: "LocalSocks5.ListenAddress.Old")
    }

    let nowSocks5Port = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort")
    let oldSocks5Port = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort.Old")
    if nowSocks5Port != oldSocks5Port {
        needGenerate = true
        UserDefaults.standard.set(nowSocks5Port, forKey: "LocalSocks5.ListenPort.Old")
    }

    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: PACFilePath) {
        needGenerate = true
    }

    if needGenerate {
        if !GeneratePACFile() {
            NSLog("GeneratePACFile failed!")
        }
    }
}


/// Generate PAC JavaScript and ensure required PAC rule files exist.
/// Ensures the PAC rules directory and source files are present, merges GFW list and user rules, injects the configured SOCKS5 address and port into the PAC template, and writes the resulting PAC JavaScript to disk.
/// - Returns: `true` if the PAC file was successfully generated and written to PACFilePath, `false` otherwise.
func GeneratePACFile() -> Bool {
    let fileMgr = FileManager.default
    // Maker the dir if rulesDirPath is not exesited.
    if !fileMgr.fileExists(atPath: PACRulesDirPath) {
        if fileMgr.fileExists(atPath: OldErrorPACRulesDirPath) {
            do {
                try fileMgr.moveItem(atPath: OldErrorPACRulesDirPath, toPath: PACRulesDirPath)
            } catch {
                ErrorHandler.shared.handle(
                    FileSystemError.writeFailed(path: PACRulesDirPath, error: error),
                    context: "Generate PAC File",
                    showAlert: true
                )
                return false
            }
        } else {
            do {
                try fileMgr.createDirectory(atPath: PACRulesDirPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                ErrorHandler.shared.handle(
                    FileSystemError.writeFailed(path: PACRulesDirPath, error: error),
                    context: "Generate PAC File",
                    showAlert: true
                )
                return false
            }
        }
    }

    // If gfwlist.txt is not exsited, copy from bundle
    if !fileMgr.fileExists(atPath: GFWListFilePath) {
        guard let src = Bundle.main.path(forResource: "gfwlist", ofType: "txt") else {
            ErrorHandler.shared.handle(
                ResourceError.resourceNotFound(name: "gfwlist", type: "txt"),
                context: "Generate PAC File",
                showAlert: true,
                critical: true
            )
            return false
        }
        do {
            try fileMgr.copyItem(atPath: src, toPath: GFWListFilePath)
        } catch {
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: GFWListFilePath, error: error),
                context: "Generate PAC File",
                showAlert: true
            )
            return false
        }
    }

    // If user-rule.txt is not exsited, copy from bundle
    if !fileMgr.fileExists(atPath: PACUserRuleFilePath) {
        guard let src = Bundle.main.path(forResource: "user-rule", ofType: "txt") else {
            ErrorHandler.shared.handle(
                ResourceError.resourceNotFound(name: "user-rule", type: "txt"),
                context: "Generate PAC File",
                showAlert: true,
                critical: true
            )
            return false
        }
        do {
            try fileMgr.copyItem(atPath: src, toPath: PACUserRuleFilePath)
        } catch {
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: PACUserRuleFilePath, error: error),
                context: "Generate PAC File",
                showAlert: true
            )
            return false
        }
    }

    guard let socks5Address = UserDefaults.standard.string(forKey: "LocalSocks5.ListenAddress") else {
        ErrorHandler.shared.handle(
            PACError.invalidFormat(reason: "LocalSocks5.ListenAddress not configured"),
            context: "Generate PAC File",
            showAlert: true,
            critical: true
        )
        return false
    }
    let socks5Port = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort")

    do {
        let gfwlist = try String(contentsOfFile: GFWListFilePath, encoding: String.Encoding.utf8)
        if let data = Data(base64Encoded: gfwlist, options: .ignoreUnknownCharacters) {
            guard let str = String(data: data, encoding: String.Encoding.utf8) else {
                ErrorHandler.shared.handle(
                    PACError.invalidFormat(reason: "Failed to decode GFW list data as UTF-8"),
                    context: "Generate PAC File",
                    showAlert: true
                )
                return false
            }
            var lines = str.components(separatedBy: CharacterSet.newlines)

            do {
                let userRuleStr = try String(contentsOfFile: PACUserRuleFilePath, encoding: String.Encoding.utf8)
                let userRuleLines = userRuleStr.components(separatedBy: CharacterSet.newlines)

                lines = userRuleLines + lines.filter { (line) in
                    // ignore the rule from gwf if user provide same rule for the same url
                    var i = line.startIndex
                    while i < line.endIndex {
                        if line[i] == "@" || line[i] == "|" {
                            i = line.index(after: i)
                            continue
                        }
                        break
                    }
                    if i == line.startIndex {
                        return !userRuleLines.contains(line)
                    }
                    return !userRuleLines.contains(String(line[i...]))
                }
            } catch {
                NSLog("Not found user-rule.txt")
            }

            // Filter empty and comment lines
            lines = lines.filter({ (s: String) -> Bool in
                if s.isEmpty {
                    return false
                }
                let c = s[s.startIndex]
                if c == "!" || c == "[" {
                    return false
                }
                return true
            })

            do {
                // rule lines to json array
                let rulesJsonData: Data
                    = try JSONSerialization.data(withJSONObject: lines, options: .prettyPrinted)
                let rulesJsonStr = String(data: rulesJsonData, encoding: String.Encoding.utf8)

                // Get raw pac js
                guard let jsPath = Bundle.main.url(forResource: "abp", withExtension: "js"),
                      let jsData = try? Data(contentsOf: jsPath),
                      var jsStr = String(data: jsData, encoding: String.Encoding.utf8),
                      let rulesJsonStr = rulesJsonStr else {
                    ErrorHandler.shared.warning("Failed to load or process PAC resources")
                    return false
                }

                // Replace rules placeholder in pac js
                jsStr = jsStr.replacingOccurrences(of: "__RULES__", with: rulesJsonStr)
                // Replace __SOCKS5PORT__ palcholder in pac js
                jsStr = jsStr.replacingOccurrences(of: "__SOCKS5PORT__", with: "\(socks5Port)")
                // Replace __SOCKS5ADDR__ palcholder in pac js
                var sin6 = sockaddr_in6()
                if socks5Address.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
                    jsStr = jsStr.replacingOccurrences(of: "__SOCKS5ADDR__", with: "[\(socks5Address)]")
                } else {
                    jsStr = jsStr.replacingOccurrences(of: "__SOCKS5ADDR__", with: socks5Address)
                }

                // Write the pac js to file.
                guard let jsData = jsStr.data(using: String.Encoding.utf8) else {
                    ErrorHandler.shared.warning("Failed to encode PAC JS string")
                    return false
                }
                try jsData.write(to: URL(fileURLWithPath: PACFilePath), options: .atomic)

                return true
            } catch {

            }
        }

    } catch {
        NSLog("Not found gfwlist.txt")
    }
    return false
}

/// Downloads the latest GFW list, saves it to the PAC rules directory, and regenerates the PAC file.
/// - Note: The URL is read from UserDefaults under the key `"GFWListURL"`.
/// - Side effects:
///   - Creates the PAC rules directory if it does not exist.
///   - Writes the downloaded GFW list to `GFWListFilePath`.
///   - Calls `GeneratePACFile()` to regenerate the PAC; when regeneration succeeds, posts a user notification indicating success.
///   - Posts a user notification on download failure and logs a warning if the `GFWListURL` setting is missing.
func UpdatePACFromGFWList() {
    // Make the dir if rulesDirPath is not exesited.
    if !FileManager.default.fileExists(atPath: PACRulesDirPath) {
        do {
            try FileManager.default.createDirectory(atPath: PACRulesDirPath
                , withIntermediateDirectories: true, attributes: nil)
        } catch {
        }
    }

    guard let url = UserDefaults.standard.string(forKey: "GFWListURL") else {
        ErrorHandler.shared.warning("GFWListURL not found in UserDefaults")
        return
    }
    AF.request(url)
        .validate()
        .responseString {
            response in
            switch response.result {
            case .success(let v):
                do {
                    try v.write(toFile: GFWListFilePath, atomically: true, encoding: String.Encoding.utf8)
                    if GeneratePACFile() {
                        // Popup a user notification
                        let notification = NSUserNotification()
                        notification.title = "PAC has been updated by latest GFW List.".localized
                        NSUserNotificationCenter.default
                            .deliver(notification)
                    }
                } catch {

                }
            case .failure:
                // Popup a user notification
                let notification = NSUserNotification()
                notification.title = "Failed to download latest GFW List.".localized
                NSUserNotificationCenter.default
                    .deliver(notification)
            }
        }
}