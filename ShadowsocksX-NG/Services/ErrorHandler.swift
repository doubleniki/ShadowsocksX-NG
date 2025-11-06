//
//  ErrorHandler.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 1
//  Centralized error handling and logging
//

import Cocoa
import os.log

/// Centralized error handler for the application
class ErrorHandler {

    // MARK: - Shared Instance

    static let shared = ErrorHandler()

    // MARK: - Private Properties

    private let logger: OSLog

    // MARK: - Initialization

    private init() {
        self.logger = OSLog(
            subsystem: "com.qiuyuzhou.shadowsocksX-NG",
            category: "ErrorHandler"
        )
    }

    // MARK: - Public Methods

    /// Handle an error with logging and optional user notification
    ///
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context about where the error occurred
    ///   - showAlert: Whether to show an alert to the user
    /// Handles and logs an error, optionally presenting a user alert.
    /// - Parameters:
    ///   - error: The error to handle and record.
    ///   - context: An optional human-readable context; if `nil` the handler uses `AppError.context` when `error` is an `AppError`, otherwise `"Unknown"`.
    ///   - showAlert: If `true`, presents an alert to the user describing the error.
    ///   - critical: If `true`, treats the error as critical for logging and alert presentation.
    func handle(
        _ error: Error,
        context: String? = nil,
        showAlert: Bool = false,
        critical: Bool = false
    ) {
        // Determine context
        let errorContext: String
        if let ctx = context {
            errorContext = ctx
        } else if let appError = error as? AppError {
            errorContext = appError.context
        } else {
            errorContext = "Unknown"
        }

        // Log error
        logError(error, context: errorContext, critical: critical)

        // Show alert if requested
        if showAlert {
            showAlert(for: error, context: errorContext, critical: critical)
        }
    }

    /// Handle an error and return a default value
    ///
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context
    ///   - defaultValue: Default value to return
    /// Handles an error by logging it without presenting a user alert.
    /// - Parameters:
    ///   - error: The error to handle.
    ///   - context: Optional context string to include in logs.
    ///   - defaultValue: The value to return after handling the error.
    /// - Returns: The provided `defaultValue`.
    func handleAndReturn<T>(
        _ error: Error,
        context: String? = nil,
        defaultValue: T
    ) -> T {
        handle(error, context: context, showAlert: false, critical: false)
        return defaultValue
    }

    // MARK: - Private Methods

    /// Logs an error to the internal logger with an appropriate severity and includes any underlying error details.
    /// - Parameters:
    ///   - error: The error to log.
    ///   - context: A short context label included in the log message.
    ///   - critical: If `true`, logs at the error/critical level and marks the message as critical; otherwise logs at the default level.
    private func logError(_ error: Error, context: String, critical: Bool) {
        let message = formatErrorMessage(error, context: context)

        if critical {
            os_log(.error, log: logger, "CRITICAL [%{public}@]: %{public}@", context, message)
        } else {
            os_log(.default, log: logger, "[%{public}@]: %{public}@", context, message)
        }

        // Log underlying error if present
        if let appError = error as? AppError,
           let underlyingError = appError.underlyingError {
            os_log(.default, log: logger, "  Underlying: %{public}@", underlyingError.localizedDescription)
        }
    }

    /// Produce a human-readable error message, preferring an `AppError`'s `errorDescription` when available.
    /// - Returns: A string containing the error description; uses `AppError.errorDescription` if present, otherwise `error.localizedDescription`.
    private func formatErrorMessage(_ error: Error, context: String) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }

    /// Displays an alert on the main thread showing the provided error and context; adds a "View Logs" button for critical errors.
    /// - Parameters:
    ///   - error: The error whose message (and underlying error details, if present) will be shown.
    ///   - context: A short title or context string displayed as the alert's main message.
    ///   - critical: If `true`, uses a critical alert style and includes a "View Logs" button that opens the app log directory when selected.
    private func showAlert(for error: Error, context: String, critical: Bool) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = context
            alert.informativeText = self.formatErrorMessage(error, context: context)
            alert.alertStyle = critical ? .critical : .warning

            // Add underlying error details if available
            if let appError = error as? AppError,
               let underlying = appError.underlyingError {
                alert.informativeText += "\n\nDetails: \(underlying.localizedDescription)"
            }

            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))

            if critical {
                alert.addButton(withTitle: NSLocalizedString("View Logs", comment: ""))
            }

            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                self.openLogFile()
            }
        }
    }

    /// Opens the application's log directory in Finder by revealing ~/Library/Logs/ShadowsocksX-NG.
    private func openLogFile() {
        let logPath = NSHomeDirectory() + "/Library/Logs/ShadowsocksX-NG"
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: logPath)
    }
}

// MARK: - Convenience Extensions

extension ErrorHandler {

    /// Logs a warning-level message to the error handler's logger with an associated context.
    /// - Parameters:
    ///   - message: The warning message to record.
    ///   - context: A short context or category for the message; defaults to "General".
    func warning(_ message: String, context: String = "General") {
        os_log(.default, log: logger, "WARNING [%{public}@]: %{public}@", context, message)
    }

    /// Logs an informational message tagged with a context label.
    /// - Parameters:
    ///   - message: The message text to log.
    ///   - context: A short label describing the context or subsystem (defaults to "General").
    func info(_ message: String, context: String = "General") {
        os_log(.info, log: logger, "[%{public}@]: %{public}@", context, message)
    }

    /// Logs a debug-level message with an optional context tag.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - context: A contextual tag included in the log output; defaults to `"General"`.
    func debug(_ message: String, context: String = "General") {
        os_log(.debug, log: logger, "[%{public}@]: %{public}@", context, message)
    }
}