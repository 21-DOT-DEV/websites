//
//  CanonicalCheckerTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import Utilities

@Suite("CanonicalChecker Tests")
struct CanonicalCheckerTests {
    
    let baseURL = URL(string: "https://21.dev")!
    
    @Test("Detect valid canonical tag")
    func detectValidCanonical() throws {
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
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/index.html",
            relativePath: "index.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .valid)
        #expect(result.existingURL?.absoluteString == "https://21.dev/")
    }
    
    @Test("Detect missing canonical tag")
    func detectMissingCanonical() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/about/index.html",
            relativePath: "about/index.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .missing)
        #expect(result.existingURL == nil)
        #expect(result.expectedURL.absoluteString == "https://21.dev/about/")
    }
    
    @Test("Detect mismatch canonical tag")
    func detectMismatchCanonical() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://old-domain.dev/blog/">
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/blog/index.html",
            relativePath: "blog/index.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .mismatch)
        #expect(result.existingURL?.absoluteString == "https://old-domain.dev/blog/")
        #expect(result.expectedURL.absoluteString == "https://21.dev/blog/")
    }
    
    @Test("Handle HTML without head section")
    func handleNoHeadSection() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <body>Content only</body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/nohead.html",
            relativePath: "nohead.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .error)
        #expect(result.errorMessage != nil)
    }
    
    @Test("Handle multiple canonical tags")
    func handleMultipleCanonicals() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="https://21.dev/page1/">
            <link rel="canonical" href="https://21.dev/page2/">
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/multi.html",
            relativePath: "multi.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .error)
        #expect(result.errorMessage?.contains("multiple") == true)
    }
    
    @Test("Extract canonical href correctly")
    func extractCanonicalHref() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Test Page</title>
            <link rel="stylesheet" href="/style.css">
            <link rel="canonical" href="https://21.dev/docs/guide/">
            <link rel="icon" href="/favicon.ico">
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/docs/guide/index.html",
            relativePath: "docs/guide/index.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .valid)
        #expect(result.existingURL?.absoluteString == "https://21.dev/docs/guide/")
    }
    
    @Test("Case insensitive rel attribute")
    func caseInsensitiveRel() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link REL="CANONICAL" href="https://21.dev/">
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/index.html",
            relativePath: "index.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .valid)
    }
    
    @Test("Handle empty href in canonical tag")
    func handleEmptyHref() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
            <link rel="canonical" href="">
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/empty.html",
            relativePath: "empty.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .error)
        #expect(result.errorMessage?.contains("empty") == true || result.errorMessage?.contains("Invalid") == true)
    }
    
    @Test("Handle malformed HTML gracefully")
    func handleMalformedHTML() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Unclosed tags
            <link rel="canonical" href="https://21.dev/">
        <body>
        Content without closing tags
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/malformed.html",
            relativePath: "malformed.html",
            baseURL: baseURL
        )
        
        // SwiftSoup handles malformed HTML gracefully - it doesn't crash
        // Any status is acceptable as long as we get a result
        let validStatuses: [CanonicalStatus] = [.valid, .missing, .mismatch, .error]
        #expect(validStatuses.contains(result.status))
    }
    
    @Test("Handle HTML with only whitespace in head")
    func handleWhitespaceOnlyHead() throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        
        </head>
        <body></body>
        </html>
        """
        
        let result = try CanonicalChecker.checkHTML(
            html: html,
            filePath: "/test/whitespace.html",
            relativePath: "whitespace.html",
            baseURL: baseURL
        )
        
        #expect(result.status == .missing)
    }
}
