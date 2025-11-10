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

    // Rate limiting properties
    private var recentNotifications: [String: Date] = [:]
    private let minimumInterval: TimeInterval
    private let queue = DispatchQueue(label: "com.shadowsocksX-NG.notifications", qos: .utility)

    private init(minimumInterval: TimeInterval = 1.0) {
        self.minimumInterval = minimumInterval
    }

    /// Request notification permissions from the user
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            granted, error in
            if let error = error {
                ErrorHandler.shared.handle(
                    error,
                    context: "Request Notification Authorization",
                    showAlert: false
                )
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    /// Send a user notification with the given title
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: Optional notification body text
    ///   - completion: Optional completion handler with error if failed
    /// - Note: Rate limited to prevent notification spam. Duplicate notifications within the minimum interval
    ///         will result in a `NotificationError.rateLimited` error passed to the completion handler.
    func send(title: String, body: String? = nil, completion: ((Error?) -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }

            // Create a key based on title and body for deduplication
            let notificationKey = "\(title):\(body ?? "")"
            let now = Date()

            // Check if we recently sent this notification
            if let lastSent = self.recentNotifications[notificationKey] {
                let timeSinceLastSent = now.timeIntervalSince(lastSent)
                if timeSinceLastSent < self.minimumInterval {
                    // Too soon, skip this notification
                    let error = NotificationError.rateLimited(
                        title: title,
                        body: body,
                        timeSinceLastSent: timeSinceLastSent
                    )
                    ErrorHandler.shared.debug(
                        error.localizedDescription,
                        context: "NotificationService"
                    )
                    DispatchQueue.main.async {
                        completion?(error)
                    }
                    return
                }
            }

            // Update the timestamp for this notification
            self.recentNotifications[notificationKey] = now

            // Clean up old entries (older than 2x minimum interval)
            let cutoffTime = now.addingTimeInterval(-self.minimumInterval * 2)
            self.recentNotifications = self.recentNotifications.filter { $0.value > cutoffTime }

            // Send the notification
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
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }

    /// Clear the rate limiting cache (useful for testing)
    func clearRateLimitCache() {
        queue.async { [weak self] in
            self?.recentNotifications.removeAll()
        }
    }
}
