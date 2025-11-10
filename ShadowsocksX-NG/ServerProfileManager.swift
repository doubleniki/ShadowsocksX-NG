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
        let defaults = UserDefaults.standard
        if let _profiles = defaults.array(forKey: Constants.UserDefaults.serverProfiles) {
            for _profile in _profiles {
                // Safe cast and unwrap
                guard let profileDict = _profile as? [String: Any],
                    let profile = ServerProfile.fromDictionary(profileDict)
                else {
                    ErrorHandler.shared.warning("Failed to load server profile from dictionary")
                    continue
                }
                profiles.append(profile)
            }
        }
        activeProfileId = defaults.string(forKey: Constants.UserDefaults.activeServerProfileId)
    }

    func setActiveProfiledId(_ id: String) {
        activeProfileId = id
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: Constants.UserDefaults.activeServerProfileId)
    }

    func save() {
        let defaults = UserDefaults.standard
        var _profiles = [AnyObject]()
        for profile in profiles {
            if profile.isValid() {
                let _profile = profile.toDictionary()
                _profiles.append(_profile as AnyObject)
            }
        }
        defaults.set(_profiles, forKey: Constants.UserDefaults.serverProfiles)

        if getActiveProfile() == nil {
            activeProfileId = nil
        }
    }

    func reload() {
        profiles.removeAll()

        let defaults = UserDefaults.standard
        if let _profiles = defaults.array(forKey: Constants.UserDefaults.serverProfiles) {
            for _profile in _profiles {
                // Safe cast and unwrap
                guard let profileDict = _profile as? [String: Any],
                    let profile = ServerProfile.fromDictionary(profileDict)
                else {
                    ErrorHandler.shared.warning("Failed to load server profile from dictionary")
                    continue
                }
                profiles.append(profile)
            }
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
