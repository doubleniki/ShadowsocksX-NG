//
//  ServerProfileManager.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6. Modified by 秦宇航 16/9/12
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class ServerProfileManager: NSObject {

    static let instance: ServerProfileManager = ServerProfileManager()

    var profiles: [ServerProfile] = [ServerProfile]()
    var activeProfileId: String?

    fileprivate override init() {
        super.init()

        let defaults = UserDefaults.standard

        // Try loading with JSON decoder (new format)
        if let data = defaults.data(forKey: Constants.UserDefaults.serverProfiles) {
            let decoder = JSONDecoder()
            do {
                profiles = try decoder.decode([ServerProfile].self, from: data)
            } catch {
                ErrorHandler.shared.warning("Failed to decode server profiles with JSON: \(error)")
                // Fall back to legacy format
                loadLegacyProfiles(from: defaults)
            }
        } else {
            // Try legacy dictionary format
            loadLegacyProfiles(from: defaults)
        }

        activeProfileId = defaults.string(forKey: Constants.UserDefaults.activeServerProfileId)
    }

    private func loadLegacyProfiles(from defaults: UserDefaults) {
        if let _profiles = defaults.array(forKey: Constants.UserDefaults.serverProfiles) {
            for _profile in _profiles {
                guard let profileDict = _profile as? [String: Any],
                    let profile = ServerProfile.fromDictionary(profileDict)
                else {
                    ErrorHandler.shared.warning("Failed to load server profile from dictionary")
                    continue
                }
                profiles.append(profile)
            }
            // Migrate to new format
            save()
        }
    }

    func setActiveProfileId(_ id: String) {
        activeProfileId = id
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: Constants.UserDefaults.activeServerProfileId)
    }

    func save() {
        let defaults = UserDefaults.standard

        // Filter valid profiles
        let validProfiles = profiles.filter { $0.isValid() }

        // Encode profiles with JSON encoder
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(validProfiles)
            defaults.set(data, forKey: Constants.UserDefaults.serverProfiles)
        } catch {
            ErrorHandler.shared.warning("Failed to encode server profiles: \(error)", context: "ServerProfileManager")
        }

        if getActiveProfile() == nil {
            activeProfileId = nil
        }
    }

    func reload() {
        profiles.removeAll()

        let defaults = UserDefaults.standard

        // Try loading with JSON decoder (new format)
        if let data = defaults.data(forKey: Constants.UserDefaults.serverProfiles) {
            let decoder = JSONDecoder()
            do {
                profiles = try decoder.decode([ServerProfile].self, from: data)
            } catch {
                ErrorHandler.shared.warning("Failed to decode server profiles with JSON: \(error)")
                // Fall back to legacy format
                loadLegacyProfiles(from: defaults)
            }
        } else {
            // Try legacy dictionary format
            loadLegacyProfiles(from: defaults)
        }

        activeProfileId = defaults.string(forKey: Constants.UserDefaults.activeServerProfileId)
    }

    func getActiveProfile() -> ServerProfile? {
        if let id = activeProfileId {
            for p in profiles {
                if p.uuid == id {
                    return p
                }
            }
            return nil
        } else {
            return nil
        }
    }

    func addServerProfileByURL(urls: [URL]) -> Int {
        var addCount = 0

        for url in urls {
            if let profile = ServerProfile(url: url) {
                profiles.append(profile)
                addCount += 1
            }
        }

        if addCount > 0 {
            save()
            NotificationCenter.default
                .post(name: Constants.Notification.serverProfilesChanged, object: nil)
        }

        return addCount
    }

    static func findURLSInText(_ text: String) -> [URL] {
        var urls = text.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .compactMap { URL(string: $0) }
        urls = urls.filter { $0.scheme == "ss" }
        return urls
    }
}

// MARK: - ServerProfileManaging Protocol Conformance

extension ServerProfileManager: ServerProfileManaging {
    // All required methods already implemented in main class
}
