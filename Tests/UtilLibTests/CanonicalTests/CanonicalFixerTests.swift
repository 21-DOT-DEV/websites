//
//  CanonicalFixerTests.swift
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

@Suite("CanonicalFixer Tests")
struct CanonicalFixerTests {
    
    let baseURL = URL(string: "https://21.dev")!
    
    @Test("Insert canonical into HTML with head")
    func insertCanonical() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test Page</title>
        </head>
        <body>Content</body>
        </html>
        """
        
        let result = try CanonicalFixer.insertCanonical(
            html: html,
            canonicalURL: URL(string: "https://21.dev/test/")!
        )
        
        // SwiftSoup outputs XHTML-style self-closing tags
        #expect(result.contains("rel=\"canonical\""))
        #expect(result.contains("href=\"https://21.dev/test/\""))
        #expect(result.contains("Test Page"))
    }
    
    @Test("Insert canonical preserves existing content")
    func preservesExistingContent() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Test</title>
            <link rel="stylesheet" href="/style.css">
        </head>
        <body><h1>Hello</h1></body>
        </html>
        """
        
        let result = try CanonicalFixer.insertCanonical(
            html: html,
            canonicalURL: URL(string: "https://21.dev/")!
        )
        
        #expect(result.contains("<meta charset=\"utf-8\">") || result.contains("charset=\"utf-8\""))
        #expect(result.contains("<title>Test</title>"))
        #expect(result.contains("stylesheet"))
        #expect(result.contains("<h1>Hello</h1>"))
    }
    
    @Test("Replace existing canonical with force")
    func replaceCanonicalWithForce() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://old.dev/page/">
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalFixer.replaceCanonical(
            html: html,
            newCanonicalURL: URL(string: "https://21.dev/page/")!
        )
        
        #expect(result.contains("https://21.dev/page/"))
        #expect(!result.contains("https://old.dev/page/"))
    }
    
    @Test("Fix missing canonical returns added action")
    func fixMissingCanonical() throws {
        let checkResult = CanonicalResult(
            filePath: "/test/index.html",
            relativePath: "index.html",
            status: .missing,
            existingURL: nil,
            expectedURL: URL(string: "https://21.dev/")!,
            errorMessage: nil
        )
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body></body>
        </html>
        """
        
        let (fixedHTML, action) = try CanonicalFixer.fix(
            html: html,
            checkResult: checkResult,
            force: false
        )
        
        #expect(action == .added)
        #expect(fixedHTML.contains("canonical"))
    }
    
    @Test("Fix mismatch without force returns skipped")
    func fixMismatchWithoutForce() throws {
        let checkResult = CanonicalResult(
            filePath: "/test/page.html",
            relativePath: "page.html",
            status: .mismatch,
            existingURL: URL(string: "https://old.dev/page")!,
            expectedURL: URL(string: "https://21.dev/page")!,
            errorMessage: nil
        )
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://old.dev/page">
        </head>
        <body></body>
        </html>
        """
        
        let (fixedHTML, action) = try CanonicalFixer.fix(
            html: html,
            checkResult: checkResult,
            force: false
        )
        
        #expect(action == .skipped)
        #expect(fixedHTML == html) // Unchanged
    }
    
    @Test("Fix mismatch with force returns updated")
    func fixMismatchWithForce() throws {
        let checkResult = CanonicalResult(
            filePath: "/test/page.html",
            relativePath: "page.html",
            status: .mismatch,
            existingURL: URL(string: "https://old.dev/page")!,
            expectedURL: URL(string: "https://21.dev/page")!,
            errorMessage: nil
        )
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://old.dev/page">
        </head>
        <body></body>
        </html>
        """
        
        let (fixedHTML, action) = try CanonicalFixer.fix(
            html: html,
            checkResult: checkResult,
            force: true
        )
        
        #expect(action == .updated)
        #expect(fixedHTML.contains("https://21.dev/page"))
        #expect(!fixedHTML.contains("https://old.dev/page"))
    }
    
    @Test("Fix valid returns skipped")
    func fixValidReturnsSkipped() throws {
        let checkResult = CanonicalResult(
            filePath: "/test/index.html",
            relativePath: "index.html",
            status: .valid,
            existingURL: URL(string: "https://21.dev/")!,
            expectedURL: URL(string: "https://21.dev/")!,
            errorMessage: nil
        )
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://21.dev/">
        </head>
        <body></body>
        </html>
        """
        
        let (_, action) = try CanonicalFixer.fix(
            html: html,
            checkResult: checkResult,
            force: false
        )
        
        #expect(action == .skipped)
    }
    
    @Test("Fix error returns failed")
    func fixErrorReturnsFailed() throws {
        let checkResult = CanonicalResult(
            filePath: "/test/broken.html",
            relativePath: "broken.html",
            status: .error,
            existingURL: nil,
            expectedURL: URL(string: "https://21.dev/broken")!,
            errorMessage: "No head section"
        )
        
        let html = "<html><body>No head</body></html>"
        
        let (_, action) = try CanonicalFixer.fix(
            html: html,
            checkResult: checkResult,
            force: false
        )
        
        #expect(action == .failed)
    }
}
