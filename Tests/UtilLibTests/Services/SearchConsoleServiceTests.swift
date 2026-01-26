//
//  SearchConsoleServiceTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

// MARK: - SearchConsoleError Tests

@Suite("SearchConsoleError Tests")
struct SearchConsoleErrorTests {
    
    @Test("SearchConsoleError.invalidSitemapURL has descriptive message")
    func invalidSitemapURLMessage() {
        let error = SearchConsoleError.invalidSitemapURL("bad-url")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("sitemap"))
        #expect(description.contains("bad-url"))
    }
    
    @Test("SearchConsoleError.submissionFailed has descriptive message")
    func submissionFailedMessage() {
        let error = SearchConsoleError.submissionFailed(403, "Forbidden")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("403"))
        #expect(description.contains("Forbidden"))
    }
}

// MARK: - Site URL Formatting Tests

@Suite("SearchConsoleService Site URL Tests")
struct SiteURLTests {
    
    @Test("formatSiteURL creates sc-domain format from sitemap URL")
    func formatsSCDomain() {
        let sitemapURL = "https://21.dev/sitemap.xml"
        let siteURL = SearchConsoleService.formatSiteURL(from: sitemapURL)
        
        #expect(siteURL == "sc-domain:21.dev")
    }
    
    @Test("formatSiteURL handles subdomain")
    func handlesSubdomain() {
        let sitemapURL = "https://docs.21.dev/sitemap.xml"
        let siteURL = SearchConsoleService.formatSiteURL(from: sitemapURL)
        
        #expect(siteURL == "sc-domain:docs.21.dev")
    }
    
    @Test("formatSiteURL handles www subdomain")
    func handlesWWW() {
        let sitemapURL = "https://www.example.com/sitemap.xml"
        let siteURL = SearchConsoleService.formatSiteURL(from: sitemapURL)
        
        #expect(siteURL == "sc-domain:www.example.com")
    }
    
    @Test("formatSiteURL strips path from URL")
    func stripsPath() {
        let sitemapURL = "https://21.dev/deep/path/sitemap.xml"
        let siteURL = SearchConsoleService.formatSiteURL(from: sitemapURL)
        
        #expect(siteURL == "sc-domain:21.dev")
    }
}

// MARK: - Sitemap URL Derivation Tests

@Suite("SearchConsoleService Sitemap URL Derivation Tests")
struct SitemapURLDerivationTests {
    
    @Test("deriveSitemapURL for 21-dev site")
    func derives21DevURL() {
        let url = SearchConsoleService.deriveSitemapURL(for: .dev21)
        
        #expect(url == "https://21.dev/sitemap.xml")
    }
    
    @Test("deriveSitemapURL for docs-21-dev site")
    func derivesDocs21DevURL() {
        let url = SearchConsoleService.deriveSitemapURL(for: .docs21dev)
        
        #expect(url == "https://docs.21.dev/sitemap.xml")
    }
    
    @Test("deriveSitemapURL for md-21-dev site")
    func derivesMd21DevURL() {
        let url = SearchConsoleService.deriveSitemapURL(for: .md21dev)
        
        #expect(url == "https://md.21.dev/sitemap.xml")
    }
}

// MARK: - API Request Building Tests

@Suite("SearchConsoleService API Request Tests")
struct APIRequestTests {
    
    @Test("buildSubmitRequest creates correct URL")
    func correctURL() throws {
        let request = try SearchConsoleService.buildSubmitRequest(
            sitemapURL: "https://21.dev/sitemap.xml",
            accessToken: "test-token"
        )
        
        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("googleapis.com/webmasters/v3/sites"))
        #expect(urlString.contains("sitemaps"))
    }
    
    @Test("buildSubmitRequest uses PUT method")
    func usesPUTMethod() throws {
        let request = try SearchConsoleService.buildSubmitRequest(
            sitemapURL: "https://21.dev/sitemap.xml",
            accessToken: "test-token"
        )
        
        #expect(request.httpMethod == "PUT")
    }
    
    @Test("buildSubmitRequest includes Authorization header")
    func includesAuthHeader() throws {
        let request = try SearchConsoleService.buildSubmitRequest(
            sitemapURL: "https://21.dev/sitemap.xml",
            accessToken: "test-token"
        )
        
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer test-token")
    }
    
    @Test("buildSubmitRequest URL-encodes site URL")
    func urlEncodesSiteURL() throws {
        let request = try SearchConsoleService.buildSubmitRequest(
            sitemapURL: "https://21.dev/sitemap.xml",
            accessToken: "test-token"
        )
        
        let urlString = request.url?.absoluteString ?? ""
        // sc-domain:21.dev must have colon encoded as %3A for Google API
        #expect(urlString.contains("sc-domain%3A21.dev"))
    }
    
    @Test("buildSubmitRequest URL-encodes sitemap URL")
    func urlEncodesSitemapURL() throws {
        let request = try SearchConsoleService.buildSubmitRequest(
            sitemapURL: "https://21.dev/sitemap.xml",
            accessToken: "test-token"
        )
        
        let urlString = request.url?.absoluteString ?? ""
        // https:// must have colons and slashes encoded for Google API
        #expect(urlString.contains("https%3A%2F%2F21.dev%2Fsitemap.xml"))
    }
}

// MARK: - Response Parsing Tests

@Suite("SearchConsoleService Response Parsing Tests")
struct ResponseParsingTests {
    
    @Test("parseSubmitResponse succeeds for 204 status")
    func succeeds204() throws {
        let result = SearchConsoleService.parseSubmitResponse(statusCode: 204, body: nil)
        
        #expect(result.success == true)
    }
    
    @Test("parseSubmitResponse succeeds for 200 status")
    func succeeds200() throws {
        let result = SearchConsoleService.parseSubmitResponse(statusCode: 200, body: nil)
        
        #expect(result.success == true)
    }
    
    @Test("parseSubmitResponse fails for 403 status")
    func fails403() throws {
        let result = SearchConsoleService.parseSubmitResponse(
            statusCode: 403,
            body: Data("{\"error\":{\"message\":\"Forbidden\"}}".utf8)
        )
        
        #expect(result.success == false)
        #expect(result.errorMessage?.contains("403") == true)
    }
    
    @Test("parseSubmitResponse fails for 404 status")
    func fails404() throws {
        let result = SearchConsoleService.parseSubmitResponse(
            statusCode: 404,
            body: Data("{\"error\":{\"message\":\"Not Found\"}}".utf8)
        )
        
        #expect(result.success == false)
        #expect(result.errorMessage?.contains("404") == true)
    }
}

// MARK: - Output Formatting Tests

@Suite("SearchConsoleService Output Tests")
struct OutputFormattingTests {
    
    @Test("formatSuccessOutput includes sitemap URL")
    func successIncludesURL() {
        let output = SearchConsoleService.formatSuccessOutput(sitemapURL: "https://21.dev/sitemap.xml")
        
        #expect(output.contains("21.dev/sitemap.xml"))
        #expect(output.contains("✅") || output.contains("success"))
    }
    
    @Test("formatErrorOutput includes error details")
    func errorIncludesDetails() {
        let output = SearchConsoleService.formatErrorOutput(
            sitemapURL: "https://21.dev/sitemap.xml",
            error: "Permission denied"
        )
        
        #expect(output.contains("Permission denied"))
        #expect(output.contains("❌") || output.contains("fail") || output.contains("error"))
    }
    
    @Test("formatJSONOutput for success")
    func jsonSuccessOutput() throws {
        let output = SearchConsoleService.formatJSONOutput(
            success: true,
            sitemapURL: "https://21.dev/sitemap.xml",
            error: nil
        )
        
        let data = output.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["success"] as? Bool == true)
        #expect(json["sitemapUrl"] as? String == "https://21.dev/sitemap.xml")
        #expect(json["provider"] as? String == "google")
    }
    
    @Test("formatJSONOutput for failure")
    func jsonFailureOutput() throws {
        let output = SearchConsoleService.formatJSONOutput(
            success: false,
            sitemapURL: "https://21.dev/sitemap.xml",
            error: "Permission denied"
        )
        
        let data = output.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["success"] as? Bool == false)
        #expect(json["error"] as? String == "Permission denied")
    }
}
