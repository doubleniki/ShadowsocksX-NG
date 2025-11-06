//
//  AppErrors.swift
//  ShadowsocksX-NG
//
//  Created for refactoring
//  Application-specific error types
//

import Foundation

// MARK: - Launch Agent Errors

/// Errors related to launch agent operations
enum LaunchAgentError: AppError {
    case directoryCreationFailed(path: String, error: Error)
    case serviceStartFailed(service: String, exitCode: Int32)
    case serviceStopFailed(service: String, error: Error)
    case plistGenerationFailed(service: String, error: Error)
    
    var context: String {
        return "Launch Agent"
    }
    
    var underlyingError: Error? {
        switch self {
        case .directoryCreationFailed(_, let error),
             .serviceStopFailed(_, let error),
             .plistGenerationFailed(_, let error):
            return error
        case .serviceStartFailed:
            return nil
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let path, _):
            return "Failed to create launch agent directory at: \(path)"
        case .serviceStartFailed(let service, let exitCode):
            return "Failed to start \(service) service (exit code: \(exitCode))"
        case .serviceStopFailed(let service, _):
            return "Failed to stop \(service) service"
        case .plistGenerationFailed(let service, _):
            return "Failed to generate plist for \(service) service"
        }
    }
}

// MARK: - Resource Errors

/// Errors related to resource loading
enum ResourceError: AppError {
    case resourceNotFound(name: String, type: String)
    case invalidResourceFormat(name: String, reason: String)
    
    var context: String {
        return "Resource"
    }
    
    var underlyingError: Error? {
        return nil
    }
    
    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name, let type):
            return "Resource not found: \(name).\(type)"
        case .invalidResourceFormat(let name, let reason):
            return "Invalid format for resource '\(name)': \(reason)"
        }
    }
}

// MARK: - File System Errors

/// Errors related to file system operations
enum FileSystemError: AppError {
    case readFailed(path: String, error: Error)
    case writeFailed(path: String, error: Error)
    case deleteFailed(path: String, error: Error)
    case copyFailed(source: String, destination: String, error: Error)
    case moveFailed(source: String, destination: String, error: Error)
    
    var context: String {
        return "File System"
    }
    
    var underlyingError: Error? {
        switch self {
        case .readFailed(_, let error),
             .writeFailed(_, let error),
             .deleteFailed(_, let error),
             .copyFailed(_, _, let error),
             .moveFailed(_, _, let error):
            return error
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .readFailed(let path, _):
            return "Failed to read file at: \(path)"
        case .writeFailed(let path, _):
            return "Failed to write file at: \(path)"
        case .deleteFailed(let path, _):
            return "Failed to delete file at: \(path)"
        case .copyFailed(let source, let destination, _):
            return "Failed to copy file from \(source) to \(destination)"
        case .moveFailed(let source, let destination, _):
            return "Failed to move file from \(source) to \(destination)"
        }
    }
}

// MARK: - PAC Errors

/// Errors related to PAC file operations
enum PACError: AppError {
    case generationFailed(reason: String)
    case invalidFormat(reason: String)
    case updateFailed(reason: String)
    
    var context: String {
        return "PAC"
    }
    
    var underlyingError: Error? {
        return nil
    }
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let reason):
            return "Failed to generate PAC file: \(reason)"
        case .invalidFormat(let reason):
            return "Invalid PAC format: \(reason)"
        case .updateFailed(let reason):
            return "Failed to update PAC file: \(reason)"
        }
    }
}
