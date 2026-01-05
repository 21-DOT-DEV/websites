//
//  CommentServiceTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

// MARK: - T006b: CommentError Tests

@Suite("CommentError Tests")
struct CommentErrorTests {
    
    @Test("CommentError.cliNotFound has descriptive message")
    func cliNotFoundMessage() {
        let error = CommentError.cliNotFound
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("gh CLI"))
        #expect(description.contains("not found"))
    }
    
    @Test("CommentError.notAuthenticated has descriptive message")
    func notAuthenticatedMessage() {
        let error = CommentError.notAuthenticated
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("authenticated"))
        #expect(description.contains("GITHUB_TOKEN"))
    }
    
    @Test("CommentError.apiError includes the error message")
    func apiErrorMessage() {
        let error = CommentError.apiError("Resource not found")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("Resource not found"))
        #expect(description.contains("API"))
    }
    
    @Test("CommentError.parseError includes the parse failure reason")
    func parseErrorMessage() {
        let error = CommentError.parseError("Invalid JSON")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("Invalid JSON"))
        #expect(description.contains("parse"))
    }
    
    @Test("CommentError is Equatable - same cases are equal")
    func equatableSameCases() {
        #expect(CommentError.cliNotFound == CommentError.cliNotFound)
        #expect(CommentError.notAuthenticated == CommentError.notAuthenticated)
    }
    
    @Test("CommentError is Equatable - different cases are not equal")
    func equatableDifferentCases() {
        #expect(CommentError.cliNotFound != CommentError.notAuthenticated)
    }
    
    @Test("CommentError.apiError is Equatable with same message")
    func apiErrorEquatable() {
        let error1 = CommentError.apiError("Not found")
        let error2 = CommentError.apiError("Not found")
        let error3 = CommentError.apiError("Forbidden")
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
    
    @Test("CommentError.parseError is Equatable with same message")
    func parseErrorEquatable() {
        let error1 = CommentError.parseError("Bad JSON")
        let error2 = CommentError.parseError("Bad JSON")
        let error3 = CommentError.parseError("Missing field")
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}

// MARK: - T007: generateCommentBody Tests

@Suite("CommentService generateCommentBody Tests")
struct GenerateCommentBodyTests {
    
    @Test("generateCommentBody produces markdown with header")
    func producesHeader() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://abc123.21-dev.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc1234567890",
            runUrl: "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        #expect(body.contains("### Deployment Preview"))
        #expect(body.contains("abc1234567890"))
        #expect(body.contains("actions/runs/12345"))
    }
    
    @Test("generateCommentBody includes deployment table")
    func includesTable() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://abc123.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc123",
            runUrl: "https://github.com/actions/runs/1"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        #expect(body.contains("| Subdomain |"))
        #expect(body.contains("| Status |"))
        #expect(body.contains("| Preview URL |"))
        #expect(body.contains("| Alias URL |"))
    }
    
    @Test("generateCommentBody shows correct status emoji")
    func statusEmoji() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://alias.21.dev"
        )
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc",
            runUrl: "https://github.com/runs/1"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        #expect(body.contains("✅"))
    }
    
    @Test("generateCommentBody includes preview and alias URLs as links")
    func urlsAsLinks() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://abc123.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc",
            runUrl: "https://github.com/runs/1"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        #expect(body.contains("[https://abc123.pages.dev]"))
        #expect(body.contains("[https://preview.21.dev]"))
    }
    
    @Test("generateCommentBody embeds JSON marker at start")
    func embedsJSONMarker() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://alias.21.dev"
        )
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc123",
            runUrl: "https://github.com/runs/1"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        #expect(body.hasPrefix("<!-- util-deployments:"))
        #expect(body.contains("-->"))
    }
    
    @Test("generateCommentBody JSON marker contains valid JSON")
    func jsonMarkerIsValid() throws {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://alias.21.dev"
        )
        let state = CommentState(
            deployments: ["21-dev": entry],
            commit: "abc123",
            runUrl: "https://github.com/runs/1"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        // Extract JSON from marker
        let pattern = #"<!-- util-deployments:(.*?) -->"#
        let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        let range = NSRange(body.startIndex..., in: body)
        
        guard let match = regex.firstMatch(in: body, options: [], range: range),
              let jsonRange = Range(match.range(at: 1), in: body) else {
            Issue.record("JSON marker not found in body")
            return
        }
        
        let jsonString = String(body[jsonRange])
        let jsonData = jsonString.data(using: .utf8)!
        
        // Should decode without throwing
        let decoded = try JSONDecoder().decode(CommentState.self, from: jsonData)
        #expect(decoded.commit == "abc123")
        #expect(decoded.deployments["21-dev"]?.status == .success)
    }
    
    @Test("generateCommentBody maps project name to subdomain display")
    func projectToSubdomain() {
        let entry = DeploymentEntry(
            project: "docs-21-dev",
            status: .failure,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://alias.docs.21.dev"
        )
        let state = CommentState(
            deployments: ["docs-21-dev": entry],
            commit: "xyz",
            runUrl: "https://github.com/runs/2"
        )
        
        let body = CommentService.generateCommentBody(from: state)
        
        // Should display as docs.21.dev not docs-21-dev
        #expect(body.contains("docs.21.dev"))
        #expect(body.contains("❌"))
    }
}

// MARK: - T008: postComment Tests (Mock-based)

@Suite("CommentService postComment Tests")
struct PostCommentTests {
    
    @Test("postComment constructs correct gh CLI arguments")
    func constructsCorrectArguments() {
        // Test the argument construction logic
        let expectedArgs = CommentService.buildPostCommentArguments(pr: 42, body: "Test body")
        
        #expect(expectedArgs.contains("issue"))
        #expect(expectedArgs.contains("comment"))
        #expect(expectedArgs.contains("42"))
        #expect(expectedArgs.contains("--edit-last"))
        #expect(expectedArgs.contains("--body"))
        #expect(expectedArgs.contains("Test body"))
    }
    
    @Test("postComment falls back to create when edit-last fails")
    func fallbackToCreate() {
        // Test the fallback argument construction
        let fallbackArgs = CommentService.buildCreateCommentArguments(pr: 42, body: "Test body")
        
        #expect(fallbackArgs.contains("issue"))
        #expect(fallbackArgs.contains("comment"))
        #expect(fallbackArgs.contains("42"))
        #expect(!fallbackArgs.contains("--edit-last"))
        #expect(fallbackArgs.contains("--body"))
    }
}

// MARK: - T013: fetchExistingComments Tests

@Suite("CommentService fetchExistingComments Tests")
struct FetchExistingCommentsTests {
    
    @Test("buildFetchCommentsArguments constructs correct gh CLI arguments")
    func constructsCorrectArguments() {
        let args = CommentService.buildFetchCommentsArguments(pr: 42)
        
        #expect(args.contains("issue"))
        #expect(args.contains("view"))
        #expect(args.contains("42"))
        #expect(args.contains("--json"))
        #expect(args.contains("comments"))
    }
    
    @Test("parseCommentsResponse extracts comment bodies")
    func parseCommentsResponse() throws {
        let json = """
        {
            "comments": [
                {"body": "First comment"},
                {"body": "<!-- util-deployments:{\\"deployments\\":{}} -->Second comment"}
            ]
        }
        """
        
        let bodies = try CommentService.parseCommentsResponse(json)
        
        #expect(bodies.count == 2)
        #expect(bodies[0] == "First comment")
        #expect(bodies[1].contains("util-deployments"))
    }
    
    @Test("parseCommentsResponse handles empty comments array")
    func emptyComments() throws {
        let json = """
        {"comments": []}
        """
        
        let bodies = try CommentService.parseCommentsResponse(json)
        
        #expect(bodies.isEmpty)
    }
    
    @Test("findDeploymentComment finds comment with marker")
    func findDeploymentComment() {
        let comments = [
            "Some random comment",
            "<!-- util-deployments:{} -->Deployment info",
            "Another comment"
        ]
        
        let found = CommentService.findDeploymentComment(in: comments)
        
        #expect(found != nil)
        #expect(found?.contains("util-deployments") == true)
    }
    
    @Test("findDeploymentComment returns nil when no marker")
    func noDeploymentComment() {
        let comments = [
            "Some random comment",
            "Another comment"
        ]
        
        let found = CommentService.findDeploymentComment(in: comments)
        
        #expect(found == nil)
    }
}

// MARK: - T014: mergeDeployment Tests

@Suite("CommentService mergeDeployment Tests")
struct MergeDeploymentTests {
    
    @Test("mergeDeployment adds new deployment to empty state")
    func addToEmptyState() {
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        var state = CommentState(
            deployments: [:],
            commit: "abc123",
            runUrl: "https://github.com/runs/1"
        )
        
        CommentService.mergeDeployment(entry, into: &state, newCommit: "abc123")
        
        #expect(state.deployments.count == 1)
        #expect(state.deployments["21-dev"] == entry)
    }
    
    @Test("mergeDeployment updates existing deployment")
    func updateExisting() {
        let oldEntry = DeploymentEntry(
            project: "21-dev",
            status: .pending,
            previewUrl: "https://old.pages.dev",
            aliasUrl: "https://old.21.dev"
        )
        let newEntry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://new.pages.dev",
            aliasUrl: "https://new.21.dev"
        )
        
        var state = CommentState(
            deployments: ["21-dev": oldEntry],
            commit: "abc123",
            runUrl: "https://github.com/runs/1"
        )
        
        CommentService.mergeDeployment(newEntry, into: &state, newCommit: "abc123")
        
        #expect(state.deployments.count == 1)
        #expect(state.deployments["21-dev"]?.status == .success)
        #expect(state.deployments["21-dev"]?.previewUrl == "https://new.pages.dev")
    }
    
    @Test("mergeDeployment preserves other deployments with same commit")
    func preserveOthers() {
        let existingEntry = DeploymentEntry(
            project: "docs-21-dev",
            status: .success,
            previewUrl: "https://docs.pages.dev",
            aliasUrl: "https://preview.docs.21.dev"
        )
        let newEntry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://main.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        var state = CommentState(
            deployments: ["docs-21-dev": existingEntry],
            commit: "abc123",
            runUrl: "https://github.com/runs/1"
        )
        
        CommentService.mergeDeployment(newEntry, into: &state, newCommit: "abc123")
        
        #expect(state.deployments.count == 2)
        #expect(state.deployments["docs-21-dev"] == existingEntry)
        #expect(state.deployments["21-dev"] == newEntry)
    }
    
    @Test("mergeDeployment handles all three subdomains")
    func allThreeSubdomains() {
        var state = CommentState(
            deployments: [:],
            commit: "xyz789",
            runUrl: "https://github.com/runs/2"
        )
        
        let entries = [
            DeploymentEntry(project: "21-dev", status: .success, previewUrl: "https://a.pages.dev", aliasUrl: "https://a.21.dev"),
            DeploymentEntry(project: "docs-21-dev", status: .failure, previewUrl: "https://b.pages.dev", aliasUrl: "https://b.21.dev"),
            DeploymentEntry(project: "md-21-dev", status: .pending, previewUrl: "https://c.pages.dev", aliasUrl: "https://c.21.dev")
        ]
        
        for entry in entries {
            CommentService.mergeDeployment(entry, into: &state, newCommit: "xyz789")
        }
        
        #expect(state.deployments.count == 3)
        #expect(state.deployments["21-dev"]?.status == .success)
        #expect(state.deployments["docs-21-dev"]?.status == .failure)
        #expect(state.deployments["md-21-dev"]?.status == .pending)
    }
    
    @Test("mergeDeployment resets other subdomains when commit changes")
    func resetsOnCommitChange() {
        let existingEntry = DeploymentEntry(
            project: "docs-21-dev",
            status: .success,
            previewUrl: "https://old-docs.pages.dev",
            aliasUrl: "https://preview.docs.21.dev"
        )
        let newEntry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://new-main.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        var state = CommentState(
            deployments: ["docs-21-dev": existingEntry],
            commit: "oldcommit123",
            runUrl: "https://github.com/runs/1"
        )
        
        // Merge with different commit - should reset docs-21-dev
        CommentService.mergeDeployment(newEntry, into: &state, newCommit: "newcommit456")
        
        #expect(state.deployments.count == 2)
        #expect(state.deployments["21-dev"]?.status == .success)
        #expect(state.deployments["21-dev"]?.previewUrl == "https://new-main.pages.dev")
        // docs-21-dev should be reset to pending with empty preview URL
        #expect(state.deployments["docs-21-dev"]?.status == .pending)
        #expect(state.deployments["docs-21-dev"]?.previewUrl == "")
        // Alias URL should be preserved
        #expect(state.deployments["docs-21-dev"]?.aliasUrl == "https://preview.docs.21.dev")
    }
    
    @Test("mergeDeployment does not reset when commit is the same")
    func noResetOnSameCommit() {
        let existingEntry = DeploymentEntry(
            project: "docs-21-dev",
            status: .success,
            previewUrl: "https://docs.pages.dev",
            aliasUrl: "https://preview.docs.21.dev"
        )
        let newEntry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://main.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        
        var state = CommentState(
            deployments: ["docs-21-dev": existingEntry],
            commit: "samecommit",
            runUrl: "https://github.com/runs/1"
        )
        
        // Merge with same commit - should NOT reset docs-21-dev
        CommentService.mergeDeployment(newEntry, into: &state, newCommit: "samecommit")
        
        #expect(state.deployments.count == 2)
        #expect(state.deployments["21-dev"]?.status == .success)
        // docs-21-dev should remain unchanged
        #expect(state.deployments["docs-21-dev"]?.status == .success)
        #expect(state.deployments["docs-21-dev"]?.previewUrl == "https://docs.pages.dev")
    }
}

// MARK: - T018: parseCommentState Tests

@Suite("CommentService parseCommentState Tests")
struct ParseCommentStateTests {
    
    @Test("parseCommentState extracts JSON from marker")
    func extractsJSON() throws {
        let commentBody = """
        <!-- util-deployments:{"deployments":{"21-dev":{"project":"21-dev","status":"success","previewUrl":"https://test.pages.dev","aliasUrl":"https://preview.21.dev"}},"commit":"abc123","runUrl":"https://github.com/runs/1"} -->
        ### Deployment Preview
        Some content here
        """
        
        let state = try CommentService.parseCommentState(from: commentBody)
        
        #expect(state != nil)
        #expect(state?.commit == "abc123")
        #expect(state?.deployments["21-dev"]?.status == .success)
    }
    
    @Test("parseCommentState returns nil when no marker present")
    func noMarker() throws {
        let commentBody = """
        ### Deployment Preview
        Just a regular comment without our marker
        """
        
        let state = try CommentService.parseCommentState(from: commentBody)
        
        #expect(state == nil)
    }
    
    @Test("parseCommentState handles multiple deployments")
    func multipleDeployments() throws {
        let commentBody = """
        <!-- util-deployments:{"deployments":{"21-dev":{"project":"21-dev","status":"success","previewUrl":"https://a.pages.dev","aliasUrl":"https://a.21.dev"},"docs-21-dev":{"project":"docs-21-dev","status":"failure","previewUrl":"https://b.pages.dev","aliasUrl":"https://b.21.dev"}},"commit":"xyz789","runUrl":"https://github.com/runs/2"} -->
        ### Deployment Preview
        """
        
        let state = try CommentService.parseCommentState(from: commentBody)
        
        #expect(state != nil)
        #expect(state?.deployments.count == 2)
        #expect(state?.deployments["21-dev"]?.status == .success)
        #expect(state?.deployments["docs-21-dev"]?.status == .failure)
    }
    
    @Test("parseCommentState roundtrip with generateCommentBody")
    func roundtrip() throws {
        // Create original state
        let entry = DeploymentEntry(
            project: "21-dev",
            status: .success,
            previewUrl: "https://test.pages.dev",
            aliasUrl: "https://preview.21.dev"
        )
        let originalState = CommentState(
            deployments: ["21-dev": entry],
            commit: "roundtrip123",
            runUrl: "https://github.com/runs/roundtrip"
        )
        
        // Generate comment body
        let body = CommentService.generateCommentBody(from: originalState)
        
        // Parse it back
        let parsedState = try CommentService.parseCommentState(from: body)
        
        #expect(parsedState != nil)
        #expect(parsedState?.commit == originalState.commit)
        #expect(parsedState?.runUrl == originalState.runUrl)
        #expect(parsedState?.deployments["21-dev"] == entry)
    }
}

// MARK: - T019: Malformed/Missing JSON Handling Tests

@Suite("CommentService malformed JSON Tests")
struct MalformedJSONTests {
    
    @Test("parseCommentState returns nil for incomplete marker")
    func incompleteMarker() throws {
        let commentBody = """
        <!-- util-deployments:{"deployments":{}}
        Missing closing marker
        """
        
        let state = try CommentService.parseCommentState(from: commentBody)
        
        #expect(state == nil)
    }
    
    @Test("parseCommentState throws for invalid JSON")
    func invalidJSON() {
        let commentBody = """
        <!-- util-deployments:{not valid json} -->
        ### Deployment Preview
        """
        
        #expect(throws: Error.self) {
            _ = try CommentService.parseCommentState(from: commentBody)
        }
    }
    
    @Test("parseCommentState handles empty deployments")
    func emptyDeployments() throws {
        let commentBody = """
        <!-- util-deployments:{"deployments":{},"commit":"abc","runUrl":"https://github.com/runs/1"} -->
        ### Deployment Preview
        """
        
        let state = try CommentService.parseCommentState(from: commentBody)
        
        #expect(state != nil)
        #expect(state?.deployments.isEmpty == true)
    }
    
    @Test("parseCommentState handles marker with extra whitespace")
    func markerWithWhitespace() throws {
        // Note: Our marker format has a space before -->
        let commentBody = """
        <!-- util-deployments:{"deployments":{},"commit":"abc","runUrl":"https://github.com/runs/1"} -->
        Content
        """
        
        let state = try CommentService.parseCommentState(from: commentBody)
        
        #expect(state != nil)
    }
}
