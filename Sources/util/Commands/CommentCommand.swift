//
//  CommentCommand.swift
//  util
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import ArgumentParser
import Foundation
import Subprocess
import UtilLib

/// CLI command for posting unified PR deployment comments.
///
/// Posts or updates a single unified comment on a GitHub PR that aggregates
/// deployment information from multiple subdomains (21-dev, docs-21-dev, md-21-dev).
///
/// **Usage:**
/// ```
/// swift run util comment \
///   --pr 42 \
///   --project 21-dev \
///   --status success \
///   --preview-url "https://abc123.21-dev.pages.dev" \
///   --alias-url "https://preview.21.dev" \
///   --commit "abc1234567890" \
///   --run-url "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
/// ```
///
/// **Features:**
/// - Aggregates multiple subdomain deployments into one comment
/// - Preserves state via hidden JSON marker in comment body
/// - Uses `gh` CLI for GitHub API interaction
/// - Supports status values: success (✅), failure (❌), pending (⏳)
///
/// **Requirements:**
/// - GitHub CLI (`gh`) must be installed and authenticated
/// - GITHUB_TOKEN environment variable (automatic in GitHub Actions)
struct CommentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "comment",
        abstract: "Post or update unified deployment comment on a PR",
        discussion: """
        Aggregates deployment previews from multiple subdomains into a single \
        unified PR comment. Each invocation updates only the specified project's \
        row while preserving other deployments.
        
        The comment includes a hidden JSON marker for state persistence, \
        enabling robust merging of deployment data across workflow runs.
        """
    )
    
    @Option(name: .long, help: "Pull request number")
    var pr: Int
    
    @Option(name: .long, help: "Project name (21-dev, docs-21-dev, md-21-dev)")
    var project: String
    
    @Option(name: .long, help: "Deployment status (success, failure, pending)")
    var status: String
    
    @Option(name: .long, help: "Cloudflare preview URL")
    var previewUrl: String
    
    @Option(name: .long, help: "Cloudflare alias URL")
    var aliasUrl: String
    
    @Option(name: .long, help: "Git commit SHA")
    var commit: String
    
    @Option(name: .long, help: "GitHub Actions run URL")
    var runUrl: String
    
    mutating func run() async throws {
        // Parse status
        guard let deploymentStatus = DeploymentStatus(rawValue: status) else {
            throw ValidationError("Invalid status: \(status). Valid values: success, failure, pending")
        }
        
        // Create deployment entry for this invocation
        let entry = DeploymentEntry(
            project: project,
            status: deploymentStatus,
            previewUrl: previewUrl,
            aliasUrl: aliasUrl
        )
        
        // US2: Fetch existing comments and merge state
        var state = try await fetchAndParseExistingState(pr: pr)
        
        // If no existing state, create new state with current deployment
        if state == nil {
            state = CommentState(
                deployments: [:],
                commit: commit,
                runUrl: runUrl
            )
        }
        
        // Merge new deployment into state
        CommentService.mergeDeployment(entry, into: &state!)
        
        // Update commit and runUrl to latest values
        state = CommentState(
            deployments: state!.deployments,
            commit: commit,
            runUrl: runUrl
        )
        
        // Generate comment body with merged state
        let body = CommentService.generateCommentBody(from: state!)
        
        // Post comment using gh CLI
        try await postComment(pr: pr, body: body)
        print("✅ Updated deployment comment for PR #\(pr)")
    }
    
    /// Fetches existing PR comments and parses deployment state if found.
    private func fetchAndParseExistingState(pr: Int) async throws -> CommentState? {
        let fetchArgs = CommentService.buildFetchCommentsArguments(pr: pr)
        
        do {
            let result = try await Subprocess.run(
                .name("gh"),
                arguments: .init(fetchArgs),
                output: .string(limit: 65536),
                error: .string(limit: 4096)
            )
            
            guard case .exited(0) = result.terminationStatus,
                  let output = result.standardOutput else {
                return nil
            }
            
            // Parse comment bodies
            let bodies = try CommentService.parseCommentsResponse(output)
            
            // Find deployment comment
            guard let deploymentComment = CommentService.findDeploymentComment(in: bodies) else {
                return nil
            }
            
            // Parse state from comment (US3 dependency - use parseCommentState when available)
            return try CommentService.parseCommentState(from: deploymentComment)
        } catch {
            // If fetching fails, treat as no existing state
            return nil
        }
    }
    
    /// Posts or updates a comment on the PR using gh CLI.
    private func postComment(pr: Int, body: String) async throws {
        // Try edit-last first
        let editArgs = CommentService.buildPostCommentArguments(pr: pr, body: body)
        
        do {
            let result = try await Subprocess.run(
                .name("gh"),
                arguments: .init(editArgs),
                output: .string(limit: 4096),
                error: .string(limit: 4096)
            )
            
            // Check if edit-last succeeded
            if case .exited(0) = result.terminationStatus {
                return
            }
        } catch {
            // edit-last failed, fall back to create
        }
        
        // Fallback: create new comment
        let createArgs = CommentService.buildCreateCommentArguments(pr: pr, body: body)
        
        let result = try await Subprocess.run(
            .name("gh"),
            arguments: .init(createArgs),
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            let stderr = result.standardError ?? "Unknown error"
            
            if stderr.contains("not logged") || stderr.contains("authentication") {
                throw CommentError.notAuthenticated
            } else if stderr.contains("not found") || stderr.contains("command not found") {
                throw CommentError.cliNotFound
            } else {
                throw CommentError.apiError(stderr)
            }
        }
    }
}
