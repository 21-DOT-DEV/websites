//
//  MediaObjectSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org MediaObject type for content encoding references.
/// https://schema.org/MediaObject
public struct MediaObjectSchema: Schema {
    public static let schemaType = "MediaObject"
    
    private let type = "MediaObject"
    public let contentUrl: String
    public let encodingFormat: String
    public let description: String?
    
    /// Creates a MediaObject schema.
    /// - Parameters:
    ///   - contentUrl: URL of the media content
    ///   - encodingFormat: MIME type (e.g., `text/markdown`)
    ///   - description: Human-readable description of this media object
    public init(contentUrl: String, encodingFormat: String, description: String? = nil) {
        self.contentUrl = contentUrl
        self.encodingFormat = encodingFormat
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case contentUrl
        case description
        case encodingFormat
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(contentUrl, forKey: .contentUrl)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(encodingFormat, forKey: .encodingFormat)
    }
}
