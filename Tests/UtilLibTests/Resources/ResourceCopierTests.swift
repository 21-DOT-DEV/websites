//
//  ResourceCopierTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import UtilLib

struct ResourceCopierTests {
    
    // MARK: - shouldExclude Tests
    
    @Test("shouldExclude returns true for exact match")
    func testExactMatch() {
        let patterns = [".DS_Store", "blog", "static"]
        
        #expect(ResourceCopier.shouldExclude(".DS_Store", patterns: patterns))
        #expect(ResourceCopier.shouldExclude("blog", patterns: patterns))
        #expect(ResourceCopier.shouldExclude("static", patterns: patterns))
    }
    
    @Test("shouldExclude returns true for suffix match")
    func testSuffixMatch() {
        let patterns = [".input.css", ".base.css", ".cjs"]
        
        #expect(ResourceCopier.shouldExclude("style.input.css", patterns: patterns))
        #expect(ResourceCopier.shouldExclude("style.base.css", patterns: patterns))
        #expect(ResourceCopier.shouldExclude("tailwind.config.cjs", patterns: patterns))
    }
    
    @Test("shouldExclude returns false for non-matching files")
    func testNonMatching() {
        let patterns = [".DS_Store", ".input.css", "blog"]
        
        #expect(!ResourceCopier.shouldExclude("robots.txt", patterns: patterns))
        #expect(!ResourceCopier.shouldExclude("llms.txt", patterns: patterns))
        #expect(!ResourceCopier.shouldExclude("style.css", patterns: patterns))
        #expect(!ResourceCopier.shouldExclude("image.svg", patterns: patterns))
    }
    
    @Test("shouldExclude handles empty patterns array")
    func testEmptyPatterns() {
        #expect(!ResourceCopier.shouldExclude("anything.txt", patterns: []))
        #expect(!ResourceCopier.shouldExclude(".DS_Store", patterns: []))
    }
    
    @Test("shouldExclude is case-sensitive")
    func testCaseSensitivity() {
        let patterns = [".DS_Store", "Blog"]
        
        #expect(ResourceCopier.shouldExclude(".DS_Store", patterns: patterns))
        #expect(!ResourceCopier.shouldExclude(".ds_store", patterns: patterns))
        #expect(ResourceCopier.shouldExclude("Blog", patterns: patterns))
        #expect(!ResourceCopier.shouldExclude("blog", patterns: patterns))
    }
    
    // MARK: - copyResources Tests
    
    @Test("copyResources copies files from source to destination")
    func testCopyFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-test-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("source")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Create source directory with test files
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try "content1".write(to: sourceDir.appendingPathComponent("file1.txt"), atomically: true, encoding: .utf8)
        try "content2".write(to: sourceDir.appendingPathComponent("file2.txt"), atomically: true, encoding: .utf8)
        
        // Copy resources
        try ResourceCopier.copyResources(from: sourceDir, to: destDir, excludePatterns: [])
        
        // Verify files were copied
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("file1.txt").path))
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("file2.txt").path))
        
        // Verify content
        let copied1 = try String(contentsOf: destDir.appendingPathComponent("file1.txt"), encoding: .utf8)
        let copied2 = try String(contentsOf: destDir.appendingPathComponent("file2.txt"), encoding: .utf8)
        #expect(copied1 == "content1")
        #expect(copied2 == "content2")
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("copyResources excludes files matching patterns")
    func testExcludeFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-exclude-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("source")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Create source directory with test files
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try "keep".write(to: sourceDir.appendingPathComponent("keep.txt"), atomically: true, encoding: .utf8)
        try "exclude".write(to: sourceDir.appendingPathComponent("style.input.css"), atomically: true, encoding: .utf8)
        try "dsstore".write(to: sourceDir.appendingPathComponent(".DS_Store"), atomically: true, encoding: .utf8)
        
        // Copy resources with exclusions
        try ResourceCopier.copyResources(
            from: sourceDir,
            to: destDir,
            excludePatterns: [".DS_Store", ".input.css"]
        )
        
        // Verify only non-excluded files were copied
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("keep.txt").path))
        #expect(!FileManager.default.fileExists(atPath: destDir.appendingPathComponent("style.input.css").path))
        #expect(!FileManager.default.fileExists(atPath: destDir.appendingPathComponent(".DS_Store").path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("copyResources handles nested directories recursively")
    func testRecursiveCopy() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-recursive-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("source")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Create nested source structure
        let nestedDir = sourceDir.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
        try "root".write(to: sourceDir.appendingPathComponent("root.txt"), atomically: true, encoding: .utf8)
        try "nested".write(to: nestedDir.appendingPathComponent("nested.txt"), atomically: true, encoding: .utf8)
        
        // Copy resources
        try ResourceCopier.copyResources(from: sourceDir, to: destDir, excludePatterns: [])
        
        // Verify nested structure was copied
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("root.txt").path))
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("nested/nested.txt").path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("copyResources excludes entire directories")
    func testExcludeDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-dir-exclude-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("source")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Create source with a directory to exclude
        let blogDir = sourceDir.appendingPathComponent("blog")
        try FileManager.default.createDirectory(at: blogDir, withIntermediateDirectories: true)
        try "root".write(to: sourceDir.appendingPathComponent("root.txt"), atomically: true, encoding: .utf8)
        try "post".write(to: blogDir.appendingPathComponent("post.md"), atomically: true, encoding: .utf8)
        
        // Copy resources excluding blog directory
        try ResourceCopier.copyResources(
            from: sourceDir,
            to: destDir,
            excludePatterns: ["blog"]
        )
        
        // Verify blog directory was excluded
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("root.txt").path))
        #expect(!FileManager.default.fileExists(atPath: destDir.appendingPathComponent("blog").path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("copyResources calls logger for each copied file")
    func testLoggerCallback() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-logger-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("source")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Create source files
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try "a".write(to: sourceDir.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try "b".write(to: sourceDir.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)
        
        // Track logged files
        var loggedFiles: [String] = []
        
        // Copy with logger
        try ResourceCopier.copyResources(
            from: sourceDir,
            to: destDir,
            excludePatterns: []
        ) { path in
            loggedFiles.append(path)
        }
        
        // Verify logger was called for each file
        #expect(loggedFiles.count == 2)
        #expect(loggedFiles.contains("a.txt"))
        #expect(loggedFiles.contains("b.txt"))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    @Test("copyResources handles non-existent source gracefully")
    func testNonExistentSource() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-nonexistent-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("nonexistent")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Should not throw for non-existent source
        try ResourceCopier.copyResources(from: sourceDir, to: destDir, excludePatterns: [])
        
        // Destination should not be created
        #expect(!FileManager.default.fileExists(atPath: destDir.path))
    }
    
    @Test("copyResources overwrites existing files (idempotency)")
    func testIdempotency() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("resource-copier-idempotent-\(UUID())")
        let sourceDir = tempDir.appendingPathComponent("source")
        let destDir = tempDir.appendingPathComponent("dest")
        
        // Create source and destination
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        
        // Create source file
        try "new content".write(to: sourceDir.appendingPathComponent("file.txt"), atomically: true, encoding: .utf8)
        
        // Create existing destination file with different content
        try "old content".write(to: destDir.appendingPathComponent("file.txt"), atomically: true, encoding: .utf8)
        
        // Copy resources
        try ResourceCopier.copyResources(from: sourceDir, to: destDir, excludePatterns: [])
        
        // Verify file was overwritten
        let content = try String(contentsOf: destDir.appendingPathComponent("file.txt"), encoding: .utf8)
        #expect(content == "new content")
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
}
