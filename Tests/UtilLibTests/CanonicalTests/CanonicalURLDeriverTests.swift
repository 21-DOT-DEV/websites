//
//  CanonicalURLDeriverTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

@Suite("CanonicalURLDeriver Tests")
struct CanonicalURLDeriverTests {
    
    let baseURL = URL(string: "https://21.dev")!
    
    @Test("Derive URL for index.html at root")
    func deriveRootIndex() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "index.html")
        #expect(url.absoluteString == "https://21.dev/")
    }
    
    @Test("Derive URL for index.html in subdirectory")
    func deriveSubdirectoryIndex() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "about/index.html")
        #expect(url.absoluteString == "https://21.dev/about/")
    }
    
    @Test("Derive URL for nested index.html")
    func deriveNestedIndex() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "docs/guide/index.html")
        #expect(url.absoluteString == "https://21.dev/docs/guide/")
    }
    
    @Test("Derive URL for non-index HTML file")
    func deriveNonIndexFile() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "about.html")
        #expect(url.absoluteString == "https://21.dev/about")
    }
    
    @Test("Derive URL for nested non-index HTML file")
    func deriveNestedNonIndexFile() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "docs/api-reference.html")
        #expect(url.absoluteString == "https://21.dev/docs/api-reference")
    }
    
    @Test("Base URL with trailing slash")
    func baseURLWithTrailingSlash() {
        let baseWithSlash = URL(string: "https://21.dev/")!
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseWithSlash, relativePath: "about/index.html")
        #expect(url.absoluteString == "https://21.dev/about/")
    }
    
    @Test("Base URL without trailing slash")
    func baseURLWithoutTrailingSlash() {
        let baseNoSlash = URL(string: "https://21.dev")!
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseNoSlash, relativePath: "about/index.html")
        #expect(url.absoluteString == "https://21.dev/about/")
    }
    
    @Test("Derive URL for docs subdomain")
    func deriveDocsSubdomain() {
        let docsBase = URL(string: "https://docs.21.dev")!
        let url = CanonicalURLDeriver.deriveURL(baseURL: docsBase, relativePath: "documentation/p256k/index.html")
        #expect(url.absoluteString == "https://docs.21.dev/documentation/p256k/")
    }
    
    @Test("Relative path should not start with slash")
    func relativePathWithoutLeadingSlash() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "blog/post-1.html")
        #expect(url.absoluteString == "https://21.dev/blog/post-1")
    }
    
    @Test("Handle deeply nested paths")
    func handleDeeplyNestedPaths() {
        let url = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: "a/b/c/d/index.html")
        #expect(url.absoluteString == "https://21.dev/a/b/c/d/")
    }
}
