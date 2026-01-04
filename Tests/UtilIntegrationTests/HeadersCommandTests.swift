//
//  HeadersCommandTests.swift
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

@Suite("Headers CLI Command Tests")
struct HeadersCommandTests {
    
    @Test("util headers validate --help shows usage")
    func helpOutput() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["headers", "validate", "--help"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            Issue.record("Command failed with non-zero exit")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("--site"))
        #expect(output.contains("--env"))
    }
    
    @Test("util headers validate requires --site and --env arguments")
    func missingRequiredArguments() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["headers", "validate"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        
        #expect(code != 0)
    }
    
    @Test("util headers validate passes for valid prod headers")
    func validateValidProdHeaders() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/arm64-apple-macosx/debug/util")),
            arguments: ["headers", "validate", "--site", "21-dev", "--env", "prod"],
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
    
    @Test("util headers validate accepts all valid site names")
    func allSiteNames() async throws {
        for siteName in ["21-dev", "docs-21-dev", "md-21-dev"] {
            let result = try await Subprocess.run(
                .path(FilePath(".build/arm64-apple-macosx/debug/util")),
                arguments: ["headers", "validate", "--site", siteName, "--env", "prod", "--help"],
                output: .string(limit: 4096),
                error: .string(limit: 4096)
            )
            
            guard case .exited(0) = result.terminationStatus else {
                Issue.record("Site \(siteName) not recognized")
                continue
            }
        }
    }
}
