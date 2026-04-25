//
//  DocCSidecar.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Decoded representation of a DocC-emitted page-data sidecar JSON.
///
/// DocC writes one sidecar per documentation page next to the rendered HTML, e.g.:
///
/// - HTML: `documentation/p256k/gettingstarted/index.html`
/// - Sidecar: `data/documentation/p256k/gettingstarted.json`
///
/// The sidecar carries the authoritative title, role (`article`, `symbol`,
/// `collection`, …), abstract, and module assignment that DocC computed from
/// the source. We use it to populate JSON-LD fields (`WebPage.name`,
/// `TechArticle.headline`, `description`, etc.) instead of relying on
/// slug-cased path heuristics.
///
/// Only the fields the schema renderer needs are decoded. Any extra DocC fields
/// (`platforms`, `fragments`, `relationshipsSections`, …) are ignored.
public struct DocCSidecar: Sendable, Decodable {

    /// Top-level `metadata` block from a DocC sidecar.
    public struct Metadata: Sendable, Decodable {
        /// Module assignment entry (DocC encodes this as `[{"name": "P256K"}]`).
        public struct Module: Sendable, Decodable {
            public let name: String
        }

        /// Authored or DocC-derived display title.
        public let title: String?

        /// DocC role (`"article"`, `"symbol"`, `"collection"`,
        /// `"collectionGroup"`, `"landingPage"`, …). Missing for some legacy
        /// or non-standard pages, so all consumers must treat absence as
        /// "no semantic role" rather than a hard error.
        public let role: String?

        /// Swift symbol kind when `role == "symbol"` (e.g., `"struct"`,
        /// `"enum"`, `"property"`).
        public let symbolKind: String?

        /// Module list — typically a single entry pointing at the owning
        /// DocC bundle (e.g., `P256K`, `ZKP`).
        public let modules: [Module]?
    }

    /// One inline-text fragment from `abstract` (DocC encodes as a tagged
    /// array of `{"type": "text", "text": "..."}` objects).
    public struct AbstractFragment: Sendable, Decodable {
        public let type: String?
        public let text: String?
    }

    /// `identifier` block — primarily the canonical `doc://` URL.
    public struct Identifier: Sendable, Decodable {
        public let url: String?
        public let interfaceLanguage: String?
    }

    public let metadata: Metadata
    public let abstract: [AbstractFragment]?
    public let identifier: Identifier?

    /// Article-class semantic role used to choose the JSON-LD content-type
    /// node for a DocC page. Mirrors `metadata.role` with the universe
    /// closed to the values our schema renderer cares about.
    public enum SemanticRole: Sendable, Equatable {
        /// Authored prose article (DocC `role == "article"`). → `TechArticle`.
        case article

        /// Swift symbol page (DocC `role == "symbol"`). → `APIReference`.
        case symbol

        /// Symbol collection / module overview (DocC `role == "collection"`
        /// or `"collectionGroup"`). → `APIReference`.
        case collection

        /// Top-level DocC landing page (DocC `role == "landingPage"`). → no
        /// Article-class node, just `WebPage`.
        case landingPage

        /// Any other DocC role we have not modeled. Renderer should fall
        /// back to `WebPage`-only output and not throw.
        case other(String)

        /// `metadata.role` was missing. Renderer falls back to `WebPage`-only.
        case unknown
    }

    /// Closed enum view of `metadata.role`.
    public var semanticRole: SemanticRole {
        guard let role = metadata.role else { return .unknown }
        switch role {
        case "article":         return .article
        case "symbol":          return .symbol
        case "collection":      return .collection
        case "collectionGroup": return .collection
        case "landingPage":     return .landingPage
        default:                return .other(role)
        }
    }

    /// First module name (`metadata.modules[0].name`), if present.
    public var moduleName: String? {
        metadata.modules?.first?.name
    }

    /// Concatenated plain text of all abstract fragments, or `nil` when the
    /// abstract is missing / empty / contains no text.
    public var concatenatedAbstract: String? {
        guard let abstract, !abstract.isEmpty else { return nil }
        let parts = abstract.compactMap { fragment -> String? in
            guard let text = fragment.text, !text.isEmpty else { return nil }
            return text
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined()
    }
}
