//
//  BGUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

let APP_SUPPORT_DIR = "/Library/Application Support/ShadowsocksX-NG/"
let USER_CONFIG_DIR = "/.ShadowsocksX-NG/"
let LAUNCH_AGENT_DIR = "/Library/LaunchAgents/"
let LAUNCH_AGENT_CONF_SSLOCAL_NAME = "com.qiuyuzhou.shadowsocksX-NG.local.plist"
let LAUNCH_AGENT_CONF_PRIVOXY_NAME = "com.qiuyuzhou.shadowsocksX-NG.http.plist"
let LAUNCH_AGENT_CONF_KCPTUN_NAME = "com.qiuyuzhou.shadowsocksX-NG.kcptun.plist"


func getFileSHA1Sum(_ filepath: String) -> String {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: filepath)) {
        return data.sha1()
    }
    return ""
}

// Ref: https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
// Genarate the mac launch agent service plist

/// Generate or update the launchd plist for the ss-local helper and write it to the user's LaunchAgents directory.
/// 
/// Creates the LaunchAgents directory if missing, composes the plist (including program arguments and DYLD_LIBRARY_PATH),
/// writes a temporary plist in the app support directory and, if different from the existing plist, replaces the plist in LaunchAgents.
/// - Returns: `true` if the on-disk launch agent plist was created or changed, `false` otherwise (also `false` if required directories could not be created).

func generateSSLocalLauchAgentPlist() -> Bool {
    let sslocalPath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local/ss-local"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/ss-local.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistTempFilepath = NSHomeDirectory() + APP_SUPPORT_DIR + LAUNCH_AGENT_CONF_SSLOCAL_NAME
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_SSLOCAL_NAME

    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        do {
            try fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            ErrorHandler.shared.handle(
                LaunchAgentError.directoryCreationFailed(path: launchAgentDirPath, error: error),
                context: "Generate SS Local Launch Agent",
                showAlert: true,
                critical: true
            )
            return false
        }
    }

    let oldSha1Sum = getFileSHA1Sum(plistFilepath)

    let defaults = UserDefaults.standard
    let enableUdpRelay = defaults.bool(forKey: "LocalSocks5.EnableUDPRelay")
    let enableVerboseMode = defaults.bool(forKey: "LocalSocks5.EnableVerboseMode")

    var arguments = [sslocalPath, "-c", "ss-local-config.json"]
    if enableUdpRelay {
        arguments.append("-u")
    }
    if enableVerboseMode {
        arguments.append("-v")
    }
    arguments.append("--reuse-port")

    // For a complete listing of the keys, see the launchd.plist manual page.
    let dyld_library_paths = [
        NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local/",
        NSHomeDirectory() + APP_SUPPORT_DIR + "plugins/",
    ]

    let dict: NSMutableDictionary = [
        "Label": "com.qiuyuzhou.shadowsocksX-NG.local",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": dyld_library_paths.joined(separator: ":")]
    ]
    dict.write(toFile: plistTempFilepath, atomically: true)
    let Sha1Sum = getFileSHA1Sum(plistTempFilepath)
    if oldSha1Sum != Sha1Sum {
        dict.write(toFile: plistFilepath, atomically: true)
        NSLog("generateSSLocalLauchAgentPlist - File has been changed.")
        return true
    } else {
        NSLog("generateSSLocalLauchAgentPlist - File has not been changed.")
        return false
    }
}

/// Starts the ss-local service by executing the bundled `start_ss_local.sh` script.
/// 
/// If the script resource is missing, reports a resource-not-found error via `ErrorHandler` and returns.
/// If the script exits with a non-zero status, reports a service start failure via `ErrorHandler`.
func startSSLocal() {
    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "start_ss_local.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "start_ss_local.sh", type: "script"),
            context: "Start SS Local",
            showAlert: true,
            critical: true
        )
        return
    }

    let task = Process.launchedProcess(launchPath: installerPath, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start ss-local succeeded.")
    } else {
        ErrorHandler.shared.handle(
            LaunchAgentError.serviceStartFailed(service: "ss-local", exitCode: task.terminationStatus),
            context: "Start SS Local",
            showAlert: true
        )
    }
}

/// Stops the bundled ss-local service by locating and executing the bundled `stop_ss_local.sh` script.
/// - Discussion: If the stop script is missing, reports a resource-not-found error via `ErrorHandler`. If the script runs and exits with a nonzero status, reports a service stop failure via `ErrorHandler`.
func stopSSLocal() {
    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "stop_ss_local.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "stop_ss_local.sh", type: "script"),
            context: "Stop SS Local",
            showAlert: true,
            critical: true
        )
        return
    }

    let task = Process.launchedProcess(launchPath: installerPath, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop ss-local succeeded.")
    } else {
        ErrorHandler.shared.handle(
            LaunchAgentError.serviceStopFailed(service: "ss-local", error: NSError(domain: "LaunchAgent", code: Int(task.terminationStatus))),
            context: "Stop SS Local",
            showAlert: true
        )
    }
}

/// Installs the bundled ss-local executable.
/// 
/// Removes any existing ss-local binary from the application's support directory and runs the bundled `install_ss_local.sh` installer script. If the installer script is missing, an alert is shown; installation success or failure is reported via logs and ErrorHandler.
func installSSLocal() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if fileMgr.fileExists(atPath: appSupportDir + "ss-local/ss-local") {
        do {
            try fileMgr.removeItem(atPath: appSupportDir + "ss-local/ss-local")
        } catch {
            NSLog("Remove old ss-local error")
        }
    }

    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "install_ss_local.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "install_ss_local.sh", type: "script"),
            context: "Install SS Local",
            showAlert: true,
            critical: true
        )
        return
    }

    let task = Process.launchedProcess(launchPath: installerPath, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Install ss-local succeeded.")
    } else {
        ErrorHandler.shared.warning("Install ss-local failed with exit code: \(task.terminationStatus)")
    }

}

/// Writes the given Shadowsocks local configuration to the app support directory as `ss-local-config.json`, normalizing escaped forward slashes and performing an atomic write.
/// - Parameters:
///   - conf: A dictionary representing the ss-local configuration to serialize to JSON.
/// - Returns: `true` if the file was written and the content changed, `false` if the file was unchanged or if an error occurred.
func writeSSLocalConfFile(_ conf:[String:AnyObject]) -> Bool {
    do {
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local-config.json"
        var data: Data = try JSONSerialization.data(withJSONObject: conf, options: .prettyPrinted)

        // https://github.com/shadowsocks/ShadowsocksX-NG/issues/1104
        // This is NSJSONSerialization.dataWithJSONObject that likes to insert additional backslashes.
        // Escaped forward slashes is also valid json.
        // Workaround:
        guard let s = String(data: data, encoding: .utf8),
              let processedData = s.replacingOccurrences(of: "\\/", with: "/").data(using: .utf8) else {
            NSLog("Failed to process JSON data encoding")
            return false
        }
        data = processedData

        let oldSum = getFileSHA1Sum(filepath)
        try data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        let newSum = data.sha1()

        if oldSum == newSum {
            NSLog("writeSSLocalConfFile - File has not been changed.")
            return false
        }

        NSLog("writeSSLocalConfFile - File has been changed.")
        return true
    } catch {
        NSLog("Write ss-local file failed.")
    }
    return false
}

/// Removes the ss-local configuration file from the application's support directory if it exists.
/// 
/// This attempts to delete "~(HOME)/\(APP_SUPPORT_DIR)ss-local-config.json" and silently ignores any errors.
func removeSSLocalConfFile() {
    do {
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local-config.json"
        try FileManager.default.removeItem(atPath: filepath)
    } catch {

    }
}

/// Synchronizes ss-local configuration and launch agent state with the current profile and user settings.
/// 
/// - Description: Ensures the ss-local launch agent plist and configuration file reflect the active server profile. If an active profile exists, updates the ss-local config from the profile and updates the launch agent plist; if no active profile exists, removes the ss-local config. Respects the `ShadowsocksOn` user setting: when enabled, starts ss-local (restarting it if configuration or plist changed); when disabled, stops ss-local. Always invokes SyncPac() and syncPrivoxy() after making changes.
func syncSSLocal() {
    var changed: Bool = false
    changed = changed || generateSSLocalLauchAgentPlist()
    let mgr = ServerProfileManager.instance
    if mgr.activeProfileId != nil {
        if let profile = mgr.getActiveProfile() {
            changed = changed || writeSSLocalConfFile((profile.toJsonConfig()))
        }

        let on = UserDefaults.standard.bool(forKey: "ShadowsocksOn")
        if on {
            if changed {
                stopSSLocal()
                DispatchQueue.main.asyncAfter(
                    deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1),
                    execute: {
                        () in
                        startSSLocal()
                    })
            } else {
                startSSLocal()
            }
        } else {
            stopSSLocal()
        }
    } else {
        removeSSLocalConfFile()
        stopSSLocal()
    }
    SyncPac()
    syncPrivoxy()
}

// --------------------------------------------------------------------------------
/// Installs or updates the bundled simple-obfs helper.
///
/// Removes any existing obfs-local binary in the app support directory and runs the bundled `install_simple_obfs.sh` installer script. Reports success or failure via logs and the shared ErrorHandler.

func installSimpleObfs() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir + APP_SUPPORT_DIR
    if fileMgr.fileExists(atPath: appSupportDir + "simple-obfs/obfs-local") {
        do {
            try fileMgr.removeItem(atPath: appSupportDir + "simple-obfs/obfs-local")
        } catch {
            NSLog("Remove old simple-obfs error")
        }
    }

    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "install_simple_obfs.sh", ofType: nil) else {
        ErrorHandler.shared.warning("install_simple_obfs.sh script not found")
        return
    }

    let task = Process.launchedProcess(launchPath: "/bin/sh", arguments: [installerPath])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Install simple-obfs succeeded.")
    } else {
        ErrorHandler.shared.warning("Install simple-obfs failed with exit code: \(task.terminationStatus)")
    }

}

// --------------------------------------------------------------------------------
/// Installs or updates the kcptun client by removing any existing client binary and executing the bundled installer script.
/// 
/// If the bundled installer script is missing a warning is emitted; installer exit status is logged as success or warning.

func installKcptun() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if fileMgr.fileExists(atPath: appSupportDir + "kcptun/client") {
        do {
            try fileMgr.removeItem(atPath: appSupportDir + "kcptun/client")
        } catch {
            NSLog("Remove old kcptun client error")
        }
    }
    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "install_kcptun", ofType: "sh") else {
        ErrorHandler.shared.warning("install_kcptun.sh script not found")
        return
    }

    let task = Process.launchedProcess(launchPath: "/bin/sh", arguments: [installerPath])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Install kcptun succeeded.")
    } else {
        ErrorHandler.shared.warning("Install kcptun failed with exit code: \(task.terminationStatus)")
    }
}

// --------------------------------------------------------------------------------
/// Installs or updates the bundled v2ray-plugin by removing any existing app-support copy and running the bundled installer script.
/// - Discussion: If the installer script is missing the function logs a warning and returns without making changes. The function attempts to remove an existing v2ray-plugin binary in the app support directory; removal failures are logged. It then executes the bundled `install_v2ray_plugin.sh` script and logs success or a warning containing the script's exit code.

func installV2rayPlugin() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if fileMgr.fileExists(atPath: appSupportDir + "v2ray-plugin/v2ray-plugin") {
        do {
            try fileMgr.removeItem(atPath: appSupportDir + "v2ray-plugin/v2ray-plugin")
        } catch {
            NSLog("Remove old v2ray-plugin error")
        }
    }
    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "install_v2ray_plugin", ofType: "sh") else {
        ErrorHandler.shared.warning("install_v2ray_plugin.sh script not found")
        return
    }

    let task = Process.launchedProcess(launchPath: "/bin/sh", arguments: [installerPath])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Install v2ray-plugin succeeded.")
    } else {
        ErrorHandler.shared.warning("Install v2ray-plugin failed with exit code: \(task.terminationStatus)")
    }
}

// --------------------------------------------------------------------------------
/// Generate or update the Privoxy launchd plist in the user's LaunchAgents directory.
/// 
/// Ensures the LaunchAgents directory exists, writes a temporary plist representing the Privoxy launch agent, and atomically updates the final plist only if its content differs from the existing file. Reports directory-creation failures via ErrorHandler.
/// - Returns: `true` if the final plist file was written because the content changed, `false` if the plist was unchanged or the operation failed.

func generatePrivoxyLauchAgentPlist() -> Bool {
    let privoxyPath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy/privoxy"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/privoxy.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistTempFilePath = NSHomeDirectory() + APP_SUPPORT_DIR + LAUNCH_AGENT_CONF_PRIVOXY_NAME
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_PRIVOXY_NAME

    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        do {
            try fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            ErrorHandler.shared.handle(
                LaunchAgentError.directoryCreationFailed(path: launchAgentDirPath, error: error),
                context: "Generate Privoxy Launch Agent",
                showAlert: true,
                critical: true
            )
            return false
        }
    }

    let oldSha1Sum = getFileSHA1Sum(plistFilepath)

    let arguments = [privoxyPath, "--no-daemon", "privoxy.config"]

    // For a complete listing of the keys, see the launchd.plist manual page.
    let dict: NSMutableDictionary = [
        "Label": "com.qiuyuzhou.shadowsocksX-NG.http",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments
    ]
    dict.write(toFile: plistTempFilePath, atomically: true)
    let Sha1Sum = getFileSHA1Sum(plistTempFilePath)
    if oldSha1Sum != Sha1Sum {
        dict.write(toFile: plistFilepath, atomically: true)
        return true
    } else {
        return false
    }
}

/// Starts the Privoxy service by executing the bundled `start_privoxy.sh` script.
/// If the script resource is missing, reports a resource-not-found error via the shared ErrorHandler.
/// If the script exits with a non-zero status, reports a warning through the shared ErrorHandler.
func startPrivoxy() {
    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "start_privoxy.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "start_privoxy.sh", type: "script"),
            context: "Start Privoxy",
            showAlert: true,
            critical: true
        )
        return
    }

    let task = Process.launchedProcess(launchPath: installerPath, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start privoxy succeeded.")
    } else {
        ErrorHandler.shared.warning("Start privoxy failed with exit code: \(task.terminationStatus)")
    }
}

/// Stops the Privoxy service by running the bundled stop_privoxy.sh script.
/// 
/// If the stop script is missing, reports a resource-not-found error via ErrorHandler and aborts.
/// Otherwise runs the script, waits for it to finish, and reports success or a warning containing the script's exit code.
func stopPrivoxy() {
    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "stop_privoxy.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "stop_privoxy.sh", type: "script"),
            context: "Stop Privoxy",
            showAlert: true,
            critical: true
        )
        return
    }

    let task = Process.launchedProcess(launchPath: installerPath, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop privoxy succeeded.")
    } else {
        ErrorHandler.shared.warning("Stop privoxy failed with exit code: \(task.terminationStatus)")
    }
}

/// Installs Privoxy and ensures a user configuration file exists.
/// 
/// Runs the bundled `install_privoxy.sh` installer (and reports non‑zero exit status), removes an existing privoxy binary from the app support directory if present, creates the user config directory `~/.ShadowsocksX-NG` when missing, and copies a default `user-privoxy.config` into that directory if one does not already exist.
/// 
/// All filesystem and resource failures are reported through the shared `ErrorHandler`.
func installPrivoxy() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if fileMgr.fileExists(atPath: appSupportDir + "privoxy/privoxy") {
        do {
            try fileMgr.removeItem(atPath: appSupportDir + "privoxy/privoxy")
        } catch {
            NSLog("Remove old privoxy error")
        }
    }

    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "install_privoxy.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "install_privoxy.sh", type: "script"),
            context: "Install Privoxy",
            showAlert: true,
            critical: true
        )
        return
    }

    let task = Process.launchedProcess(launchPath: installerPath, arguments: [""])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Install privoxy succeeded.")
    } else {
        ErrorHandler.shared.warning("Install privoxy failed with exit code: \(task.terminationStatus)")
    }

    let userConfigDir = homeDir + USER_CONFIG_DIR
    // Make dir: '~/.ShadowsocksX-NG'
    if !fileMgr.fileExists(atPath: userConfigDir) {
        do {
            try fileMgr.createDirectory(atPath: userConfigDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: userConfigDir, error: error),
                context: "Install Privoxy",
                showAlert: true
            )
            return
        }
    }

    // Install empty `user-privoxy.config` file.
    let userConfigPath = userConfigDir + "user-privoxy.config"
    if !fileMgr.fileExists(atPath: userConfigPath) {
        guard let srcPath = Bundle.main.path(forResource: "user-privoxy", ofType: "config") else {
            ErrorHandler.shared.warning("user-privoxy.config resource not found")
            return
        }

        do {
            try fileMgr.copyItem(atPath: srcPath, toPath: userConfigPath)
        } catch {
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: userConfigPath, error: error),
                context: "Install Privoxy",
                showAlert: true
            )
        }
    }
}

/// Generates and writes privoxy.config by substituting proxy addresses into the template and appending the user's privoxy configuration.
/// 
/// Reads the bundled "privoxy.template.config", replaces `{http}` and `{socks5}` placeholders with the configured local HTTP and SOCKS5 addresses and ports, appends the user's `user-privoxy.config`, and writes the result atomically to the application's support directory. The file is only replaced if its SHA1 differs from the existing file.
/// - Returns: `true` if privoxy.config was created or changed, `false` otherwise.
func writePrivoxyConfFile() -> Bool {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        guard let templatePath = bundle.path(forResource: "privoxy.template.config", ofType: nil) else {
            ErrorHandler.shared.warning("privoxy.template.config not found")
            return false
        }

        // Read template file
        var template = try String(contentsOfFile: templatePath, encoding: .utf8)

        guard let httpAddress = defaults.string(forKey: "LocalHTTP.ListenAddress"),
              let socks5Address = defaults.string(forKey: "LocalSocks5.ListenAddress") else {
            ErrorHandler.shared.warning("Failed to get proxy addresses from defaults")
            return false
        }

        let httpPort = defaults.integer(forKey: "LocalHTTP.ListenPort")
        let socks5Port = defaults.integer(forKey: "LocalSocks5.ListenPort")

        template = template.replacingOccurrences(of: "{http}", with: "\(httpAddress):\(httpPort)")
        template = template.replacingOccurrences(of: "{socks5}", with: "\(socks5Address):\(socks5Port)")

        // Append the user config file to the end
        let userConfigPath = NSHomeDirectory() + USER_CONFIG_DIR + "user-privoxy.config"
        let userConfig = try String(contentsOfFile: userConfigPath, encoding: .utf8)
        template.append(contentsOf: userConfig)

        // Write to file
        let data = template.data(using: .utf8)
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy.config"

        let oldSum = getFileSHA1Sum(filepath)
        try data?.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        let newSum = getFileSHA1Sum(filepath)

        if oldSum == newSum {
            return false
        }

        return true
    } catch {
        NSLog("Write privoxy file failed.")
    }
    return false
}

/// Remove the Privoxy configuration file from the application's support directory.
/// 
/// If the file does not exist or deletion fails, the function returns without signaling an error.
func removePrivoxyConfFile() {
    do {
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy.config"
        try FileManager.default.removeItem(atPath: filepath)
    } catch {

    }
}

/// Synchronizes Privoxy configuration and its launch agent with the current profile and user settings.
/// 
/// If an active server profile exists, updates the Privoxy launch agent plist and configuration file. 
/// When the "LocalHTTPOn" user default is enabled, restarts Privoxy if configuration or plist changed, otherwise ensures Privoxy is started. 
/// When "LocalHTTPOn" is disabled, stops Privoxy. 
/// If there is no active profile, removes the Privoxy configuration file and stops Privoxy.
func syncPrivoxy() {
    var changed: Bool = false
    changed = changed || generatePrivoxyLauchAgentPlist()
    let mgr = ServerProfileManager.instance
    if mgr.activeProfileId != nil {
        changed = changed || writePrivoxyConfFile()

        let on = UserDefaults.standard.bool(forKey: "LocalHTTPOn")
        if on {
            if changed {
                stopPrivoxy()
                DispatchQueue.main.asyncAfter(
                    deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1),
                    execute: {
                        () in
                        startPrivoxy()
                    })
            } else {
                startPrivoxy()
            }
        } else {
            stopPrivoxy()
        }
    } else {
        removePrivoxyConfFile()
        stopPrivoxy()
    }
}