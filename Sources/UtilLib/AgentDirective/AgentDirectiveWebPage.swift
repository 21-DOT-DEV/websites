//
//  AgentDirectiveWebPage.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SchemaLib

/// Schema.org WebPage used for agent directive injection.
///
/// Encodes a WebPage with:
/// - `isPartOf`: A `WebSite` for the module-level llms.txt (or parent site)
/// - `mainEntity`: A `WebSite` for the root llms.txt
///
/// Markdown alternate linking is handled separately via `<link rel="alternate">`.
struct AgentDirectiveWebPage: Schema {
    static let schemaType = "WebPage"

    let isPartOf: WebSiteSchema
    let mainEntity: WebSiteSchema

    private enum CodingKeys: String, CodingKey {
        case type = "@type"
        case isPartOf
        case mainEntity
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.schemaType, forKey: .type)
        try container.encode(isPartOf, forKey: .isPartOf)
        try container.encode(mainEntity, forKey: .mainEntity)
    }
}
