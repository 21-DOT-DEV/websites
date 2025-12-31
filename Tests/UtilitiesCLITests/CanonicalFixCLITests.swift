//
//  CanonicalFixCLITests.swift
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

@Suite("Canonical Fix CLI Tests")
struct CanonicalFixCLITests {
    
    @Test("Fix command requires path argument")
    func requiresPathArgument() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }
    
    @Test("Fix command requires base-url argument")
    func requiresBaseURLArgument() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--path", "/tmp"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }
    
    @Test("Fix command supports dry-run flag")
    func supportsDryRunFlag() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--help"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            Issue.record("Help command failed")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("--dry-run"))
    }
    
    @Test("Fix command supports force flag")
    func supportsForceFlag() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--help"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            Issue.record("Help command failed")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("--force"))
    }
}
