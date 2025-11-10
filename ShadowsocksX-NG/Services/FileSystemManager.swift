//
//  FileSystemManager.swift
//  ShadowsocksX-NG
//
//  Created for refactoring Phase 2.3
//

import Foundation

/// Concrete implementation of `FileSystemManaging` backed by `FileManager`
final class FileSystemManager: FileSystemManaging {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        try fileManager.createDirectory(
            atPath: path,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: attributes
        )
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.copyItem(at: srcURL, to: dstURL)
    }

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.moveItem(at: srcURL, to: dstURL)
    }

    func removeItem(at URL: URL) throws {
        try fileManager.removeItem(at: URL)
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try fileManager.contentsOfDirectory(atPath: path)
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return try fileManager.attributesOfItem(atPath: path)
    }
}
