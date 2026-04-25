//
//  SchemaProtocol.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Protocol for all schema.org JSON-LD types.
/// Conforming types can be encoded to JSON-LD and combined in a @graph.
public protocol Schema: Encodable, Sendable {
    /// The schema.org type (e.g., "FAQPage", "Organization")
    static var schemaType: String { get }
}

/// A container for schema.org JSON-LD structured data.
/// Automatically uses the optimal format based on schema count:
/// - Single schema: Simple format (no @graph wrapper)
/// - Multiple schemas: @graph format for entity relationships
public struct SchemaGraph: Sendable {
    private let context = "https://schema.org"
    private let schemas: [AnyEncodable]
    
    /// Creates a schema graph from an array of schemas.
    public init(_ schemas: [any Schema]) {
        self.schemas = schemas.map { AnyEncodable($0) }
    }
    
    /// Creates a schema graph from variadic schemas.
    public init(_ schemas: any Schema...) {
        self.schemas = schemas.map { AnyEncodable($0) }
    }
    
    /// Renders the schema(s) as a pretty-printed JSON-LD string.
    /// Uses simple format for single schema, @graph for multiple.
    public func render() throws -> String {
        try render(formatting: [.prettyPrinted, .sortedKeys])
    }

    /// Renders the schema(s) as a compact (minified) JSON-LD string.
    /// Ideal for inline HTML injection where file size matters.
    public func renderCompact() throws -> String {
        try render(formatting: [.sortedKeys])
    }

    private func render(formatting: JSONEncoder.OutputFormatting) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = formatting
        
        let data: Data
        if schemas.count == 1 {
            // Single schema: use simple format without @graph
            let wrapper = SingleSchemaWrapper(context: context, schema: schemas[0])
            data = try encoder.encode(wrapper)
        } else {
            // Multiple schemas: use @graph format
            let wrapper = GraphSchemaWrapper(context: context, graph: schemas)
            data = try encoder.encode(wrapper)
        }
        let raw = String(data: data, encoding: .utf8) ?? "{}"
        // Inline-JSON-LD safety: prevent `</script>` smuggling into the surrounding
        // <script type="application/ld+json"> block. Escapes `<` and `>` as \u003c
        // and \u003e — canonical pattern recommended by Mozilla and OWASP for inline
        // JSON. Behavior-preserving for all current consumers (no schema field today
        // legitimately contains `<` or `>`).
        return raw
            .replacingOccurrences(of: "<", with: "\\u003c")
            .replacingOccurrences(of: ">", with: "\\u003e")
    }
}

/// Wrapper for single schema (simple format)
private struct SingleSchemaWrapper: Encodable {
    let context: String
    let schema: AnyEncodable
    
    enum CodingKeys: String, CodingKey {
        case context = "@context"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(context, forKey: .context)
        // Encode schema fields at the same level as @context
        try schema.encode(to: encoder)
    }
}

/// Wrapper for multiple schemas (@graph format)
private struct GraphSchemaWrapper: Encodable {
    let context: String
    let graph: [AnyEncodable]
    
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case graph = "@graph"
    }
}

/// Type-erased wrapper for encoding heterogeneous Schema types.
public struct AnyEncodable: Encodable, Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void
    
    public init<T: Encodable & Sendable>(_ wrapped: T) {
        _encode = { encoder in
            try wrapped.encode(to: encoder)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
