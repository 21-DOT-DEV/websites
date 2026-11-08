//
//  BrokenLink.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// An internal reference that resolves to nothing in the site output.
public struct BrokenLink: Sendable, Equatable {
    /// The HTML attribute that carried the reference (`href`, `src`, `srcset`).
    public let attribute: String

    /// The URL token as written in the markup.
    public let rawValue: String

    /// The site-relative path the reference resolved to (leading `/`).
    public let resolvedPath: String

    /// Why the reference failed, e.g. "no file, directory index, or redirect rule".
    public let reason: String

    public init(attribute: String, rawValue: String, resolvedPath: String, reason: String) {
        self.attribute = attribute
        self.rawValue = rawValue
        self.resolvedPath = resolvedPath
        self.reason = reason
    }
}
