//
//  SitemapValidator.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Validates sitemap XML and URLs.
public enum SitemapValidator {
    
    // MARK: - URL Validation
    
    /// Validates a single URL for sitemap inclusion.
    /// - Parameter url: The URL to validate
    /// - Returns: Validation result
    public static func validateURL(_ url: String) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Check length
        if url.count > 2048 {
            errors.append(ValidationError(
                code: "URL_TOO_LONG",
                message: "URL exceeds 2048 character limit (\(url.count) chars)",
                location: url.prefix(50) + "..."
            ))
            return ValidationResult.failure(errors)
        }
        
        // Use existing validation function
        if !isValidSitemapURL(url) {
            errors.append(ValidationError(
                code: "INVALID_URL",
                message: "Invalid sitemap URL: must be absolute HTTP/HTTPS URL",
                location: url
            ))
        }
        
        if errors.isEmpty {
            return ValidationResult.success()
        }
        return ValidationResult.failure(errors)
    }
    
    // MARK: - XML Validation
    
    /// Validates sitemap XML content.
    /// - Parameter xml: The XML string to validate
    /// - Returns: Validation result with errors for any issues found
    public static func validateXML(_ xml: String) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []
        
        // Check XML declaration
        if !xml.contains("<?xml") {
            errors.append(ValidationError(
                code: "MISSING_XML_DECLARATION",
                message: "Missing XML declaration (<?xml version=\"1.0\"?>)"
            ))
        }
        
        // Check urlset element
        if !xml.contains("<urlset") {
            errors.append(ValidationError(
                code: "MISSING_URLSET",
                message: "Missing <urlset> root element"
            ))
        }
        
        // Check namespace (warning only)
        if !xml.contains("xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"") {
            warnings.append("Missing sitemap namespace declaration")
        }
        
        // Extract and validate all URLs
        let urlPattern = "<loc>([^<]+)</loc>"
        if let regex = try? NSRegularExpression(pattern: urlPattern, options: []) {
            let range = NSRange(xml.startIndex..., in: xml)
            let matches = regex.matches(in: xml, options: [], range: range)
            
            for match in matches {
                if let urlRange = Range(match.range(at: 1), in: xml) {
                    let url = String(xml[urlRange])
                    let urlResult = validateURL(url)
                    if !urlResult.isValid {
                        errors.append(contentsOf: urlResult.errors)
                    }
                }
            }
        }
        
        if errors.isEmpty {
            return ValidationResult.success(warnings: warnings)
        }
        return ValidationResult(isValid: false, errors: errors, warnings: warnings)
    }
    
    // MARK: - File Validation
    
    /// Validates a sitemap file.
    /// - Parameter path: Path to the sitemap file
    /// - Returns: Validation result
    public static func validateFile(at path: String) -> ValidationResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return ValidationResult.failure([
                ValidationError(
                    code: "FILE_NOT_FOUND",
                    message: "Sitemap file not found",
                    location: path
                )
            ])
        }
        
        do {
            let xml = try String(contentsOfFile: path, encoding: .utf8)
            return validateXML(xml)
        } catch {
            return ValidationResult.failure([
                ValidationError(
                    code: "READ_ERROR",
                    message: "Failed to read sitemap file: \(error.localizedDescription)",
                    location: path
                )
            ])
        }
    }
    
    /// Validates a generated sitemap for a site configuration.
    /// - Parameter config: The site configuration
    /// - Returns: Validation result
    public static func validate(for config: SiteConfiguration) -> ValidationResult {
        let sitemapPath = "\(config.outputDirectory)/sitemap.xml"
        return validateFile(at: sitemapPath)
    }
}
