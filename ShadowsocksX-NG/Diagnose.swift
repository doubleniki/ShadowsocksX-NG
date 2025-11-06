//
//  diagnose.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 2018/10/2.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//

import Foundation

func shell(_ args: String...) -> String {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return output ?? ""
}

/// Produce a diagnostic report containing app metadata, preferences, the active server profile, and selected system command outputs.
/// 
/// The report includes the app's Info.plist serialized as pretty-printed JSON (or an inline error message if unavailable or serialization fails), listed UserDefaults keys and values for a predefined set of preferences, the active server profile debug string (or a message if none), and the outputs of several shell commands. Sections are separated by delimiter lines for readability.
/// - Returns: A single string containing the assembled diagnostic report; any errors encountered while gathering information are included inline as human-readable messages.
func diagnose() -> String {
    var strs = [String]()
    
    strs.append("\n-----------------------------------\n")

    // Safe access to bundle info dictionary
    guard let infoDict = Bundle.main.infoDictionary else {
        strs.append("ERROR: Could not access bundle info dictionary\n")
        strs.append("\n-----------------------------------\n")
        return strs.joined()
    }

    do {
        let infoDictJsonData = try JSONSerialization.data(withJSONObject: infoDict, options: JSONSerialization.WritingOptions.prettyPrinted)
        if let jsonString = String(data: infoDictJsonData, encoding: String.Encoding.utf8) {
            strs.append(jsonString)
        } else {
            strs.append("ERROR: Could not encode info dictionary as UTF-8\n")
        }
    } catch {
        strs.append("ERROR: Failed to serialize info dictionary: \(error.localizedDescription)\n")
    }

    strs.append("\n-----------------------------------\n")
    
    let defaults = UserDefaults.standard
    let keys = [
        "ShadowsocksOn",
        "ShadowsocksRunningMode",
        "LocalSocks5.ListenPort",
        "LocalSocks5.ListenAddress",
        "PacServer.BindToLocalhost",
        "PacServer.ListenPort",
        "LocalSocks5.Timeout",
        "LocalSocks5.EnableUDPRelay",
        "LocalSocks5.EnableVerboseMode",
        "GFWListURL",
        "LocalHTTP.ListenAddress",
        "LocalHTTP.ListenPort",
        "LocalHTTPOn",
        "LocalHTTP.FollowGlobal",
        "ProxyExceptions",
        ]
    
    strs.append("Preferences:\n")
    for key in keys {
        if let obj = defaults.object(forKey: key) {
            strs.append("\(key)=\(obj)\n")
        }
    }
    strs.append("-----------------------------------\n")
    strs.append("Active server profile: \n")
    
    if let profile = ServerProfileManager.instance.getActiveProfile() {
        strs.append(profile.debugString())
    } else {
        strs.append("No actived server profile!")
    }
    
    strs.append("-----------------------------------\n")
    strs.append("$ ls -l ~/Library/Application Support/ShadowsocksX-NG/\n")
    strs.append(shell("ls", "-l", NSHomeDirectory() + "/Library/Application Support/ShadowsocksX-NG/"))
    strs.append("-----------------------------------\n")
    strs.append("$ ls -l ~/Library/LaunchAgents/\n")
    strs.append(shell("ls", "-l", NSHomeDirectory() + "/Library/LaunchAgents/"))
    strs.append("-----------------------------------\n")
    strs.append("$ ls -l ~/.ShadowsocksX-NG/\n")
    strs.append(shell("ls", "-l", NSHomeDirectory() + "/.ShadowsocksX-NG/"))
    strs.append("-----------------------------------\n")
    strs.append("$ ls -l /Library/Application Support/ShadowsocksX-NG/\n")
    strs.append(shell("ls", "-l", "/Library/Application Support/ShadowsocksX-NG/"))
    strs.append("-----------------------------------\n")
    strs.append("$ lsof -PiTCP -sTCP:LISTEN\n")
    strs.append(shell("lsof", "-PiTCP", "-sTCP:LISTEN"))
    strs.append("-----------------------------------\n")
    strs.append("$ ifconfig\n")
    strs.append(shell("ifconfig"))
    strs.append("-----------------------------------\n")
    strs.append("$ launchctl list | grep com.qiuyuzhou.\n")
    strs.append(shell("bash", "-c", "launchctl list | grep com.qiuyuzhou."))
    strs.append("-----------------------------------\n")
    
    let output = strs.joined()
    return output
}