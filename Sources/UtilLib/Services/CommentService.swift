//
//  CommentService.swift
//  UtilLib
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Errors that can occur during PR comment operations.
public enum CommentError: Error, Equatable, Sendable {
    /// The gh CLI tool is not installed or not found in PATH.
    case cliNotFound
    
    /// The gh CLI is not authenticated (GITHUB_TOKEN missing or invalid).
    case notAuthenticated
    
    /// The GitHub API returned an error.
    case apiError(String)
    
    /// Failed to parse the response from gh CLI.
    case parseError(String)
}

extension CommentError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "gh CLI not found. Ensure GitHub CLI is installed and in PATH."
        case .notAuthenticated:
            return "Not authenticated. Run 'gh auth login' or set GITHUB_TOKEN."
        case .apiError(let message):
            return "GitHub API error: \(message)"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

// MARK: - CommentService

/// Service for managing PR deployment comments via gh CLI.
public enum CommentService {
    
    /// Marker prefix for embedded JSON state in comments.
    public static let markerPrefix = "<!-- util-deployments:"
    public static let markerSuffix = " -->"
    
    // MARK: - T009: Generate Comment Body
    
    /// Generates markdown comment body from deployment state.
    /// Includes hidden JSON marker at start for state persistence.
    public static func generateCommentBody(from state: CommentState) -> String {
        var lines: [String] = []
        
        // Embed JSON state as hidden marker
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let jsonData = try? encoder.encode(state),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            lines.append("\(markerPrefix)\(jsonString)\(markerSuffix)")
        }
        
        // Header with shared context (use short 7-char commit hash)
        let shortCommit = String(state.commit.prefix(7))
        lines.append("### Deployment Preview 🚀")
        lines.append("**Commit**: \(shortCommit) | **Run**: [View Logs](\(state.runUrl))")
        lines.append("")
        
        // Table header
        lines.append("| Subdomain | Status | Preview URL | Alias URL |")
        lines.append("|-----------|--------|-------------|-----------|")
        
        // Sort deployments by project name for consistent ordering
        let sortedDeployments = state.deployments.sorted { $0.key < $1.key }
        
        for (_, entry) in sortedDeployments {
            let subdomain = projectToSubdomain(entry.project)
            let status = entry.status.emoji
            
            // Show ⏳ for empty/stale preview URLs, otherwise show link
            let previewDisplay: String
            if entry.previewUrl.isEmpty {
                previewDisplay = "⏳"
            } else {
                previewDisplay = "[\(entry.previewUrl)](\(entry.previewUrl))"
            }
            
            // Alias URL is fixed - always show link
            let aliasLink = "[\(entry.aliasUrl)](\(entry.aliasUrl))"
            
            lines.append("| \(subdomain) | \(status) | \(previewDisplay) | \(aliasLink) |")
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Converts project name (e.g., "docs-21-dev") to subdomain display (e.g., "docs.21.dev").
    public static func projectToSubdomain(_ project: String) -> String {
        switch project {
        case "21-dev":
            return "21.dev"
        case "docs-21-dev":
            return "docs.21.dev"
        case "md-21-dev":
            return "md.21.dev"
        default:
            // Generic conversion: replace hyphens with dots
            return project.replacingOccurrences(of: "-", with: ".")
        }
    }
    
    // MARK: - T010: Post Comment Arguments
    
    /// Builds arguments for `gh issue comment --edit-last`.
    public static func buildPostCommentArguments(pr: Int, body: String) -> [String] {
        return ["issue", "comment", "\(pr)", "--edit-last", "--body", body]
    }
    
    /// Builds arguments for `gh issue comment` (create new).
    public static func buildCreateCommentArguments(pr: Int, body: String) -> [String] {
        return ["issue", "comment", "\(pr)", "--body", body]
    }
    
    // MARK: - T015: Fetch Existing Comments
    
    /// Builds arguments for `gh issue view --json comments`.
    public static func buildFetchCommentsArguments(pr: Int) -> [String] {
        return ["issue", "view", "\(pr)", "--json", "comments"]
    }
    
    /// Parses the JSON response from `gh issue view --json comments`.
    /// Returns an array of comment body strings.
    public static func parseCommentsResponse(_ json: String) throws -> [String] {
        guard let data = json.data(using: .utf8) else {
            throw CommentError.parseError("Invalid JSON encoding")
        }
        
        struct CommentsResponse: Decodable {
            struct Comment: Decodable {
                let body: String
            }
            let comments: [Comment]
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(CommentsResponse.self, from: data)
        return response.comments.map { $0.body }
    }
    
    /// Finds the deployment comment (with marker) in an array of comment bodies.
    public static func findDeploymentComment(in comments: [String]) -> String? {
        return comments.first { $0.contains(markerPrefix) }
    }
    
    // MARK: - T016: Merge Deployment
    
    /// Merges a new deployment entry into existing state (upsert by project key).
    /// If the commit has changed, resets other subdomains to pending status.
    public static func mergeDeployment(_ entry: DeploymentEntry, into state: inout CommentState, newCommit: String) {
        // Check if commit has changed - if so, reset other subdomains
        if state.commit != newCommit {
            resetOtherDeployments(except: entry.project, in: &state)
        }
        state.deployments[entry.project] = entry
    }
    
    /// Resets all deployments except the specified project to pending status.
    /// Clears preview URLs but keeps alias URLs (which are fixed).
    public static func resetOtherDeployments(except currentProject: String, in state: inout CommentState) {
        for (project, existingEntry) in state.deployments {
            if project != currentProject {
                state.deployments[project] = DeploymentEntry(
                    project: existingEntry.project,
                    status: .pending,
                    previewUrl: "",  // Clear stale preview URL
                    aliasUrl: existingEntry.aliasUrl  // Keep fixed alias URL
                )
            }
        }
    }
    
    // MARK: - US3: Parse Comment State (needed for US2 merge flow)
    
    /// Extracts and parses the JSON state from a deployment comment body.
    public static func parseCommentState(from commentBody: String) throws -> CommentState? {
        // Find the JSON marker in the comment
        guard let prefixRange = commentBody.range(of: markerPrefix),
              let suffixRange = commentBody.range(of: markerSuffix, range: prefixRange.upperBound..<commentBody.endIndex) else {
            return nil
        }
        
        // Extract JSON string between markers
        let jsonString = String(commentBody[prefixRange.upperBound..<suffixRange.lowerBound])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw CommentError.parseError("Invalid JSON encoding in comment")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(CommentState.self, from: jsonData)
    }
}
