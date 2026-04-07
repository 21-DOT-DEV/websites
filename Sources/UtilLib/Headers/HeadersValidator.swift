//
//  HeadersValidator.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Environment for headers validation.
public enum HeadersEnvironment: String, CaseIterable, Sendable {
    case prod
    case dev
}

/// Errors that can occur during headers validation.
public enum HeadersError: Error, LocalizedError {
    case fileNotFound(String)
    case parseError(String, Int)
    case invalidFormat(String, Int)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Headers file not found: \(path)"
        case .parseError(let reason, let line):
            return "Parse error at line \(line): \(reason)"
        case .invalidFormat(let reason, let line):
            return "Invalid format at line \(line): \(reason)"
        }
    }
}

/// Represents a single headers rule (path pattern + headers).
public struct HeadersRule: Sendable {
    /// The path pattern (e.g., "/*", "/static/*")
    public let pattern: String
    
    /// Headers for this pattern (name -> value)
    public let headers: [String: String]
    
    /// Line number where this rule starts
    public let lineNumber: Int
    
    /// Suppression directives from `# cfpages-ignore:` comments above this rule
    public let suppressions: Set<String>
    
    public init(pattern: String, headers: [String: String], lineNumber: Int, suppressions: Set<String> = []) {
        self.pattern = pattern
        self.headers = headers
        self.lineNumber = lineNumber
        self.suppressions = suppressions
    }
    
    /// Checks if this rule has a specific header.
    public func hasHeader(_ name: String) -> Bool {
        headers.keys.contains { $0.lowercased() == name.lowercased() }
    }
    
    /// Checks if a specific warning is suppressed for this rule.
    public func isSuppressed(_ directive: String) -> Bool {
        suppressions.contains(directive)
    }
}

/// Validates Cloudflare _headers files for correctness.
public enum HeadersValidator {
    
    /// Required headers for production environment.
    public static let requiredProdHeaders = [
        "X-Frame-Options",
        "X-Content-Type-Options",
        "Referrer-Policy"
    ]
    
    /// Parses a _headers file content into rules.
    /// - Parameter content: The file content
    /// - Returns: Array of parsed header rules
    /// - Throws: `HeadersError` if parsing fails
    public static func parseHeaders(_ content: String) throws -> [HeadersRule] {
        var rules: [HeadersRule] = []
        var currentPattern: String?
        var currentHeaders: [String: String] = [:]
        var currentSuppressions: Set<String> = []
        var patternLineNumber = 0
        
        let lines = content.components(separatedBy: .newlines)
        var pendingSuppressions: Set<String> = []
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines; parse cfpages-ignore directives from comments
            if trimmed.isEmpty {
                continue
            }
            if trimmed.hasPrefix("#") {
                if let range = trimmed.range(of: "cfpages-ignore:") {
                    let directive = trimmed[range.upperBound...]
                        .trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: " ").first ?? ""
                    if !directive.isEmpty {
                        pendingSuppressions.insert(directive)
                    }
                }
                continue
            }
            
            // Check if this is a path pattern (starts with /)
            if trimmed.hasPrefix("/") && !line.hasPrefix(" ") && !line.hasPrefix("\t") {
                // Save previous rule if exists
                if let pattern = currentPattern {
                    rules.append(HeadersRule(
                        pattern: pattern,
                        headers: currentHeaders,
                        lineNumber: patternLineNumber,
                        suppressions: currentSuppressions
                    ))
                }
                
                currentPattern = trimmed
                currentHeaders = [:]
                currentSuppressions = pendingSuppressions
                pendingSuppressions = []
                patternLineNumber = lineNumber
            } else if line.hasPrefix(" ") || line.hasPrefix("\t") {
                // This is a header line (indented)
                guard let colonIndex = trimmed.firstIndex(of: ":") else {
                    throw HeadersError.invalidFormat("Header must contain ':'", lineNumber)
                }
                
                let name = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                
                if name.isEmpty {
                    throw HeadersError.invalidFormat("Header name cannot be empty", lineNumber)
                }
                
                currentHeaders[name] = value
            }
        }
        
        // Save last rule
        if let pattern = currentPattern {
            rules.append(HeadersRule(
                pattern: pattern,
                headers: currentHeaders,
                lineNumber: patternLineNumber,
                suppressions: currentSuppressions
            ))
        }
        
        return rules
    }
    
    /// Validates headers content for the specified environment.
    /// - Parameters:
    ///   - content: The _headers file content
    ///   - environment: The target environment (prod/dev)
    /// - Returns: Validation result with errors and warnings
    public static func validate(_ content: String, environment: HeadersEnvironment) throws -> ValidationResult {
        let rules = try parseHeaders(content)
        
        var errors: [ValidationError] = []
        var warnings: [String] = []
        
        // Find the catch-all rule (/*) for security header checks
        let catchAllRule = rules.first { $0.pattern == "/*" }
        
        if environment == .prod {
            // Check required headers in production
            for requiredHeader in requiredProdHeaders {
                let hasHeader = catchAllRule?.hasHeader(requiredHeader) ?? false
                if !hasHeader {
                    errors.append(ValidationError(
                        code: "MISSING_HEADER",
                        message: "\(requiredHeader) required for prod at /*",
                        location: "/*"
                    ))
                }
            }
        } else {
            // Dev environment - warn about missing security headers
            for requiredHeader in requiredProdHeaders {
                let hasHeader = catchAllRule?.hasHeader(requiredHeader) ?? false
                if !hasHeader {
                    warnings.append("Consider adding \(requiredHeader) for dev environment")
                }
            }
        }
        
        // Warn when a glob pattern sets Content-Type (Cloudflare Pages anti-pattern)
        // Skip patterns suppressed with # cfpages-ignore: glob-content-type
        for rule in rules where !rule.isSuppressed("glob-content-type") {
            if rule.pattern.contains("*") && rule.hasHeader("Content-Type") {
                warnings.append(
                    "Glob pattern '\(rule.pattern)' sets Content-Type — "
                    + "this may serve incorrect content types for non-existent URLs on Cloudflare Pages. "
                    + "Consider using explicit file paths instead, "
                    + "or add '# cfpages-ignore: glob-content-type' above the rule to suppress."
                )
            }
        }
        
        if errors.isEmpty {
            return ValidationResult.success(warnings: warnings)
        } else {
            return ValidationResult(isValid: false, errors: errors, warnings: warnings)
        }
    }
    
    /// Validates a headers file at the specified path.
    /// - Parameters:
    ///   - path: Path to the _headers file
    ///   - environment: The target environment
    /// - Returns: Validation result
    public static func validateFile(at path: String, environment: HeadersEnvironment) throws -> ValidationResult {
        guard FileManager.default.fileExists(atPath: path) else {
            throw HeadersError.fileNotFound(path)
        }
        
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return try validate(content, environment: environment)
    }
    
    /// Returns the default headers file path for a site and environment.
    public static func defaultPath(for site: SiteName, environment: HeadersEnvironment) -> String {
        return "Resources/\(site.rawValue)/_headers.\(environment.rawValue)"
    }
}
