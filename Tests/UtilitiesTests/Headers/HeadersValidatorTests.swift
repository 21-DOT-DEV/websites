//
//  HeadersValidatorTests.swift
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

@Suite("HeadersValidator Parsing Tests")
struct HeadersParsingTests {
    
    @Test("parseHeaders extracts path patterns and headers")
    func basicParsing() throws {
        let content = """
        /static/*
          Cache-Control: public, max-age=86400
          Vary: Accept-Encoding
        
        /*
          X-Frame-Options: DENY
        """
        
        let rules = try HeadersValidator.parseHeaders(content)
        
        #expect(rules.count == 2)
        #expect(rules[0].pattern == "/static/*")
        #expect(rules[0].headers.count == 2)
        #expect(rules[1].pattern == "/*")
        #expect(rules[1].headers["X-Frame-Options"] == "DENY")
    }
    
    @Test("parseHeaders ignores comments")
    func ignoresComments() throws {
        let content = """
        # This is a comment
        /static/*
          Cache-Control: public
        # Another comment
        """
        
        let rules = try HeadersValidator.parseHeaders(content)
        
        #expect(rules.count == 1)
        #expect(rules[0].pattern == "/static/*")
    }
    
    @Test("parseHeaders ignores empty lines")
    func ignoresEmptyLines() throws {
        let content = """
        /static/*
          Cache-Control: public
        
        
        /*
          X-Frame-Options: DENY
        """
        
        let rules = try HeadersValidator.parseHeaders(content)
        
        #expect(rules.count == 2)
    }
    
    @Test("parseHeaders throws for invalid header format")
    func invalidHeaderFormat() {
        let content = """
        /static/*
          InvalidHeaderWithoutColon
        """
        
        #expect(throws: HeadersError.self) {
            _ = try HeadersValidator.parseHeaders(content)
        }
    }
}

@Suite("HeadersValidator Production Rules Tests")
struct ProductionRulesTests {
    
    @Test("validate requires X-Frame-Options in prod")
    func requiresXFrameOptions() throws {
        let content = """
        /*
          X-Content-Type-Options: nosniff
          Referrer-Policy: strict-origin-when-cross-origin
        """
        
        let result = try HeadersValidator.validate(content, environment: .prod)
        
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "MISSING_HEADER" && $0.message.contains("X-Frame-Options") })
    }
    
    @Test("validate requires X-Content-Type-Options in prod")
    func requiresXContentTypeOptions() throws {
        let content = """
        /*
          X-Frame-Options: DENY
          Referrer-Policy: strict-origin-when-cross-origin
        """
        
        let result = try HeadersValidator.validate(content, environment: .prod)
        
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "MISSING_HEADER" && $0.message.contains("X-Content-Type-Options") })
    }
    
    @Test("validate requires Referrer-Policy in prod")
    func requiresReferrerPolicy() throws {
        let content = """
        /*
          X-Frame-Options: DENY
          X-Content-Type-Options: nosniff
        """
        
        let result = try HeadersValidator.validate(content, environment: .prod)
        
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "MISSING_HEADER" && $0.message.contains("Referrer-Policy") })
    }
    
    @Test("validate passes with all required prod headers")
    func validProdHeaders() throws {
        let content = """
        /*
          X-Frame-Options: DENY
          X-Content-Type-Options: nosniff
          Referrer-Policy: strict-origin-when-cross-origin
        """
        
        let result = try HeadersValidator.validate(content, environment: .prod)
        
        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
    }
}

@Suite("HeadersValidator Dev Environment Tests")
struct DevEnvironmentTests {
    
    @Test("validate dev does not require security headers")
    func devNoRequiredHeaders() throws {
        let content = """
        /*
          Cache-Control: no-store
        """
        
        let result = try HeadersValidator.validate(content, environment: .dev)
        
        #expect(result.isValid == true)
    }
    
    @Test("validate dev warns about missing security headers")
    func devWarnsAboutMissingHeaders() throws {
        let content = """
        /*
          Cache-Control: no-store
        """
        
        let result = try HeadersValidator.validate(content, environment: .dev)
        
        #expect(result.isValid == true)
        #expect(result.warnings.count > 0)
    }
}

@Suite("HeadersRule Tests")
struct HeadersRuleTests {
    
    @Test("HeadersRule stores pattern and headers")
    func basicRule() {
        let rule = HeadersRule(
            pattern: "/*",
            headers: ["X-Frame-Options": "DENY", "Cache-Control": "no-store"],
            lineNumber: 5
        )
        
        #expect(rule.pattern == "/*")
        #expect(rule.headers.count == 2)
        #expect(rule.lineNumber == 5)
    }
    
    @Test("HeadersRule hasHeader checks for header presence")
    func hasHeader() {
        let rule = HeadersRule(
            pattern: "/*",
            headers: ["X-Frame-Options": "DENY"],
            lineNumber: 1
        )
        
        #expect(rule.hasHeader("X-Frame-Options") == true)
        #expect(rule.hasHeader("X-Content-Type-Options") == false)
    }
}

@Suite("HeadersEnvironment Tests")
struct HeadersEnvironmentTests {
    
    @Test("HeadersEnvironment has prod and dev cases")
    func allCases() {
        let environments = HeadersEnvironment.allCases
        
        #expect(environments.count == 2)
        #expect(environments.contains(.prod))
        #expect(environments.contains(.dev))
    }
    
    @Test("HeadersEnvironment raw values match expected")
    func rawValues() {
        #expect(HeadersEnvironment.prod.rawValue == "prod")
        #expect(HeadersEnvironment.dev.rawValue == "dev")
    }
}
