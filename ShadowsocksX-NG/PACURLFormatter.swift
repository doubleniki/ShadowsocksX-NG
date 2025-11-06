//
//  PACURLFormatter.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 2019/9/15.
//  Copyright © 2019 qiuyuzhou. All rights reserved.
//

import Cocoa



class PACURLFormatter: Formatter {
    /// Provide the input string when the provided object is a `String`; otherwise provide an empty string.
    /// - Parameters:
    ///   - obj: The object to convert to a string.
    /// - Returns: The original string if `obj` is a `String`, otherwise an empty string.
    override func string(for obj: Any?) -> String? {
        if let _obj = obj {
            switch _obj {
            case let s as String:
                return s
            default:
                return ""
            }
        }
        return ""
    }

    /// Validate a string as a URL with scheme "http", "https", or "file" and produce its absolute string.
    /// 
    /// An input that is empty or contains only whitespace is treated as valid and leaves `obj` unchanged.
    /// - Parameters:
    ///   - obj: Output pointer that will receive the URL's `absoluteString` as `AnyObject` when validation succeeds.
    ///   - string: The input string to validate and parse as a URL.
    ///   - error: Output pointer that will receive a localized error message when validation fails.
    /// - Returns: `true` if the input is empty or a valid URL with an allowed scheme; `false` if the input is non-empty and not a valid allowed URL.
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        let input = string.trimmingCharacters(in: .whitespaces)
        if input.isEmpty {
            return true
        }

        let errorMessage = "Must be a valid URL with scheme 'file', 'http' or 'https'".localized

        if let url = URL.init(string: input) {
            if let scheme = url.scheme {
                if !(["http", "https", "file"].contains(scheme) ) {
                    error?.pointee = errorMessage as NSString
                    return false
                }

                obj?.pointee = url.absoluteString as AnyObject
                return true
            } else {
                error?.pointee = errorMessage as NSString
                return false
            }
        } else {
            error?.pointee = errorMessage as NSString
            return false
        }
    }
}