//
//  NotificationService.swift
//  ShadowsocksX-NG
//
//  Centralized notification service using modern UserNotifications framework
//

import Foundation
import UserNotifications

class NotificationService {

    static let shared = NotificationService()

    private init() {}

    /// Request notification permissions from the user
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                ErrorHandler.shared.handle(
                    error,
                    context: "Request Notification Authorization",
                    showAlert: false
                )
            }
            completion?(granted)
        }
    }

    /// Send a user notification with the given title
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: Optional notification body text
    ///   - completion: Optional completion handler with error if failed
    func send(title: String, body: String? = nil, completion: ((Error?) -> Void)? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body = body {
            content.body = body
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                ErrorHandler.shared.handle(
                    error,
                    context: "Send User Notification",
                    showAlert: false
                )
            }
            completion?(error)
        }
    }
}
