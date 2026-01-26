//
//  DeploymentCommentTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

// MARK: - T003: DeploymentStatus Tests

@Suite("DeploymentStatus Tests")
struct DeploymentStatusTests {
    
    @Test("DeploymentStatus has success case")
    func successCase() {
        let status = DeploymentStatus.success
        #expect(status == .success)
    }
    
    @Test("DeploymentStatus has failure case")
    func failureCase() {
        let status = DeploymentStatus.failure
        #expect(status == .failure)
    }
    
    @Test("DeploymentStatus has pending case")
    func pendingCase() {
        let status = DeploymentStatus.pending
        #expect(status == .pending)
    }
    
    @Test("DeploymentStatus displays correct emoji for success")
    func successEmoji() {
        #expect(DeploymentStatus.success.emoji == "✅")
    }
    
    @Test("DeploymentStatus displays correct emoji for failure")
    func failureEmoji() {
        #expect(DeploymentStatus.failure.emoji == "❌")
    }
    
    @Test("DeploymentStatus displays correct emoji for pending")
    func pendingEmoji() {
        #expect(DeploymentStatus.pending.emoji == "⏳")
    }
    
    @Test("DeploymentStatus is Codable - encodes to string")
    func codableEncode() throws {
        let status = DeploymentStatus.success
        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let string = String(data: data, encoding: .utf8)
        
        #expect(string == "\"success\"")
    }
    
    @Test("DeploymentStatus is Codable - decodes from string")
    func codableDecode() throws {
        let json = "\"failure\""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let status = try decoder.decode(DeploymentStatus.self, from: data)
        
        #expect(status == .failure)
    }
}

// MARK: - T003: DeploymentEntry Tests

@Suite("DeploymentEntry Tests")
struct DeploymentEntryTests {
    
    @Test("DeploymentEntry initializes with all fields")
    func initialization() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://abc123.21-dev.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        #expect(entry.project == "21-dev")
        #expect(entry.status == .success)
        #expect(entry.previewUrl == "https://abc123.21-dev.pages.dev")
        #expect(entry.aliasUrl == "https://preview.21.dev")
    }
    
    @Test("DeploymentEntry is Equatable")
    func equatable() {
        let entry1 = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        let entry2 = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        #expect(entry1 == entry2)
    }
    
    @Test("DeploymentEntry is Codable")
    func codable() throws {
        let entry = DeploymentEntry(
            project: "docs-21-dev",
            status: .failure,
            previewUrl: "https://abc.pages.dev",
            aliasUrl: "https://preview.docs.21.dev"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeploymentEntry.self, from: data)
        
        #expect(decoded == entry)
    }
    
    @Test("DeploymentEntry JSON has expected keys")
    func jsonKeys() throws {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://alias.21.dev"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["project"] as? String == "21-dev")
        #expect(json["status"] as? String == "success")
        #expect(json["previewUrl"] as? String == "https://test.pages.dev")
        #expect(json["aliasUrl"] as? String == "https://alias.21.dev")
    }
}

// MARK: - T004: CommentState Tests

@Suite("CommentState Tests")
struct CommentStateTests {
    
    @Test("CommentState initializes with empty deployments")
    func emptyInitialization() {
        let state = CommentState(
            deployments: [:],
            commit: "abc1234",
            runUrl: "https://github.com/21-DOT-DEV/websites/actions/runs/123"
        )
        
        #expect(state.deployments.isEmpty)
        #expect(state.commit == "abc1234")
        #expect(state.runUrl == "https://github.com/21-DOT-DEV/websites/actions/runs/123")
    }
    
    @Test("CommentState initializes with deployments")
    func withDeployments() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "def5678",
            runUrl: "https://github.com/actions/runs/456"
        )
        
        #expect(state.deployments.count == 1)
        #expect(state.deployments["21-dev"] == entry)
    }
    
    @Test("CommentState is Codable - roundtrip")
    func codableRoundtrip() throws {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc1234567890",
            runUrl: "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CommentState.self, from: data)
        
        #expect(decoded.commit == state.commit)
        #expect(decoded.runUrl == state.runUrl)
        #expect(decoded.deployments["21-dev"] == entry)
    }
    
    @Test("CommentState decodes from expected JSON format")
    func decodeFromJSON() throws {
        let json = """
        {
          "deployments": {
            "21-dev": {
              "project": "21-dev",
              "status": "success",
              "previewUrl": "https://abc123.21-dev.pages.dev",
              "aliasUrl": "https://preview.21.dev"
            }
          },
          "commit": "abc1234567890",
          "runUrl": "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let state = try decoder.decode(CommentState.self, from: data)
        
        #expect(state.commit == "abc1234567890")
        #expect(state.deployments["21-dev"]?.status == .success)
    }
    
    @Test("CommentState supports multiple deployments")
    func multipleDeployments() throws {
        let json = """
        {
          "deployments": {
            "21-dev": {
              "project": "21-dev",
              "status": "success",
              "previewUrl": "https://a.pages.dev",
              "aliasUrl": "https://preview.21.dev"
            },
            "docs-21-dev": {
              "project": "docs-21-dev",
              "status": "failure",
              "previewUrl": "https://b.pages.dev",
              "aliasUrl": "https://preview.docs.21.dev"
            },
            "md-21-dev": {
              "project": "md-21-dev",
              "status": "pending",
              "previewUrl": "https://c.pages.dev",
              "aliasUrl": "https://preview.md.21.dev"
            }
          },
          "commit": "xyz789",
          "runUrl": "https://github.com/actions/runs/999"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let state = try decoder.decode(CommentState.self, from: data)
        
        #expect(state.deployments.count == 3)
        #expect(state.deployments["21-dev"]?.status == .success)
        #expect(state.deployments["docs-21-dev"]?.status == .failure)
        #expect(state.deployments["md-21-dev"]?.status == .pending)
    }
}
