//
//  StateManagerTests.swift
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

@Suite("StateFile Model Tests")
struct StateFileTests {
    
    @Test("StateFile initializes with required fields")
    func basicInitialization() {
        let date = Date()
        let state = StateFile(
            packageVersion: "1.2.3",
            generatedDate: date,
            subdomains: [:]
        )
        
        #expect(state.packageVersion == "1.2.3")
        #expect(state.generatedDate == date)
        #expect(state.subdomains.isEmpty)
    }
    
    @Test("StateFile stores subdomain states")
    func subdomainStates() {
        let date = Date()
        let state = StateFile(
            packageVersion: "1.2.3",
            generatedDate: date,
            subdomains: [
                "docs-21-dev": SubdomainState(lastmod: date),
                "md-21-dev": SubdomainState(lastmod: date)
            ]
        )
        
        #expect(state.subdomains.count == 2)
        #expect(state.subdomains["docs-21-dev"]?.lastmod == date)
    }
    
    @Test("StateFile is Codable with snake_case keys")
    func codableWithSnakeCase() throws {
        let date = ISO8601DateFormatter().date(from: "2025-12-15T12:00:00Z")!
        let state = StateFile(
            packageVersion: "1.2.3",
            generatedDate: date,
            subdomains: ["docs-21-dev": SubdomainState(lastmod: date)]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"package_version\""))
        #expect(json.contains("\"generated_date\""))
        #expect(json.contains("\"1.2.3\""))
    }
    
    @Test("StateFile decodes from JSON")
    func decodesFromJSON() throws {
        let json = """
        {
            "package_version": "0.21.1",
            "generated_date": "2025-12-15T12:00:00Z",
            "subdomains": {
                "docs-21-dev": { "lastmod": "2025-12-15T12:00:00Z" }
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(StateFile.self, from: json.data(using: .utf8)!)
        
        #expect(state.packageVersion == "0.21.1")
        #expect(state.subdomains.count == 1)
    }
}

@Suite("SubdomainState Tests")
struct SubdomainStateTests {
    
    @Test("SubdomainState stores lastmod date")
    func basicState() {
        let date = Date()
        let state = SubdomainState(lastmod: date)
        
        #expect(state.lastmod == date)
    }
}

@Suite("StateManager Read/Write Tests")
struct StateManagerIOTests {
    
    @Test("StateManager reads existing state file")
    func readExistingFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-state-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        let json = """
        {
            "package_version": "0.21.1",
            "generated_date": "2025-12-15T12:00:00Z",
            "subdomains": {}
        }
        """
        try json.write(to: statePath, atomically: true, encoding: .utf8)
        
        let state = try StateManager.read(from: statePath.path)
        
        #expect(state?.packageVersion == "0.21.1")
    }
    
    @Test("StateManager returns nil for non-existent file")
    func readNonExistentFile() throws {
        let state = try StateManager.read(from: "/nonexistent/path/state.json")
        
        #expect(state == nil)
    }
    
    @Test("StateManager writes state file")
    func writeStateFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-write-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        let state = StateFile(
            packageVersion: "1.0.0",
            generatedDate: Date(),
            subdomains: [:]
        )
        
        try StateManager.write(state, to: statePath.path)
        
        #expect(FileManager.default.fileExists(atPath: statePath.path))
        
        let content = try String(contentsOfFile: statePath.path, encoding: .utf8)
        #expect(content.contains("package_version"))
        #expect(content.contains("1.0.0"))
    }
}

@Suite("StateManager Update Tests")
struct StateManagerUpdateTests {
    
    @Test("StateManager creates new state file if not exists")
    func createNewState() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-create-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        
        let state = try StateManager.update(
            at: statePath.path,
            packageVersion: "1.0.0"
        )
        
        #expect(state.packageVersion == "1.0.0")
        #expect(FileManager.default.fileExists(atPath: statePath.path))
    }
    
    @Test("StateManager updates existing state with new version")
    func updateExistingState() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        let json = """
        {
            "package_version": "0.21.0",
            "generated_date": "2025-12-01T12:00:00Z",
            "subdomains": {
                "docs-21-dev": { "lastmod": "2025-12-01T12:00:00Z" }
            }
        }
        """
        try json.write(to: statePath, atomically: true, encoding: .utf8)
        
        let state = try StateManager.update(
            at: statePath.path,
            packageVersion: "0.21.1"
        )
        
        #expect(state.packageVersion == "0.21.1")
        // Subdomains should be updated with new date
        #expect(state.subdomains["docs-21-dev"] != nil)
    }
    
    @Test("StateManager preserves subdomains when version unchanged")
    func preserveSubdomainsWhenUnchanged() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-preserve-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        let originalDate = ISO8601DateFormatter().date(from: "2025-12-01T12:00:00Z")!
        let json = """
        {
            "package_version": "0.21.1",
            "generated_date": "2025-12-01T12:00:00Z",
            "subdomains": {
                "docs-21-dev": { "lastmod": "2025-12-01T12:00:00Z" }
            }
        }
        """
        try json.write(to: statePath, atomically: true, encoding: .utf8)
        
        let state = try StateManager.update(
            at: statePath.path,
            packageVersion: "0.21.1"
        )
        
        // Version unchanged, so subdomain lastmod should be preserved
        #expect(state.packageVersion == "0.21.1")
        #expect(state.subdomains["docs-21-dev"]?.lastmod == originalDate)
    }
}

@Suite("StateManager Validation Tests")
struct StateManagerValidationTests {
    
    @Test("validate passes for valid state file")
    func validStateFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-valid-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        let json = """
        {
            "package_version": "0.21.1",
            "generated_date": "2025-12-15T12:00:00Z",
            "subdomains": {}
        }
        """
        try json.write(to: statePath, atomically: true, encoding: .utf8)
        
        let result = StateManager.validate(at: statePath.path)
        
        #expect(result.isValid == true)
    }
    
    @Test("validate fails for non-existent file")
    func nonExistentFile() {
        let result = StateManager.validate(at: "/nonexistent/state.json")
        
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "FILE_NOT_FOUND" })
    }
    
    @Test("validate fails for invalid JSON")
    func invalidJSON() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-invalid-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let statePath = tempDir.appendingPathComponent("state.json")
        try "not valid json".write(to: statePath, atomically: true, encoding: .utf8)
        
        let result = StateManager.validate(at: statePath.path)
        
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "PARSE_ERROR" })
    }
}
