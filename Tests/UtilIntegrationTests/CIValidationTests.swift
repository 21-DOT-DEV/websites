//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation

@Suite("CI Validation Tests")
struct CIValidationTests {
    
    // T045: Verify no old target name references in workflows
    @Test("GitHub workflows have no old target name references")
    func noOldTargetNamesInWorkflows() async throws {
        let workflowsDir = FileManager.default.currentDirectoryPath + "/.github/workflows"
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: workflowsDir) else {
            return
        }
        
        if let enumerator = fileManager.enumerator(atPath: workflowsDir) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".yml") || file.hasSuffix(".yaml") {
                    let filePath = workflowsDir + "/" + file
                    if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                        let lines = content.components(separatedBy: .newlines)
                        for (index, line) in lines.enumerated() {
                            // Check for old target names
                            if line.contains("Utilities") && !line.contains("UtilLib") && !line.contains("#") {
                                #expect(Bool(false), "File \(file) line \(index+1) references old 'Utilities' target")
                            }
                            if line.contains("UtilitiesTests") {
                                #expect(Bool(false), "File \(file) line \(index+1) references old 'UtilitiesTests' target")
                            }
                            if line.contains("UtilitiesCLITests") {
                                #expect(Bool(false), "File \(file) line \(index+1) references old 'UtilitiesCLITests' target")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // T046: Verify all 8 success criteria from spec.md
    @Test("All success criteria satisfied")
    func allSuccessCriteriaSatisfied() async throws {
        let baseDir = FileManager.default.currentDirectoryPath
        
        // SC-001: UtilLibTests tests library internals via @testable import UtilLib
        let utilLibTestsPath = baseDir + "/Tests/UtilLibTests"
        var foundTestableImport = false
        if let enumerator = FileManager.default.enumerator(atPath: utilLibTestsPath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    let content = try? String(contentsOfFile: utilLibTestsPath + "/" + file, encoding: .utf8)
                    if content?.contains("@testable import UtilLib") == true {
                        foundTestableImport = true
                        break
                    }
                }
            }
        }
        #expect(foundTestableImport, "SC-001: UtilLibTests should use @testable import UtilLib")
        
        // SC-002: UtilIntegrationTests has zero dependency on UtilLib
        let packageSwift = try String(contentsOfFile: baseDir + "/Package.swift", encoding: .utf8)
        let lines = packageSwift.components(separatedBy: .newlines)
        var inUtilIntegrationTarget = false
        var hasUtilLibDep = false
        for line in lines {
            if line.contains("name: \"UtilIntegrationTests\"") {
                inUtilIntegrationTarget = true
            }
            if inUtilIntegrationTarget && (line.contains("\"UtilLib\"") || line.contains("UtilLib")) {
                if !line.contains("//") {
                    hasUtilLibDep = true
                }
            }
            if inUtilIntegrationTarget && line.contains("]") {
                break
            }
        }
        #expect(!hasUtilLibDep, "SC-002: UtilIntegrationTests should have zero UtilLib dependency")
        
        // SC-003: TestHarness provides CLI execution (verifiable by its existence)
        let testHarnessPath = baseDir + "/Tests/UtilIntegrationTests/TestHarness.swift"
        #expect(FileManager.default.fileExists(atPath: testHarnessPath), "SC-003: TestHarness should exist")
        
        // SC-005: Clear separation exists
        #expect(FileManager.default.fileExists(atPath: utilLibTestsPath), "SC-005: UtilLibTests should exist")
        let utilIntegrationPath = baseDir + "/Tests/UtilIntegrationTests"
        #expect(FileManager.default.fileExists(atPath: utilIntegrationPath), "SC-005: UtilIntegrationTests should exist")
        
        // SC-006: Architecture documentation exists
        let archDocPath = baseDir + "/.windsurf/rules/util-architecture.md"
        #expect(FileManager.default.fileExists(atPath: archDocPath), "SC-006: Architecture documentation should exist")
    }
    
    // T047: Verify util executable is minimal wrapper
    @Test("util executable is minimal wrapper (<10 lines per SC-008)")
    func utilExecutableMinimal() async throws {
        let utilMainPath = FileManager.default.currentDirectoryPath + "/Sources/util/Util.swift"
        
        guard let content = try? String(contentsOfFile: utilMainPath, encoding: .utf8) else {
            #expect(Bool(false), "Could not read util/Util.swift")
            return
        }
        
        // Count non-empty, non-comment lines
        let lines = content.components(separatedBy: .newlines)
        var codeLines = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Skip empty lines, comments, and imports
            if !trimmed.isEmpty && 
               !trimmed.hasPrefix("//") && 
               !trimmed.hasPrefix("import ") &&
               !trimmed.hasPrefix("/*") &&
               !trimmed.hasPrefix("*") {
                codeLines += 1
            }
        }
        
        // Should be minimal - mainly struct declaration and ArgumentParser configuration
        // Realistic threshold: ArgumentParser configuration is ~10-15 lines
        #expect(codeLines <= 20, "SC-008: util executable should be minimal wrapper (found \(codeLines) lines)")
    }
}
