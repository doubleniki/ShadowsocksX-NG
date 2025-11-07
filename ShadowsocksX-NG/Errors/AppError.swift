//
//  AppError.swift
//  ShadowsocksX-NG
//
//  Created for refactoring - Phase 1
//  Error types for application-wide error handling
//

import Foundation

// MARK: - Base Error Protocol

/// Base protocol for all application errors
protocol AppError: LocalizedError {
    /// Context in which the error occurred
    var context: String { get }

    /// Underlying system error if any
    var underlyingError: Error? { get }
}

// MARK: - Launch Agent Errors

/// Errors related to Launch Agent operations
enum LaunchAgentError: AppError {
    case directoryCreationFailed(path: String, error: Error)
    case plistGenerationFailed(service: String, error: Error)
    case serviceStartFailed(service: String, exitCode: Int32)
    case serviceStopFailed(service: String, error: Error)
    case serviceNotFound(service: String)
    case invalidConfiguration(reason: String)

    var context: String {
        switch self {
        case .directoryCreationFailed:
            return "Launch Agent Setup"
        case .plistGenerationFailed:
            return "Service Configuration"
        case .serviceStartFailed, .serviceStopFailed, .serviceNotFound:
            return "Service Control"
        case .invalidConfiguration:
            return "Configuration Validation"
        }
    }

    var underlyingError: Error? {
        switch self {
        case .directoryCreationFailed(_, let error):
            return error
        case .plistGenerationFailed(_, let error):
            return error
        case .serviceStopFailed(_, let error):
            return error
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let path, let error):
            return "Failed to create directory at \(path): \(error.localizedDescription)"
        case .plistGenerationFailed(let service, let error):
            return "Failed to generate configuration for \(service): \(error.localizedDescription)"
        case .serviceStartFailed(let service, let exitCode):
            return "Failed to start \(service) (exit code: \(exitCode))"
        case .serviceStopFailed(let service, let error):
            return "Failed to stop \(service): \(error.localizedDescription)"
        case .serviceNotFound(let service):
            return "Service not found: \(service)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
}

// MARK: - PAC Errors

/// Errors related to PAC (Proxy Auto-Configuration) operations
enum PACError: AppError {
    case templateNotFound(path: String)
    case writeFailed(path: String, error: Error)
    case downloadFailed(url: String, error: Error)
    case invalidFormat(reason: String)
    case ruleParsingFailed(error: Error)

    var context: String {
        return "PAC Configuration"
    }

    var underlyingError: Error? {
        switch self {
        case .writeFailed(_, let error):
            return error
        case .downloadFailed(_, let error):
            return error
        case .ruleParsingFailed(let error):
            return error
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .templateNotFound(let path):
            return "PAC template file not found at \(path)"
        case .writeFailed(let path, let error):
            return "Failed to write PAC file to \(path): \(error.localizedDescription)"
        case .downloadFailed(let url, let error):
            return "Failed to download GFW list from \(url): \(error.localizedDescription)"
        case .invalidFormat(let reason):
            return "Invalid GFW list format: \(reason)"
        case .ruleParsingFailed(let error):
            return "Failed to parse rules: \(error.localizedDescription)"
        }
    }
}

// MARK: - Server Profile Errors

/// Errors related to server profile operations
enum ServerProfileError: AppError {
    case invalidHost(String)
    case invalidPort(Int)
    case emptyPassword
    case invalidMethod(String)
    case urlParsingFailed(url: String)
    case serializationFailed(error: Error)
    case deserializationFailed(error: Error)
    case keychainAccessFailed(error: Error)

    var context: String {
        return "Server Profile"
    }

    var underlyingError: Error? {
        switch self {
        case .serializationFailed(let error):
            return error
        case .deserializationFailed(let error):
            return error
        case .keychainAccessFailed(let error):
            return error
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidHost(let host):
            return "Invalid server host: \(host)"
        case .invalidPort(let port):
            return "Invalid port number: \(port). Must be between 1 and 65535"
        case .emptyPassword:
            return "Password cannot be empty"
        case .invalidMethod(let method):
            return "Invalid encryption method: \(method)"
        case .urlParsingFailed(let url):
            return "Failed to parse server URL: \(url)"
        case .serializationFailed(let error):
            return "Failed to serialize profile: \(error.localizedDescription)"
        case .deserializationFailed(let error):
            return "Failed to deserialize profile: \(error.localizedDescription)"
        case .keychainAccessFailed(let error):
            return "Failed to access keychain: \(error.localizedDescription)"
        }
    }
}

// MARK: - File System Errors

/// Errors related to file system operations
enum FileSystemError: AppError {
    case fileNotFound(path: String)
    case permissionDenied(path: String)
    case readFailed(path: String, error: Error)
    case writeFailed(path: String, error: Error)
    case deleteFailed(path: String, error: Error)
    case copyFailed(source: String, destination: String, error: Error)
    case moveFailed(source: String, destination: String, error: Error)
    case invalidPath(path: String)

    var context: String {
        return "File System"
    }

    var underlyingError: Error? {
        switch self {
        case .readFailed(_, let error):
            return error
        case .writeFailed(_, let error):
            return error
        case .deleteFailed(_, let error):
            return error
        case .copyFailed(_, _, let error):
            return error
        case .moveFailed(_, _, let error):
            return error
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .readFailed(let path, let error):
            return "Failed to read file at \(path): \(error.localizedDescription)"
        case .writeFailed(let path, let error):
            return "Failed to write file to \(path): \(error.localizedDescription)"
        case .deleteFailed(let path, let error):
            return "Failed to delete file at \(path): \(error.localizedDescription)"
        case .copyFailed(let source, let destination, let error):
            return
                "Failed to copy file from \(source) to \(destination): \(error.localizedDescription)"
        case .moveFailed(let source, let destination, let error):
            return
                "Failed to move file from \(source) to \(destination): \(error.localizedDescription)"
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        }
    }
}

// MARK: - Resource Errors

/// Errors related to resource loading
enum ResourceError: AppError {
    case imageNotFound(name: String)
    case nibNotFound(name: String)
    case resourceNotFound(name: String, type: String)

    var context: String {
        return "Resource Loading"
    }

    var underlyingError: Error? {
        return nil
    }

    var errorDescription: String? {
        switch self {
        case .imageNotFound(let name):
            return "Image resource not found: \(name)"
        case .nibNotFound(let name):
            return "NIB file not found: \(name)"
        case .resourceNotFound(let name, let type):
            return "Resource not found: \(name).\(type)"
        }
    }
}
