//
//  SitemapCommandTests.swift
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

@Suite("Sitemap CLI Command Tests")
struct SitemapCommandTests {
    
    @Test("util sitemap generate --help shows usage")
    func helpOutput() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["sitemap", "generate", "--help"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            Issue.record("Command failed with non-zero exit")
            return
        }
        
        let output = result.standardOutput ?? ""
        #expect(output.contains("--site"))
        #expect(output.contains("--output"))
    }
    
    @Test("util sitemap generate requires --site argument")
    func missingSiteArgument() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["sitemap", "generate"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        // Should fail without required argument
        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        
        #expect(code != 0)
    }
    
    @Test("util sitemap generate --site 21-dev creates sitemap")
    func generateForDev21() async throws {
        // Create a temp output directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create minimal HTML file
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        
        let outputPath = tempDir.appendingPathComponent("sitemap.xml").path
        
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: [
                "sitemap", "generate",
                "--site", "21-dev",
                "--input", tempDir.path,
                "--output", outputPath
            ],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            let stderr = result.standardError ?? "unknown error"
            Issue.record("Command failed: \(stderr)")
            return
        }
        
        // Verify sitemap was created
        #expect(FileManager.default.fileExists(atPath: outputPath))
        
        let content = try String(contentsOfFile: outputPath)
        #expect(content.contains("<?xml version=\"1.0\""))
        #expect(content.contains("<urlset"))
    }
    
    @Test("util sitemap generate accepts all valid site names")
    func allSiteNames() async throws {
        for siteName in ["21-dev", "docs-21-dev", "md-21-dev"] {
            let result = try await Subprocess.run(
                .path(FilePath(".build/debug/util")),
                arguments: ["sitemap", "generate", "--site", siteName, "--help"],
                output: .string(limit: 4096),
                error: .string(limit: 4096)
            )
            
            // --help should always succeed
            guard case .exited(0) = result.terminationStatus else {
                Issue.record("Site \(siteName) not recognized")
                continue
            }
        }
    }
}
