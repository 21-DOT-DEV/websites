//
//  CanonicalCICLITests.swift
//  UtilitiesCLITests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import Subprocess
import System
@testable import Utilities

@Suite("Canonical CI Integration Tests")
struct CanonicalCICLITests {
    
    // MARK: - Exit Code Tests
    
    @Test("Check command exits 0 when all canonicals valid")
    func checkExitsZeroWhenValid() async throws {
        // Create temp directory with valid HTML
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://test.dev/">
        </head>
        <body></body>
        </html>
        """
        try html.write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "check", "--path", tempDir.path, "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0, "Expected exit code 0 for valid canonicals, got \(code)")
    }
    
    @Test("Check command exits 1 when canonicals missing")
    func checkExitsOneWhenMissing() async throws {
        // Create temp directory with HTML missing canonical
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
        </head>
        <body></body>
        </html>
        """
        try html.write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "check", "--path", tempDir.path, "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 1, "Expected exit code 1 for missing canonicals, got \(code)")
    }
    
    @Test("Check command exits 1 when canonicals mismatch")
    func checkExitsOneWhenMismatch() async throws {
        // Create temp directory with mismatched canonical
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://wrong.dev/">
        </head>
        <body></body>
        </html>
        """
        try html.write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "check", "--path", tempDir.path, "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 1, "Expected exit code 1 for mismatched canonicals, got \(code)")
    }
    
    // MARK: - Validation Error Tests
    
    @Test("Check command exits non-zero for invalid path")
    func checkExitsNonZeroForInvalidPath() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "check", "--path", "/nonexistent/path/xyz", "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0, "Expected non-zero exit code for invalid path")
        
        let stderr = result.standardError ?? ""
        #expect(stderr.contains("Path") || stderr.contains("path") || stderr.contains("directory"),
                "Error message should mention path issue")
    }
    
    @Test("Check command exits non-zero for invalid URL scheme")
    func checkExitsNonZeroForInvalidURLScheme() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "check", "--path", "/tmp", "--base-url", "not-a-valid-url"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0, "Expected non-zero exit code for invalid URL")
        
        let stderr = result.standardError ?? ""
        #expect(stderr.contains("URL") || stderr.contains("scheme"),
                "Error message should mention URL issue")
    }
    
    // MARK: - Fix Command CI Tests
    
    @Test("Fix command with dry-run exits 0 and doesn't modify files")
    func fixDryRunExitsZero() async throws {
        // Create temp directory with HTML missing canonical
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let originalHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
        </head>
        <body></body>
        </html>
        """
        let filePath = tempDir.appendingPathComponent("index.html")
        try originalHTML.write(to: filePath, atomically: true, encoding: .utf8)
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--path", tempDir.path, "--base-url", "https://test.dev", "--dry-run"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0, "Expected exit code 0 for dry-run fix")
        
        // Verify file was not modified
        let currentHTML = try String(contentsOf: filePath, encoding: .utf8)
        #expect(!currentHTML.contains("canonical"), "File should not be modified in dry-run mode")
    }
}
