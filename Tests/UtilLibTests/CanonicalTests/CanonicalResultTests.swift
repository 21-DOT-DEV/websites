//
//  CanonicalResultTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

@Suite("CanonicalResult Tests")
struct CanonicalResultTests {
    
    let baseURL = URL(string: "https://21.dev")!
    
    @Test("Create valid result")
    func createValidResult() {
        let expectedURL = URL(string: "https://21.dev/about/")!
        let existingURL = URL(string: "https://21.dev/about/")!
        
        let result = CanonicalResult(
            filePath: "/Users/test/Websites/21-dev/about/index.html",
            relativePath: "about/index.html",
            status: .valid,
            existingURL: existingURL,
            expectedURL: expectedURL,
            errorMessage: nil
        )
        
        #expect(result.filePath == "/Users/test/Websites/21-dev/about/index.html")
        #expect(result.relativePath == "about/index.html")
        #expect(result.status == .valid)
        #expect(result.existingURL == existingURL)
        #expect(result.expectedURL == expectedURL)
        #expect(result.errorMessage == nil)
    }
    
    @Test("Create missing result")
    func createMissingResult() {
        let expectedURL = URL(string: "https://21.dev/docs/")!
        
        let result = CanonicalResult(
            filePath: "/Users/test/Websites/21-dev/docs/index.html",
            relativePath: "docs/index.html",
            status: .missing,
            existingURL: nil,
            expectedURL: expectedURL,
            errorMessage: nil
        )
        
        #expect(result.status == .missing)
        #expect(result.existingURL == nil)
    }
    
    @Test("Create mismatch result")
    func createMismatchResult() {
        let expectedURL = URL(string: "https://21.dev/blog/")!
        let existingURL = URL(string: "https://old-domain.dev/blog/")!
        
        let result = CanonicalResult(
            filePath: "/Users/test/Websites/21-dev/blog/index.html",
            relativePath: "blog/index.html",
            status: .mismatch,
            existingURL: existingURL,
            expectedURL: expectedURL,
            errorMessage: nil
        )
        
        #expect(result.status == .mismatch)
        #expect(result.existingURL != result.expectedURL)
    }
    
    @Test("Create error result with message")
    func createErrorResult() {
        let expectedURL = URL(string: "https://21.dev/broken/")!
        
        let result = CanonicalResult(
            filePath: "/Users/test/Websites/21-dev/broken/index.html",
            relativePath: "broken/index.html",
            status: .error,
            existingURL: nil,
            expectedURL: expectedURL,
            errorMessage: "No <head> section found"
        )
        
        #expect(result.status == .error)
        #expect(result.errorMessage == "No <head> section found")
    }
    
    @Test("Result is Sendable")
    func isSendable() {
        let result = CanonicalResult(
            filePath: "/test/file.html",
            relativePath: "file.html",
            status: .valid,
            existingURL: URL(string: "https://21.dev/")!,
            expectedURL: URL(string: "https://21.dev/")!,
            errorMessage: nil
        )
        
        let sendable: any Sendable = result
        #expect(sendable is CanonicalResult)
    }
}
