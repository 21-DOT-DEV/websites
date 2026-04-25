//
//  SiteIdentityTests.swift
//  SiteIdentityTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import SchemaLib
@testable import SiteIdentity

@Suite("SiteIdentity")
struct SiteIdentityTests {
    @Test("organizationSchema id matches schemaID constant")
    func organizationSchemaIDMatchesSchemaID() {
        // Future regression: someone renames .schemaID without updating .organizationSchema.
        #expect(SiteIdentity.organizationSchema.id == SiteIdentity.schemaID)
    }

    @Test("sameAs contains GitHub, X, and Nostr URLs")
    func sameAsContainsExpectedSocials() {
        #expect(SiteIdentity.sameAs.contains(SiteIdentity.githubURL))
        #expect(SiteIdentity.sameAs.contains(SiteIdentity.twitterURL))
        #expect(SiteIdentity.sameAs.contains(SiteIdentity.nostrURL))
    }

    @Test("websiteSchema id is the org url + #website fragment")
    func websiteSchemaIDFragment() {
        #expect(SiteIdentity.websiteSchema.id == "\(SiteIdentity.url)#website")
    }

    @Test("schemaID uses the canonical 21.dev #organization @id")
    func schemaIDIsCanonical() {
        #expect(SiteIdentity.schemaID == "https://21.dev/#organization")
    }
}
