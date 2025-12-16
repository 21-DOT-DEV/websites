//
//  SitemapGenerator.swift
//  Utilities
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Subprocess

/// Generates sitemap.xml files for configured sites.
public enum SitemapGenerator {
    
    // MARK: - URL Discovery
    
    /// Discovers all HTML files in a directory recursively.
    /// - Parameter directory: The directory path to scan
    /// - Returns: Array of file paths relative to the directory
    /// - Throws: `SitemapError.discoveryFailed` if directory doesn't exist or can't be read
    public static func discoverHTMLFiles(in directory: String) throws -> [String] {
        try discoverFiles(in: directory, withExtension: "html")
    }
    
    /// Discovers all Markdown files in a directory recursively.
    /// - Parameter directory: The directory path to scan
    /// - Returns: Array of file paths relative to the directory
    /// - Throws: `SitemapError.discoveryFailed` if directory doesn't exist or can't be read
    public static func discoverMarkdownFiles(in directory: String) throws -> [String] {
        try discoverFiles(in: directory, withExtension: "md")
    }
    
    private static func discoverFiles(in directory: String, withExtension ext: String) throws -> [String] {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: directory) else {
            throw SitemapError.discoveryFailed("Directory does not exist: \(directory)")
        }
        
        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            throw SitemapError.discoveryFailed("Cannot enumerate directory: \(directory)")
        }
        
        var files: [String] = []
        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".\(ext)") {
                files.append(file)
            }
        }
        
        return files.sorted()
    }
    
    // MARK: - Path to URL Conversion
    
    /// Converts a file path to a sitemap URL.
    /// - Parameters:
    ///   - filePath: The full file path
    ///   - baseURL: The base URL for the site (e.g., "https://21.dev")
    ///   - outputDirectory: The output directory path to strip from the file path
    /// - Returns: The full URL for the sitemap
    public static func pathToURL(filePath: String, baseURL: String, outputDirectory: String) -> String {
        // Remove the output directory prefix
        var relativePath = filePath
        if relativePath.hasPrefix(outputDirectory) {
            relativePath = String(relativePath.dropFirst(outputDirectory.count))
        }
        
        // Ensure path starts with /
        if !relativePath.hasPrefix("/") {
            relativePath = "/" + relativePath
        }
        
        // Convert index.html to directory URL
        if relativePath.hasSuffix("/index.html") {
            relativePath = String(relativePath.dropLast("index.html".count))
        }
        
        // Handle root index.html
        if relativePath == "/index.html" {
            relativePath = "/"
        }
        
        return baseURL + relativePath
    }
    
    // MARK: - Lastmod Strategies
    
    /// Gets the last modification date for a file using git commit history.
    /// - Parameter filePath: Path to the file
    /// - Returns: ISO8601 formatted date string
    public static func getGitLastmod(for filePath: String) async -> String {
        do {
            let result = try await Subprocess.run(
                .name("git"),
                arguments: .init([
                    "log",
                    "-1",
                    "--format=%cI",
                    "--",
                    filePath
                ]),
                output: .string(limit: 4096),
                error: .string(limit: 1024)
            )
            
            guard case .exited(0) = result.terminationStatus else {
                return currentDateString()
            }
            
            guard let dateString = result.standardOutput?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !dateString.isEmpty else {
                return currentDateString()
            }
            
            return dateString
            
        } catch {
            return currentDateString()
        }
    }
    
    /// Returns the current date as an ISO8601 string.
    public static func currentDateString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
    }
    
    // MARK: - Sitemap Generation
    
    /// Generates a complete sitemap.xml for the given configuration.
    /// - Parameter config: The site configuration
    /// - Returns: The complete sitemap XML as a string
    /// - Throws: `SitemapError` if generation fails
    public static func generate(for config: SiteConfiguration) async throws -> String {
        // Discover files based on strategy
        let files: [String]
        let directory: String
        
        switch config.urlDiscoveryStrategy {
        case .htmlFiles(let dir):
            directory = dir
            files = try discoverHTMLFiles(in: dir)
        case .markdownFiles(let dir):
            directory = dir
            files = try discoverMarkdownFiles(in: dir)
        case .sitemapDictionary:
            // This strategy is handled at the call site (Slipstream integration)
            throw SitemapError.discoveryFailed("sitemapDictionary strategy must be handled by caller")
        }
        
        // Generate entries
        var entries: [SitemapEntry] = []
        
        for file in files {
            let fullPath = directory.hasSuffix("/") ? directory + file : directory + "/" + file
            let url = pathToURL(filePath: fullPath, baseURL: config.baseURL, outputDirectory: config.outputDirectory)
            
            let lastmod: Date
            switch config.lastmodStrategy {
            case .gitCommitDate:
                let dateString = await getGitLastmod(for: fullPath)
                lastmod = ISO8601DateFormatter().date(from: dateString) ?? Date()
            case .packageVersionState:
                // This would be read from state file - for now use current date
                lastmod = Date()
            case .currentDate:
                lastmod = Date()
            }
            
            if let entry = try? SitemapEntry(url: url, lastmod: lastmod) {
                entries.append(entry)
            }
        }
        
        // Build sitemap XML
        var xml = sitemapXMLHeader()
        for entry in entries {
            xml += entry.toXML()
        }
        xml += sitemapXMLFooter()
        
        return xml
    }
    
    /// Writes a sitemap to the specified output path.
    /// - Parameters:
    ///   - sitemap: The sitemap XML content
    ///   - path: The output file path
    /// - Throws: `SitemapError.writeFailed` if writing fails
    public static func write(_ sitemap: String, to path: String) throws {
        do {
            try sitemap.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw SitemapError.writeFailed(error.localizedDescription)
        }
    }
}
