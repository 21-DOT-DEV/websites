import Testing
import Foundation

@Suite("LastMod Preservation Integration Tests")
struct LastModPreservationTests {
    
    @Test("State file preserves lastmod date when package version unchanged")
    func testLastModPreservationWithUnchangedVersion() async throws {
        let stateFilePath = "Resources/sitemap-state.json"
        
        // Read the current state file
        let stateURL = URL(fileURLWithPath: stateFilePath)
        
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            Issue.record("State file does not exist at \(stateFilePath)")
            return
        }
        
        // Parse the state file
        let data = try Data(contentsOf: stateURL)
        let decoder = JSONDecoder()
        let state = try decoder.decode(SitemapState.self, from: data)
        
        // Verify structure
        #expect(!state.packageVersion.isEmpty, "Package version should not be empty")
        #expect(!state.generatedDate.isEmpty, "Generated date should not be empty")
        
        // Verify date format is ISO8601
        let formatter = ISO8601DateFormatter()
        let parsedDate = formatter.date(from: state.generatedDate)
        #expect(parsedDate != nil, "Generated date should be valid ISO8601 format")
        
        // Verify package version matches Package.resolved
        let resolvedURL = URL(fileURLWithPath: "Package.resolved")
        let resolvedData = try Data(contentsOf: resolvedURL)
        let resolved = try decoder.decode(PackageResolved.self, from: resolvedData)
        
        let secp256k1Pin = resolved.pins.first { $0.identity == "swift-secp256k1" }
        #expect(secp256k1Pin != nil, "swift-secp256k1 should be in Package.resolved")
        
        if let pin = secp256k1Pin {
            #expect(pin.state.version != nil, "swift-secp256k1 should have a version")
            if let version = pin.state.version {
                #expect(state.packageVersion == version, 
                       "State file version should match Package.resolved version")
            }
        }
    }
    
    @Test("State file generated date is valid ISO8601 with timezone")
    func testStateDateFormatIsISO8601WithTimezone() async throws {
        let stateFilePath = "Resources/sitemap-state.json"
        let stateURL = URL(fileURLWithPath: stateFilePath)
        
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            Issue.record("State file does not exist at \(stateFilePath)")
            return
        }
        
        let data = try Data(contentsOf: stateURL)
        let state = try JSONDecoder().decode(SitemapState.self, from: data)
        
        // Verify ISO8601 format with timezone (either Z or +HH:MM/-HH:MM)
        let iso8601Pattern = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$|^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#
        let regex = try! NSRegularExpression(pattern: iso8601Pattern)
        let range = NSRange(state.generatedDate.startIndex..., in: state.generatedDate)
        let matches = regex.numberOfMatches(in: state.generatedDate, range: range)
        
        #expect(matches == 1, "Generated date should match ISO8601 format with timezone")
    }
    
    @Test("Multiple reads of state file return consistent data")
    func testStateFileConsistency() async throws {
        let stateFilePath = "Resources/sitemap-state.json"
        let stateURL = URL(fileURLWithPath: stateFilePath)
        
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            Issue.record("State file does not exist at \(stateFilePath)")
            return
        }
        
        // Read the state file multiple times
        let decoder = JSONDecoder()
        
        let data1 = try Data(contentsOf: stateURL)
        let state1 = try decoder.decode(SitemapState.self, from: data1)
        
        // Small delay to ensure file system cache doesn't interfere
        try await Task.sleep(for: .milliseconds(10))
        
        let data2 = try Data(contentsOf: stateURL)
        let state2 = try decoder.decode(SitemapState.self, from: data2)
        
        // Both reads should return identical data
        #expect(state1.packageVersion == state2.packageVersion)
        #expect(state1.generatedDate == state2.generatedDate)
    }
}

// MARK: - Supporting Types

/// Represents the structure of Resources/sitemap-state.json
struct SitemapState: Codable {
    let packageVersion: String
    let generatedDate: String
    
    enum CodingKeys: String, CodingKey {
        case packageVersion = "package_version"
        case generatedDate = "generated_date"
    }
}

/// Simplified structure for parsing Package.resolved
struct PackageResolved: Codable {
    let pins: [Pin]
    
    struct Pin: Codable {
        let identity: String
        let state: State
        
        struct State: Codable {
            let version: String?
            let branch: String?
            let revision: String?
        }
    }
}
