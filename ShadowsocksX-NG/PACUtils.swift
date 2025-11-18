//
//  PACUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/9.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Alamofire
import Foundation

let oldErrorPACRulesDirPath = NSHomeDirectory() + "/.ShadowsocksX-NE/"

let PACRulesDirPath = NSHomeDirectory() + "/.ShadowsocksX-NG/"
let PACUserRuleFilePath = PACRulesDirPath + "user-rule.txt"
let PACFilePath = PACRulesDirPath + "gfwlist.js"
let GFWListFilePath = PACRulesDirPath + "gfwlist.txt"

// Because of LocalSocks5.ListenPort may be changed
func syncPac() {
    var needGenerate = false

    let nowSocks5Address = AppPreferences.socksAddress
    let oldSocks5Address = UserDefaults.standard.string(forKey: "LocalSocks5.ListenAddress.Old")
    if nowSocks5Address != oldSocks5Address {
        needGenerate = true
        UserDefaults.standard.set(nowSocks5Address, forKey: "LocalSocks5.ListenAddress.Old")
    }

    let nowSocks5Port = AppPreferences.socksPort
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
        if !generatePACFile() {
            ErrorHandler.shared.warning("generatePACFile failed!", context: "PAC")
        }
    }
}

// swiftlint:disable function_body_length cyclomatic_complexity
// TODO: Refactor generatePACFile - decompose into helper functions (Phase 2)
func generatePACFile() -> Bool {
    let fileMgr = FileManager.default
    // Maker the dir if rulesDirPath is not exesited.
    if !fileMgr.fileExists(atPath: PACRulesDirPath) {
        if fileMgr.fileExists(atPath: oldErrorPACRulesDirPath) {
            do {
                try fileMgr.moveItem(atPath: oldErrorPACRulesDirPath, toPath: PACRulesDirPath)
            } catch {
                ErrorHandler.shared.handle(
                    FileSystemError.moveFailed(
                        source: oldErrorPACRulesDirPath, destination: PACRulesDirPath, error: error),
                    context: "Generate PAC File",
                    showAlert: true
                )
                return false
            }
        } else {
            do {
                try fileMgr.createDirectory(
                    atPath: PACRulesDirPath, withIntermediateDirectories: true, attributes: nil)
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
                FileSystemError.copyFailed(source: src, destination: GFWListFilePath, error: error),
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
                FileSystemError.copyFailed(
                    source: src, destination: PACUserRuleFilePath, error: error),
                context: "Generate PAC File",
                showAlert: true
            )
            return false
        }
    }

    let socks5Address = AppPreferences.socksAddress
    let socks5Port = AppPreferences.socksPort

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
                let userRuleStr = try String(
                    contentsOfFile: PACUserRuleFilePath, encoding: String.Encoding.utf8)
                let userRuleLines = userRuleStr.components(separatedBy: CharacterSet.newlines)

                lines =
                    userRuleLines
                    + lines.filter { (line) in
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
                ErrorHandler.shared.debug("Not found user-rule.txt", context: "PAC")
            }

            // Filter empty and comment lines
            lines = lines.filter({ (line: String) -> Bool in
                if line.isEmpty {
                    return false
                }
                let character: Character = line[line.startIndex]
                if character == "!" || character == "[" {
                    return false
                }
                return true
            })

            do {
                // rule lines to json array
                let rulesJsonData: Data = try JSONSerialization.data(
                    withJSONObject: lines, options: .prettyPrinted)
                let rulesJsonStr = String(data: rulesJsonData, encoding: String.Encoding.utf8)

                // Get raw pac js
                guard let jsPath = Bundle.main.url(forResource: "abp", withExtension: "js") else {
                    ErrorHandler.shared.handle(
                        ResourceError.resourceNotFound(name: "abp", type: "js"),
                        context: "Generate PAC File",
                        showAlert: true
                    )
                    return false
                }
                let jsData: Data
                do {
                    jsData = try Data(contentsOf: jsPath)
                } catch {
                    ErrorHandler.shared.handle(
                        FileSystemError.readFailed(path: jsPath.path, error: error),
                        context: "Generate PAC File",
                        showAlert: true
                    )
                    return false
                }
                guard var jsStr = String(data: jsData, encoding: String.Encoding.utf8) else {
                    ErrorHandler.shared.handle(
                        PACError.invalidFormat(reason: "Failed to decode abp.js as UTF-8"),
                        context: "Generate PAC File",
                        showAlert: true
                    )
                    return false
                }
                guard let rulesJsonStr = rulesJsonStr else {
                    ErrorHandler.shared.handle(
                        PACError.invalidFormat(reason: "Failed to encode rules as JSON string"),
                        context: "Generate PAC File",
                        showAlert: true
                    )
                    return false
                }

                // Replace rules placeholder in pac js
                jsStr = jsStr.replacingOccurrences(of: "__RULES__", with: rulesJsonStr)
                // Replace __SOCKS5PORT__ palcholder in pac js
                jsStr = jsStr.replacingOccurrences(of: "__SOCKS5PORT__", with: "\(socks5Port)")
                // Replace __SOCKS5ADDR__ palcholder in pac js
                var sin6 = sockaddr_in6()
                if socks5Address.withCString({ cstring in
                    inet_pton(AF_INET6, cstring, &sin6.sin6_addr)
                }) == 1 {
                    jsStr = jsStr.replacingOccurrences(
                        of: "__SOCKS5ADDR__", with: "[\(socks5Address)]")
                } else {
                    jsStr = jsStr.replacingOccurrences(of: "__SOCKS5ADDR__", with: socks5Address)
                }

                // Write the pac js to file.
                guard let jsData = jsStr.data(using: String.Encoding.utf8) else {
                    ErrorHandler.shared.handle(
                        PACError.invalidFormat(reason: "Failed to encode PAC JS string as UTF-8"),
                        context: "Generate PAC File",
                        showAlert: true
                    )
                    return false
                }
                try jsData.write(to: URL(fileURLWithPath: PACFilePath), options: .atomic)

                return true
            } catch {
                ErrorHandler.shared.handle(
                    error,
                    context: "Failed to generate PAC file (JSON serialization or file write)",
                    showAlert: false
                )
                return false
            }
        } else {
            ErrorHandler.shared.handle(
                PACError.invalidFormat(reason: "Failed to decode GFW list base64"),
                context: "Generate PAC File",
                showAlert: true
            )
            return false
        }

    } catch {
        ErrorHandler.shared.handle(
            FileSystemError.readFailed(path: GFWListFilePath, error: error),
            context: "Generate PAC File",
            showAlert: true
        )
    }
    return false
}
// swiftlint:enable function_body_length cyclomatic_complexity

/// Generates PAC file asynchronously on background thread
/// - Returns: True if generation succeeded
func generatePACFileAsync() async -> Bool {
    await Task.detached {
        generatePACFile()
    }.value
}

func updatePACFromGFWList() {
    // Make the dir if rulesDirPath is not exesited.
    if !FileManager.default.fileExists(atPath: PACRulesDirPath) {
        do {
            try FileManager.default.createDirectory(
                atPath: PACRulesDirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: PACRulesDirPath, error: error),
                context: "Update PAC from GFW List",
                showAlert: true
            )
            return
        }
    }

    let url = AppPreferences.gfwListURL
    AF.request(url)
        .validate()
        .responseString {
            response in
            switch response.result {
            case .success(let v):
                do {
                    try v.write(
                        toFile: GFWListFilePath, atomically: true, encoding: String.Encoding.utf8)
                    if generatePACFile() {
                        // Popup a user notification
                        NotificationService.shared.send(title: "PAC has been updated by latest GFW List.".localized)
                    }
                } catch {
                    ErrorHandler.shared.handle(
                        FileSystemError.writeFailed(path: GFWListFilePath, error: error),
                        context: "Update PAC from GFW List - write file",
                        showAlert: true
                    )
                }
            case .failure:
                // Popup a user notification
                NotificationService.shared.send(title: "Failed to download latest GFW List.".localized)
            }
        }
}

// MARK: - Async/Await Version

/// Updates PAC file from GFW List (async version)
/// - Returns: True if update and generation succeeded
/// - Throws: PACError or FileSystemError on failure
func updatePACFromGFWListAsync() async throws -> Bool {
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: PACRulesDirPath) {
        try FileManager.default.createDirectory(
            atPath: PACRulesDirPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    let urlString = AppPreferences.gfwListURL

    // Download GFW List using continuation to bridge callback-based API
    let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
        AF.request(urlString)
            .validate()
            .responseString { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
    }

    // Write to file on background thread
    try await Task.detached {
        try data.write(
            toFile: GFWListFilePath,
            atomically: true,
            encoding: String.Encoding.utf8
        )
    }.value

    // Generate PAC file asynchronously
    let success = await generatePACFileAsync()

    // Send notification on main thread
    await MainActor.run {
        if success {
            NotificationService.shared.send(
                title: "PAC has been updated by latest GFW List.".localized
            )
        }
    }

    return success
}
