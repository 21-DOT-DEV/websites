//
//  CanonicalCheckCLITests.swift
//  UtilitiesCLITests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import Subprocess
import System

@Suite("Canonical Check CLI Tests")
struct CanonicalCheckCLITests {

    @Test("canonical fix --check requires path argument")
    func requiresPathArgument() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--check", "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }
    
    @Test("canonical fix --check requires base-url argument")
    func requiresBaseURLArgument() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--check", "--path", "/tmp"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }
    
    @Test("canonical fix --check validates path exists")
    func validatesPathExists() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--check", "--path", "/nonexistent/path", "--base-url", "https://test.dev"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }
    
    @Test("canonical fix --check validates base-url has scheme")
    func validatesBaseURLScheme() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["canonical", "fix", "--check", "--path", "/tmp", "--base-url", "example.com"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }
}
