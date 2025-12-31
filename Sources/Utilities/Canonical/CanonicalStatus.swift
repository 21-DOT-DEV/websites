//
//  CanonicalStatus.swift
//  Utilities
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Enumeration representing the check result state for a single HTML file.
public enum CanonicalStatus: String, Sendable {
    /// Existing canonical tag matches the expected/derived URL
    case valid
    
    /// Existing canonical tag differs from the expected/derived URL
    case mismatch
    
    /// No `<link rel="canonical">` tag present in the HTML file
    case missing
    
    /// File could not be processed (parse error, no head section, etc.)
    case error
}
