//
//  ErrorHandler.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 1
//  Centralized error handling and logging
//

import Cocoa
import os.log

// MARK: - Error Handler

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
    ///   - critical: Whether this is a critical error
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
            self.showAlert(for: error, context: errorContext, critical: critical)
        }
    }

    /// Handle an error and return a default value
    ///
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context
    ///   - defaultValue: Default value to return
    /// - Returns: The default value
    func handleAndReturn<T>(
        _ error: Error,
        context: String? = nil,
        defaultValue: T
    ) -> T {
        handle(error, context: context, showAlert: false, critical: false)
        return defaultValue
    }

    // MARK: - Private Methods

    /// Log error to system log
    private func logError(_ error: Error, context: String, critical: Bool) {
        let message = formatErrorMessage(error, context: context)

        if #available(macOS 10.14, *) {
            if critical {
                os_log(.error, log: logger, "CRITICAL [%{public}@]: %{public}@", context, message)
            } else {
                os_log(.default, log: logger, "[%{public}@]: %{public}@", context, message)
            }

            // Log underlying error if present
            if let appError = error as? AppError,
                let underlyingError = appError.underlyingError
            {
                os_log(
                    .default, log: logger, "  Underlying: %{public}@",
                    underlyingError.localizedDescription)
            }
        } else {
            // Fallback for older macOS versions
            let prefix = critical ? "CRITICAL" : "ERROR"
            NSLog("[\(prefix)][\(context)]: \(message)")

            if let appError = error as? AppError,
                let underlyingError = appError.underlyingError
            {
                NSLog("  Underlying: \(underlyingError.localizedDescription)")
            }
        }
    }

    /// Format error message for logging
    private func formatErrorMessage(_ error: Error, context: String) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }

    /// Show alert to user
    private func showAlert(for error: Error, context: String, critical: Bool) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = context
            alert.informativeText = self.formatErrorMessage(error, context: context)
            alert.alertStyle = critical ? .critical : .warning

            // Add underlying error details if available
            if let appError = error as? AppError,
                let underlying = appError.underlyingError
            {
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

    /// Open system log file
    private func openLogFile() {
        let logPath = NSHomeDirectory() + "/Library/Logs/ShadowsocksX-NG"
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: logPath)
    }
}

// MARK: - Convenience Extensions

extension ErrorHandler {

    /// Log a warning message
    func warning(_ message: String, context: String = "General") {
        if #available(macOS 10.14, *) {
            os_log(.default, log: logger, "WARNING [%{public}@]: %{public}@", context, message)
        } else {
            NSLog("[WARNING][\(context)]: \(message)")
        }
    }

    /// Log an info message
    func info(_ message: String, context: String = "General") {
        if #available(macOS 10.14, *) {
            os_log(.info, log: logger, "[%{public}@]: %{public}@", context, message)
        } else {
            NSLog("[INFO][\(context)]: \(message)")
        }
    }

    /// Log a debug message
    func debug(_ message: String, context: String = "General") {
        if #available(macOS 10.14, *) {
            os_log(.debug, log: logger, "[%{public}@]: %{public}@", context, message)
        } else {
            NSLog("[DEBUG][\(context)]: \(message)")
        }
    }
}
