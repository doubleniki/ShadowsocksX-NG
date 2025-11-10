//
//  BGUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

// MARK: - Path Constants
// Note: These constants are relative paths without leading slashes
// Use homeDirectory().appendingPathComponent() for safe path construction
private let APP_SUPPORT_DIR = "Library/Application Support/ShadowsocksX-NG"
private let USER_CONFIG_DIR = ".ShadowsocksX-NG"
private let LAUNCH_AGENT_DIR = "Library/LaunchAgents"
let LAUNCH_AGENT_CONF_SSLOCAL_NAME = "com.qiuyuzhou.shadowsocksX-NG.local.plist"
let LAUNCH_AGENT_CONF_PRIVOXY_NAME = "com.qiuyuzhou.shadowsocksX-NG.http.plist"
let LAUNCH_AGENT_CONF_KCPTUN_NAME = "com.qiuyuzhou.shadowsocksX-NG.kcptun.plist"

// MARK: - Helper Functions

/// Returns home directory as URL
private func homeDirectory() -> URL {
    return FileManager.default.homeDirectoryForCurrentUser
}

/// Returns app support directory path
private func appSupportDirectory() -> String {
    return homeDirectory().appendingPathComponent(APP_SUPPORT_DIR).path
}

/// Returns user config directory path
private func userConfigDirectory() -> String {
    return homeDirectory().appendingPathComponent(USER_CONFIG_DIR).path
}

/// Returns launch agent directory path
private func launchAgentDirectory() -> String {
    return homeDirectory().appendingPathComponent(LAUNCH_AGENT_DIR).path
}

func getFileSHA1Sum(_ filepath: String) -> String {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: filepath)) {
        return data.sha1()
    }
    return ""
}

// Ref: https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
// Genarate the mac launch agent service plist

//  MARK: sslocal

func generateSSLocalLauchAgentPlist() -> Bool {
    let sslocalPath = homeDirectory()
        .appendingPathComponent(APP_SUPPORT_DIR)
        .appendingPathComponent("ss-local/ss-local")
        .path
    let logFilePath = homeDirectory()
        .appendingPathComponent("Library/Logs")
        .appendingPathComponent("ss-local.log")
        .path
    let launchAgentDirPath = launchAgentDirectory()
    let plistTempFilepath = homeDirectory()
        .appendingPathComponent(APP_SUPPORT_DIR)
        .appendingPathComponent(LAUNCH_AGENT_CONF_SSLOCAL_NAME)
        .path
    let plistFilepath = URL(fileURLWithPath: launchAgentDirPath)
        .appendingPathComponent(LAUNCH_AGENT_CONF_SSLOCAL_NAME)
        .path

    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        do {
            try fileMgr.createDirectory(
                atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
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
        homeDirectory().appendingPathComponent(APP_SUPPORT_DIR).appendingPathComponent("ss-local")
            .path,
        homeDirectory().appendingPathComponent(APP_SUPPORT_DIR).appendingPathComponent("plugins")
            .path,
    ]

    let dict: NSMutableDictionary = [
        "Label": "com.qiuyuzhou.shadowsocksX-NG.local",
        "WorkingDirectory": appSupportDirectory(),
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": dyld_library_paths.joined(separator: ":")],
    ]

    // Write to temporary file first to check if content changed
    guard dict.write(toFile: plistTempFilepath, atomically: true) else {
        let writeError = NSError(
            domain: "com.qiuyuzhou.ShadowsocksX-NG",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to write plist to temporary file"]
        )
        ErrorHandler.shared.handle(
            FileSystemError.writeFailed(path: plistTempFilepath, error: writeError),
            context: "Generate SS Local Launch Agent",
            showAlert: true,
            critical: true
        )
        return false
    }

    let sha1Sum = getFileSHA1Sum(plistTempFilepath)
    if oldSha1Sum != sha1Sum {
        // Write to final destination
        guard dict.write(toFile: plistFilepath, atomically: true) else {
            let writeError = NSError(
                domain: "com.qiuyuzhou.ShadowsocksX-NG",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write plist to final destination"]
            )
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: plistFilepath, error: writeError),
                context: "Generate SS Local Launch Agent",
                showAlert: true,
                critical: true
            )
            return false
        }

        ErrorHandler.shared.debug(
            "generateSSLocalLauchAgentPlist - File has been changed.", context: "LaunchAgent")
        return true
    } else {
        ErrorHandler.shared.debug(
            "generateSSLocalLauchAgentPlist - File has not been changed.", context: "LaunchAgent")
        return false
    }
}

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
        ErrorHandler.shared.info("Start ss-local succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.handle(
            LaunchAgentError.serviceStartFailed(
                service: "ss-local", exitCode: task.terminationStatus),
            context: "Start SS Local",
            showAlert: true
        )
    }
}

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
        ErrorHandler.shared.info("Stop ss-local succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.handle(
            LaunchAgentError.serviceStopFailed(
                service: "ss-local",
                error: NSError(domain: "LaunchAgent", code: Int(task.terminationStatus))),
            context: "Stop SS Local",
            showAlert: true
        )
    }
}

func installSSLocal() {
    let fileMgr = FileManager.default
    let appSupportDir = appSupportDirectory()
    let sslocalPath = URL(fileURLWithPath: appSupportDir)
        .appendingPathComponent("ss-local/ss-local")
        .path
    if fileMgr.fileExists(atPath: sslocalPath) {
        do {
            try fileMgr.removeItem(atPath: sslocalPath)
        } catch {
            ErrorHandler.shared.warning("Remove old ss-local error", context: "LaunchAgent")
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
        ErrorHandler.shared.info("Install ss-local succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Install ss-local failed with exit code: \(task.terminationStatus)",
            context: "LaunchAgent")
    }

}

func writeSSLocalConfFile(_ conf: [String: AnyObject]) -> Bool {
    do {
        let filepath = homeDirectory()
            .appendingPathComponent(APP_SUPPORT_DIR)
            .appendingPathComponent("ss-local-config.json")
            .path
        var data: Data = try JSONSerialization.data(withJSONObject: conf, options: .prettyPrinted)

        // https://github.com/shadowsocks/ShadowsocksX-NG/issues/1104
        // This is NSJSONSerialization.dataWithJSONObject that likes to insert additional backslashes.
        // Escaped forward slashes is also valid json.
        // Workaround:
        guard let s = String(data: data, encoding: .utf8),
            let processedData = s.replacingOccurrences(of: "\\/", with: "/").data(using: .utf8)
        else {
            ErrorHandler.shared.warning(
                "Failed to process JSON data encoding", context: "LaunchAgent")
            return false
        }
        data = processedData

        let oldSum = getFileSHA1Sum(filepath)
        try data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        let newSum = data.sha1()

        if oldSum == newSum {
            ErrorHandler.shared.debug(
                "writeSSLocalConfFile - File has not been changed.", context: "LaunchAgent")
            return false
        }

        ErrorHandler.shared.debug(
            "writeSSLocalConfFile - File has been changed.", context: "LaunchAgent")
        return true
    } catch {
        ErrorHandler.shared.warning("Write ss-local file failed.", context: "LaunchAgent")
    }
    return false
}

func removeSSLocalConfFile() {
    do {
        let filepath = homeDirectory()
            .appendingPathComponent(APP_SUPPORT_DIR)
            .appendingPathComponent("ss-local-config.json")
            .path
        try FileManager.default.removeItem(atPath: filepath)
    } catch {
        ErrorHandler.shared.debug(
            "Failed to remove ss-local config file: \(error.localizedDescription)",
            context: "LaunchAgent"
        )
    }
}

func syncSSLocal() {
    var changed: Bool = false
    changed = changed || generateSSLocalLauchAgentPlist()
    let mgr = ServerProfileManager.instance
    if mgr.activeProfileId != nil {
        if let profile = mgr.getActiveProfile() {
            changed = changed || writeSSLocalConfFile((profile.toJsonConfig()))
        }

        let on = UserDefaults.standard.bool(forKey: Constants.UserDefaults.shadowsocksOn)
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
    syncPac()
    syncPrivoxy()
}

// --------------------------------------------------------------------------------
//  MARK: simple-obfs

func installSimpleObfs() {
    let fileMgr = FileManager.default
    let appSupportDir = appSupportDirectory()
    let obfsLocalPath = URL(fileURLWithPath: appSupportDir)
        .appendingPathComponent("simple-obfs/obfs-local")
        .path
    if fileMgr.fileExists(atPath: obfsLocalPath) {
        do {
            try fileMgr.removeItem(atPath: obfsLocalPath)
        } catch {
            ErrorHandler.shared.warning("Remove old simple-obfs error", context: "LaunchAgent")
        }
    }

    let bundle = Bundle.main
    guard let installerPath = bundle.path(forResource: "install_simple_obfs.sh", ofType: nil) else {
        ErrorHandler.shared.handle(
            ResourceError.resourceNotFound(name: "install_simple_obfs.sh", type: "script"),
            context: "Install Simple Obfs",
            showAlert: false
        )
        return
    }

    let task = Process.launchedProcess(launchPath: "/bin/sh", arguments: [installerPath])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        ErrorHandler.shared.info("Install simple-obfs succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Install simple-obfs failed with exit code: \(task.terminationStatus)",
            context: "LaunchAgent")
    }

}

// --------------------------------------------------------------------------------
//  MARK: kcptun

func installKcptun() {
    let fileMgr = FileManager.default
    let appSupportDir = appSupportDirectory()
    let kcptunClientPath = URL(fileURLWithPath: appSupportDir)
        .appendingPathComponent("kcptun/client")
        .path
    if fileMgr.fileExists(atPath: kcptunClientPath) {
        do {
            try fileMgr.removeItem(atPath: kcptunClientPath)
        } catch {
            ErrorHandler.shared.warning("Remove old kcptun client error", context: "LaunchAgent")
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
        ErrorHandler.shared.info("Install kcptun succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Install kcptun failed with exit code: \(task.terminationStatus)",
            context: "LaunchAgent")
    }
}

// --------------------------------------------------------------------------------
//  MARK: v2ray-plugin

func installV2rayPlugin() {
    let fileMgr = FileManager.default
    let appSupportDir = appSupportDirectory()
    let v2rayPluginPath = URL(fileURLWithPath: appSupportDir)
        .appendingPathComponent("v2ray-plugin/v2ray-plugin")
        .path
    if fileMgr.fileExists(atPath: v2rayPluginPath) {
        do {
            try fileMgr.removeItem(atPath: v2rayPluginPath)
        } catch {
            ErrorHandler.shared.warning("Remove old v2ray-plugin error", context: "LaunchAgent")
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
        ErrorHandler.shared.info("Install v2ray-plugin succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Install v2ray-plugin failed with exit code: \(task.terminationStatus)",
            context: "LaunchAgent")
    }
}

// --------------------------------------------------------------------------------
//  MARK: privoxy

func generatePrivoxyLauchAgentPlist() -> Bool {
    let privoxyPath = homeDirectory()
        .appendingPathComponent(APP_SUPPORT_DIR)
        .appendingPathComponent("privoxy/privoxy")
        .path
    let logFilePath = homeDirectory()
        .appendingPathComponent("Library/Logs")
        .appendingPathComponent("privoxy.log")
        .path
    let launchAgentDirPath = launchAgentDirectory()
    let plistTempFilePath = homeDirectory()
        .appendingPathComponent(APP_SUPPORT_DIR)
        .appendingPathComponent(LAUNCH_AGENT_CONF_PRIVOXY_NAME)
        .path
    let plistFilepath = URL(fileURLWithPath: launchAgentDirPath)
        .appendingPathComponent(LAUNCH_AGENT_CONF_PRIVOXY_NAME)
        .path

    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        do {
            try fileMgr.createDirectory(
                atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
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
        "WorkingDirectory": appSupportDirectory(),
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments,
    ]

    // Write to temporary file first to check if content changed
    guard dict.write(toFile: plistTempFilePath, atomically: true) else {
        let writeError = NSError(
            domain: "com.qiuyuzhou.ShadowsocksX-NG",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to write plist to temporary file"]
        )
        ErrorHandler.shared.handle(
            FileSystemError.writeFailed(path: plistTempFilePath, error: writeError),
            context: "Generate Privoxy Launch Agent",
            showAlert: true,
            critical: true
        )
        return false
    }

    let sha1Sum = getFileSHA1Sum(plistTempFilePath)
    if oldSha1Sum != sha1Sum {
        // Write to final destination
        guard dict.write(toFile: plistFilepath, atomically: true) else {
            let writeError = NSError(
                domain: "com.qiuyuzhou.ShadowsocksX-NG",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write plist to final destination"]
            )
            ErrorHandler.shared.handle(
                FileSystemError.writeFailed(path: plistFilepath, error: writeError),
                context: "Generate Privoxy Launch Agent",
                showAlert: true,
                critical: true
            )
            return false
        }

        return true
    } else {
        return false
    }
}

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
        ErrorHandler.shared.info("Start privoxy succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Start privoxy failed with exit code: \(task.terminationStatus)", context: "LaunchAgent"
        )
    }
}

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
        ErrorHandler.shared.info("Stop privoxy succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Stop privoxy failed with exit code: \(task.terminationStatus)", context: "LaunchAgent")
    }
}

func installPrivoxy() {
    let fileMgr = FileManager.default
    let appSupportDir = appSupportDirectory()
    let privoxyPath = URL(fileURLWithPath: appSupportDir)
        .appendingPathComponent("privoxy/privoxy")
        .path
    if fileMgr.fileExists(atPath: privoxyPath) {
        do {
            try fileMgr.removeItem(atPath: privoxyPath)
        } catch {
            ErrorHandler.shared.warning("Remove old privoxy error", context: "LaunchAgent")
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
        ErrorHandler.shared.info("Install privoxy succeeded.", context: "LaunchAgent")
    } else {
        ErrorHandler.shared.warning(
            "Install privoxy failed with exit code: \(task.terminationStatus)",
            context: "LaunchAgent")
    }

    let userConfigDir = userConfigDirectory()
    // Make dir: '~/.ShadowsocksX-NG'
    if !fileMgr.fileExists(atPath: userConfigDir) {
        do {
            try fileMgr.createDirectory(
                atPath: userConfigDir, withIntermediateDirectories: true, attributes: nil)
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
    let userConfigPath = URL(fileURLWithPath: userConfigDir)
        .appendingPathComponent("user-privoxy.config")
        .path
    if !fileMgr.fileExists(atPath: userConfigPath) {
        guard let srcPath = Bundle.main.path(forResource: "user-privoxy", ofType: "config") else {
            ErrorHandler.shared.handle(
                ResourceError.resourceNotFound(name: "user-privoxy", type: "config"),
                context: "Install Privoxy",
                showAlert: true
            )
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

func writePrivoxyConfFile() -> Bool {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        guard let templatePath = bundle.path(forResource: "privoxy.template.config", ofType: nil)
        else {
            ErrorHandler.shared.handle(
                ResourceError.resourceNotFound(name: "privoxy.template.config", type: ""),
                context: "Write Privoxy Config",
                showAlert: true
            )
            return false
        }

        // Read template file
        var template = try String(contentsOfFile: templatePath, encoding: .utf8)

        guard let httpAddress = defaults.string(forKey: "LocalHTTP.ListenAddress"),
            let socks5Address = defaults.string(forKey: "LocalSocks5.ListenAddress")
        else {
            ErrorHandler.shared.handle(
                PACError.invalidFormat(reason: "Proxy addresses not configured in defaults"),
                context: "Write Privoxy Config",
                showAlert: true
            )
            return false
        }

        let httpPort = defaults.integer(forKey: "LocalHTTP.ListenPort")
        let socks5Port = defaults.integer(forKey: "LocalSocks5.ListenPort")

        template = template.replacingOccurrences(of: "{http}", with: "\(httpAddress):\(httpPort)")
        template = template.replacingOccurrences(
            of: "{socks5}", with: "\(socks5Address):\(socks5Port)")

        // Append the user config file to the end
        let userConfigPath = homeDirectory()
            .appendingPathComponent(USER_CONFIG_DIR)
            .appendingPathComponent("user-privoxy.config")
            .path
        let userConfig = try String(contentsOfFile: userConfigPath, encoding: .utf8)
        template.append(contentsOf: userConfig)

        // Write to file
        let data = template.data(using: .utf8)
        let filepath = homeDirectory()
            .appendingPathComponent(APP_SUPPORT_DIR)
            .appendingPathComponent("privoxy.config")
            .path

        let oldSum = getFileSHA1Sum(filepath)
        try data?.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        let newSum = getFileSHA1Sum(filepath)

        if oldSum == newSum {
            return false
        }

        return true
    } catch {
        ErrorHandler.shared.warning("Write privoxy file failed.", context: "LaunchAgent")
    }
    return false
}

func removePrivoxyConfFile() {
    do {
        let filepath = homeDirectory()
            .appendingPathComponent(APP_SUPPORT_DIR)
            .appendingPathComponent("privoxy.config")
            .path
        try FileManager.default.removeItem(atPath: filepath)
    } catch {

    }
}

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
