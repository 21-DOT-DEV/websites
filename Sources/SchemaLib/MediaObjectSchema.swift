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
    
    /// Creates a MediaObject schema.
    /// - Parameters:
    ///   - contentUrl: URL of the media content
    ///   - encodingFormat: MIME type (e.g., `text/markdown`)
    public init(contentUrl: String, encodingFormat: String) {
        self.contentUrl = contentUrl
        self.encodingFormat = encodingFormat
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case contentUrl
        case encodingFormat
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(contentUrl, forKey: .contentUrl)
        try container.encode(encodingFormat, forKey: .encodingFormat)
    }
}
