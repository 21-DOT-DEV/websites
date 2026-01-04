import Testing
import Foundation

@Suite("Package Structure Validation Tests")
struct PackageStructureValidationTests {
    
    // T012: Verify UtilLib target exists in Package.swift
    @Test("Package.swift defines UtilLib library target")
    func utilLibTargetExists() async throws {
        let packageSwiftPath = FileManager.default.currentDirectoryPath + "/Package.swift"
        let content = try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
        
        #expect(content.contains("name: \"UtilLib\""))
        #expect(content.contains(".target(") && content.contains("name: \"UtilLib\""))
    }
    
    // T013: Verify util depends on UtilLib
    @Test("util executable depends on UtilLib")
    func utilDependsOnUtilLib() async throws {
        let packageSwiftPath = FileManager.default.currentDirectoryPath + "/Package.swift"
        let content = try String(contentsOfFile: packageSwiftPath, encoding: .utf8)
        
        // Check that util target exists
        #expect(content.contains("name: \"util\""))
        
        // Check that util depends on UtilLib (not Utilities)
        #expect(content.contains(".target(name: \"UtilLib\")"))
        
        // Verify it's in the util target's dependencies
        let utilTargetPattern = #/.executableTarget\s*\(\s*name:\s*"util"[\s\S]*?dependencies:\s*\[[\s\S]*?\.target\(name:\s*"UtilLib"\)/#
        #expect(content.contains(utilTargetPattern))
    }
    
    // T014: Verify UtilLibTests uses @testable import UtilLib
    @Test("UtilLibTests uses @testable import UtilLib")
    func utilLibTestsImportCorrect() async throws {
        let testDir = FileManager.default.currentDirectoryPath + "/Tests/UtilLibTests"
        let fileManager = FileManager.default
        
        // Check directory exists
        var isDirectory: ObjCBool = false
        #expect(fileManager.fileExists(atPath: testDir, isDirectory: &isDirectory) && isDirectory.boolValue)
        
        // Check at least one test file has @testable import UtilLib
        let testFiles = try fileManager.contentsOfDirectory(atPath: testDir)
            .filter { $0.hasSuffix(".swift") }
        
        #expect(!testFiles.isEmpty)
        
        var foundCorrectImport = false
        for file in testFiles {
            let filePath = testDir + "/" + file
            if let content = try? String(contentsOfFile: filePath, encoding: .utf8),
               content.contains("@testable import UtilLib") {
                foundCorrectImport = true
                break
            }
        }
        
        #expect(foundCorrectImport, "At least one test file should have @testable import UtilLib")
    }
    
    // T015: Verify all consumers import UtilLib
    @Test("All consumer targets import UtilLib (not Utilities)")
    func consumersImportUtilLib() async throws {
        let consumers = [
            "Sources/21-dev",
            "Sources/DesignSystem",
            "Tests/IntegrationTests",
            "Tests/DesignSystemTests"
        ]
        
        let baseDir = FileManager.default.currentDirectoryPath
        let fileManager = FileManager.default
        
        for consumer in consumers {
            let consumerPath = baseDir + "/" + consumer
            
            guard fileManager.fileExists(atPath: consumerPath) else {
                continue // Skip if directory doesn't exist
            }
            
            // Recursively check all Swift files in this directory
            if let enumerator = fileManager.enumerator(atPath: consumerPath) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".swift") {
                        let filePath = consumerPath + "/" + file
                        if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                            // If file imports Utilities, it should import UtilLib instead
                            if content.contains("import Utilities") {
                                #expect(content.contains("import UtilLib"), 
                                       "File \(consumer)/\(file) should import UtilLib, not Utilities")
                            }
                        }
                    }
                }
            }
        }
    }
}
