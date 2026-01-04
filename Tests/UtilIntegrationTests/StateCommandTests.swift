//
//  StateCommandTests.swift
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

@Suite("State CLI Command Tests")
struct StateCommandTests {
    
    @Test("util state update --help shows usage")
    func updateHelpOutput() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["state", "update", "--help"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            Issue.record("Command failed with non-zero exit")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("--package-version"))
        #expect(output.contains("--file"))
    }
    
    @Test("util state validate --help shows usage")
    func validateHelpOutput() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["state", "validate", "--help"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            Issue.record("Command failed with non-zero exit")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("--file"))
    }
    
    @Test("util state update creates state file")
    func updateCreatesFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-cli-state-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json").path
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["state", "update", "--package-version", "1.0.0", "--file", statePath],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            let stderr = result.standardError ?? "unknown error"
            Issue.record("Command failed: \(stderr)")
            return
        }
        
        #expect(FileManager.default.fileExists(atPath: statePath))
    }
    
    @Test("util state validate passes for valid file")
    func validatePassesForValidFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-cli-validate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        let json = """
        {
            "package_version": "0.21.1",
            "generated_date": "2025-12-15T12:00:00Z",
            "subdomains": {}
        }
        """
        try json.write(to: statePath, atomically: true, encoding: .utf8)
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["state", "validate", "--file", statePath.path],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            let stderr = result.standardError ?? "unknown error"
            Issue.record("Command failed: \(stderr)")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅") || output.contains("valid"))
    }
}
