//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation

@Suite("Integration Test Structure Validation Tests")
struct IntegrationTestStructureValidationTests {
    
    // T027: Verify UtilIntegrationTests has zero UtilLib dependency
    @Test("UtilIntegrationTests has no UtilLib dependency in Package.swift")
    func utilIntegrationTestsNoUtilLibDependency() async throws {
        let packageSwiftPath = FileManager.default.currentDirectoryPath + "/Package.swift"
        let content = try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
        
        // Find the UtilIntegrationTests target
        let lines = content.components(separatedBy: .newlines)
        var inUtilIntegrationTarget = false
        var foundDependencies = false
        var hasUtilLibDependency = false
        
        for line in lines {
            if line.contains("name: \"UtilIntegrationTests\"") {
                inUtilIntegrationTarget = true
            }
            
            if inUtilIntegrationTarget && line.contains("dependencies:") {
                foundDependencies = true
            }
            
            if inUtilIntegrationTarget && foundDependencies {
                if line.contains("\"UtilLib\"") || line.contains("UtilLib") {
                    hasUtilLibDependency = true
                }
                
                // End of dependencies array
                if line.contains("]") && foundDependencies {
                    break
                }
            }
        }
        
        #expect(!hasUtilLibDependency, "UtilIntegrationTests should not depend on UtilLib")
    }
    
    // T028: Verify UtilIntegrationTests has zero util dependency
    @Test("UtilIntegrationTests has no util executable dependency in Package.swift")
    func utilIntegrationTestsNoUtilDependency() async throws {
        let packageSwiftPath = FileManager.default.currentDirectoryPath + "/Package.swift"
        let content = try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
        
        // Find the UtilIntegrationTests target
        let lines = content.components(separatedBy: .newlines)
        var inUtilIntegrationTarget = false
        var foundDependencies = false
        var hasUtilDependency = false
        
        for line in lines {
            if line.contains("name: \"UtilIntegrationTests\"") {
                inUtilIntegrationTarget = true
            }
            
            if inUtilIntegrationTarget && line.contains("dependencies:") {
                foundDependencies = true
            }
            
            if inUtilIntegrationTarget && foundDependencies {
                if line.contains("\"util\"") && !line.contains("Util") {
                    hasUtilDependency = true
                }
                
                // End of dependencies array
                if line.contains("]") && foundDependencies {
                    break
                }
            }
        }
        
        #expect(!hasUtilDependency, "UtilIntegrationTests should not depend on util executable")
    }
    
    // T029: Verify no import UtilLib statements
    @Test("UtilIntegrationTests has no import UtilLib statements")
    func utilIntegrationTestsNoUtilLibImports() async throws {
        let testDir = FileManager.default.currentDirectoryPath + "/Tests/UtilIntegrationTests"
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: testDir) else {
            return
        }
        
        if let enumerator = fileManager.enumerator(atPath: testDir) {
            while let file = enumerator.nextObject() as? String {
                // Skip validation test files themselves
                if file.hasSuffix(".swift") && !file.contains("ValidationTests") {
                    let filePath = testDir + "/" + file
                    if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                        let lines = content.components(separatedBy: .newlines)
                        for (index, line) in lines.enumerated() {
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            if trimmed.hasPrefix("import UtilLib") || trimmed.hasPrefix("@testable import UtilLib") {
                                #expect(Bool(false), "File \(file) line \(index+1) should not import UtilLib")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // T030: Verify no import util statements
    @Test("UtilIntegrationTests has no import util statements")
    func utilIntegrationTestsNoUtilImports() async throws {
        let testDir = FileManager.default.currentDirectoryPath + "/Tests/UtilIntegrationTests"
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: testDir) else {
            return
        }
        
        if let enumerator = fileManager.enumerator(atPath: testDir) {
            while let file = enumerator.nextObject() as? String {
                // Skip validation test files themselves
                if file.hasSuffix(".swift") && !file.contains("ValidationTests") {
                    let filePath = testDir + "/" + file
                    if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                        let lines = content.components(separatedBy: .newlines)
                        for (index, line) in lines.enumerated() {
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            if trimmed == "import util" {
                                #expect(Bool(false), "File \(file) line \(index+1) should not import util executable")
                            }
                        }
                    }
                }
            }
        }
    }
}
