//
//  DeploymentComment.swift
//  UtilLib
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Status of a deployment operation.
public enum DeploymentStatus: String, Codable, Equatable, Sendable {
    case success
    case failure
    case pending
    
    /// Emoji representation for display in PR comments.
    public var emoji: String {
        switch self {
        case .success: return "✅"
        case .failure: return "❌"
        case .pending: return "⏳"
        }
    }
}

/// Represents a single subdomain deployment within a PR comment.
public struct DeploymentEntry: Codable, Equatable, Sendable {
    /// Project identifier (e.g., "21-dev", "docs-21-dev", "md-21-dev").
    public let project: String
    
    /// Deployment outcome status.
    public let status: DeploymentStatus
    
    /// Cloudflare preview URL.
    public let previewUrl: String
    
    /// Cloudflare alias URL.
    public let aliasUrl: String
    
    public init(project: String, status: DeploymentStatus, previewUrl: String, aliasUrl: String) {
        self.project = project
        self.status = status
        self.previewUrl = previewUrl
        self.aliasUrl = aliasUrl
    }
}

/// JSON structure embedded in HTML comment for state persistence.
/// Contains all deployment entries plus shared metadata.
public struct CommentState: Codable, Equatable, Sendable {
    /// Map of project name to deployment entry.
    public var deployments: [String: DeploymentEntry]
    
    /// Git commit SHA (shared across all deployments in a single workflow run).
    public let commit: String
    
    /// GitHub Actions run URL (shared across all deployments).
    public let runUrl: String
    
    public init(deployments: [String: DeploymentEntry], commit: String, runUrl: String) {
        self.deployments = deployments
        self.commit = commit
        self.runUrl = runUrl
    }
}
