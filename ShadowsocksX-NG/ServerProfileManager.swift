//
//  ServerProfileManager.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6. Modified by 秦宇航 16/9/12
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class ServerProfileManager: NSObject {

    static let instance:ServerProfileManager = ServerProfileManager()

    var profiles:[ServerProfile] = [ServerProfile]()
    var activeProfileId: String?

    fileprivate override init() {
        let defaults = UserDefaults.standard
        if let _profiles = defaults.array(forKey: "ServerProfiles") {
            for _profile in _profiles {
                // Safe cast and unwrap
                guard let profileDict = _profile as? [String: Any],
                      let profile = ServerProfile.fromDictionary(profileDict) else {
                    ErrorHandler.shared.warning("Failed to load server profile from dictionary")
                    continue
                }
                profiles.append(profile)
            }
        }
        activeProfileId = defaults.string(forKey: "ActiveServerProfileId")
    }

    /// Sets the active server profile by identifier and persists the selection.
    /// - Parameters:
    ///   - id: The UUID string of the profile to mark as active; stored in UserDefaults under the key `"ActiveServerProfileId"`.
    func setActiveProfiledId(_ id: String) {
        activeProfileId = id
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: "ActiveServerProfileId")
    }

    /// Persists all valid server profiles to UserDefaults and clears the active profile if it no longer exists.
    /// 
    /// Only profiles for which `isValid()` returns true are converted to dictionaries and stored under the
    /// "ServerProfiles" UserDefaults key. If there is no active profile after saving, `activeProfileId` is set to `nil`.
    func save() {
        let defaults = UserDefaults.standard
        var _profiles = [AnyObject]()
        for profile in profiles {
            if profile.isValid() {
                let _profile = profile.toDictionary()
                _profiles.append(_profile as AnyObject)
            }
        }
        defaults.set(_profiles, forKey: "ServerProfiles")

        if getActiveProfile() == nil {
            activeProfileId = nil
        }
    }

    /// Reloads the manager's profiles and active profile identifier from UserDefaults.
    /// 
    /// Clears the current in-memory profiles, then loads and validates profiles from the UserDefaults array stored under "ServerProfiles" (invalid entries are skipped and a warning is logged). Finally updates `activeProfileId` from the "ActiveServerProfileId" key.
    func reload() {
        profiles.removeAll()

        let defaults = UserDefaults.standard
        if let _profiles = defaults.array(forKey: "ServerProfiles") {
            for _profile in _profiles {
                // Safe cast and unwrap
                guard let profileDict = _profile as? [String: Any],
                      let profile = ServerProfile.fromDictionary(profileDict) else {
                    ErrorHandler.shared.warning("Failed to load server profile from dictionary")
                    continue
                }
                profiles.append(profile)
            }
        }
        activeProfileId = defaults.string(forKey: "ActiveServerProfileId")
    }

    /// Retrieve the currently active ServerProfile by the stored activeProfileId.
    /// - Returns: The `ServerProfile` whose `uuid` matches `activeProfileId`, or `nil` if no active id is set or no matching profile is found.
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

    /// Adds server profiles for the provided URLs, persists any new profiles, and notifies observers of the change.
    /// - Parameters:
    ///   - urls: The URLs to attempt to convert into `ServerProfile` instances.
    /// - Returns: The number of profiles that were successfully added.
    func addServerProfileByURL(urls: [URL]) -> Int {
        var addCount = 0

        for url in urls {
            if let profile = ServerProfile(url: url) {
                profiles.append(profile)
                addCount = addCount + 1
            }
        }

        if addCount > 0 {
            save()
            NotificationCenter.default
                .post(name: NOTIFY_SERVER_PROFILES_CHANGED, object: nil)
        }

        return addCount
    }

    /// Extracts `ss`-scheme URLs from newline-separated text.
    /// - Parameter text: Input string containing one or more URLs separated by newlines (whitespace around lines is ignored).
    /// - Returns: An array of `URL` values parsed from lines whose scheme is `ss`.
    static func findURLSInText(_ text: String) -> [URL] {
        var urls = text.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .compactMap { URL(string: $0) }
        urls = urls.filter { $0.scheme == "ss" }
        return urls
    }
}