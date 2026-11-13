//
//  RedirectsOutcomeDescriptionTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import UtilLib

/// The report's `CustomStringConvertible` text is what `util redirects verify`
/// prints per rule — every case must name its reason, and the declared and
/// observed values must not trade places.
@Suite("Redirects outcome descriptions")
struct RedirectsOutcomeDescriptionTests {

    @Test("Failure descriptions name declared and observed values in order")
    func failureDescriptions() {
        typealias Failure = RedirectRuleVerification.Failure
        #expect(Failure.statusMismatch(expected: 301, observed: 404).description
            == "expected status 301, got 404")
        #expect(Failure.locationMismatch(expected: "/docs", observed: "/elsewhere").description
            == "expected Location \"/docs\", got \"/elsewhere\"")
        #expect(Failure.locationMismatch(expected: "/docs", observed: nil).description
            == "expected Location \"/docs\", got none")
        #expect(Failure.transportError("connection refused").description
            == "probe request failed: connection refused")
        #expect(Failure.edgeRefused(.uncompilableSource).description
            == "edge would not apply this rule: source cannot compile — more than one '*' splat")
    }

    @Test("Skip descriptions name why the rule could not be proven")
    func skipDescriptions() {
        typealias Skip = RedirectRuleVerification.Skip
        #expect(Skip.noDeployedRoot.description
            == "no deployed output root — cannot derive a real target or rule out SPA fallback")
        #expect(Skip.noDerivableTarget.description
            == "no deployed file matches the rule's target")
        #expect(Skip.probeSourceIsDeployedAsset.description
            == "probe source is itself a deployed asset — a 200 there proves nothing")
        #expect(Skip.probeSourceShadowed.description
            == "an earlier rule matches the probe source first")
        #expect(Skip.probeSourceUnmatchable.description
            == "the constructed probe source does not match this rule")
        #expect(Skip.spaFallbackUnprovable.description
            == "no top-level 404.html — SPA fallback could answer any 200")
    }

    @Test("Refusal descriptions name why the edge drops the rule")
    func refusalDescriptions() {
        #expect(RedirectEdgeRefusal.unsupportedStatus(404).description
            == "unsupported status 404 (permitted: 200, 301, 302, 303, 307, 308)")
        #expect(RedirectEdgeRefusal.externalProxyTarget.description
            == "200 rewrite target must be site-relative — external proxying is unsupported")
        #expect(RedirectEdgeRefusal.uncompilableSource.description
            == "source cannot compile — more than one '*' splat")
        #expect(RedirectEdgeRefusal.selfReferencingTarget.description
            == "target loops back through the rule's own source")
    }
}
