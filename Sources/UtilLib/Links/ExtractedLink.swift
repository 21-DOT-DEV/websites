//
//  ExtractedLink.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// A single URL reference extracted from an HTML attribute.
public struct ExtractedLink: Sendable, Equatable {
    /// The HTML attribute the value came from.
    public enum Attribute: String, Sendable {
        case href
        case src
        case srcset
    }

    /// Which attribute carried the reference.
    public let attribute: Attribute

    /// The URL token — for `srcset`, one candidate URL rather than the whole attribute.
    public let rawValue: String

    public init(attribute: Attribute, rawValue: String) {
        self.attribute = attribute
        self.rawValue = rawValue
    }
}
