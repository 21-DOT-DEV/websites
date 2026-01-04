//
//  CheckReportTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

@Suite("CheckReport Tests")
struct CheckReportTests {
    
    let baseURL = URL(string: "https://21.dev")!
    
    @Test("Empty report has zero counts")
    func emptyReport() {
        let report = CheckReport(
            results: [],
            baseURL: baseURL,
            scanDirectory: "/test"
        )
        
        #expect(report.validCount == 0)
        #expect(report.mismatchCount == 0)
        #expect(report.missingCount == 0)
        #expect(report.errorCount == 0)
        #expect(report.totalCount == 0)
        #expect(report.isAllValid == true)
    }
    
    @Test("Report counts valid results")
    func countsValidResults() {
        let results = [
            CanonicalResult(
                filePath: "/test/index.html",
                relativePath: "index.html",
                status: .valid,
                existingURL: URL(string: "https://21.dev/")!,
                expectedURL: URL(string: "https://21.dev/")!,
                errorMessage: nil
            ),
            CanonicalResult(
                filePath: "/test/about/index.html",
                relativePath: "about/index.html",
                status: .valid,
                existingURL: URL(string: "https://21.dev/about/")!,
                expectedURL: URL(string: "https://21.dev/about/")!,
                errorMessage: nil
            )
        ]
        
        let report = CheckReport(results: results, baseURL: baseURL, scanDirectory: "/test")
        
        #expect(report.validCount == 2)
        #expect(report.totalCount == 2)
        #expect(report.isAllValid == true)
    }
    
    @Test("Report counts missing results")
    func countsMissingResults() {
        let results = [
            CanonicalResult(
                filePath: "/test/blog/index.html",
                relativePath: "blog/index.html",
                status: .missing,
                existingURL: nil,
                expectedURL: URL(string: "https://21.dev/blog/")!,
                errorMessage: nil
            )
        ]
        
        let report = CheckReport(results: results, baseURL: baseURL, scanDirectory: "/test")
        
        #expect(report.missingCount == 1)
        #expect(report.isAllValid == false)
    }
    
    @Test("Report counts mismatch results")
    func countsMismatchResults() {
        let results = [
            CanonicalResult(
                filePath: "/test/docs/index.html",
                relativePath: "docs/index.html",
                status: .mismatch,
                existingURL: URL(string: "https://old.dev/docs/")!,
                expectedURL: URL(string: "https://21.dev/docs/")!,
                errorMessage: nil
            )
        ]
        
        let report = CheckReport(results: results, baseURL: baseURL, scanDirectory: "/test")
        
        #expect(report.mismatchCount == 1)
        #expect(report.isAllValid == false)
    }
    
    @Test("Report counts error results")
    func countsErrorResults() {
        let results = [
            CanonicalResult(
                filePath: "/test/broken.html",
                relativePath: "broken.html",
                status: .error,
                existingURL: nil,
                expectedURL: URL(string: "https://21.dev/broken")!,
                errorMessage: "No <head> section"
            )
        ]
        
        let report = CheckReport(results: results, baseURL: baseURL, scanDirectory: "/test")
        
        #expect(report.errorCount == 1)
        #expect(report.isAllValid == false)
    }
    
    @Test("Mixed results report")
    func mixedResultsReport() {
        let results = [
            CanonicalResult(
                filePath: "/test/index.html",
                relativePath: "index.html",
                status: .valid,
                existingURL: URL(string: "https://21.dev/")!,
                expectedURL: URL(string: "https://21.dev/")!,
                errorMessage: nil
            ),
            CanonicalResult(
                filePath: "/test/about/index.html",
                relativePath: "about/index.html",
                status: .missing,
                existingURL: nil,
                expectedURL: URL(string: "https://21.dev/about/")!,
                errorMessage: nil
            ),
            CanonicalResult(
                filePath: "/test/blog/index.html",
                relativePath: "blog/index.html",
                status: .mismatch,
                existingURL: URL(string: "https://old.dev/blog/")!,
                expectedURL: URL(string: "https://21.dev/blog/")!,
                errorMessage: nil
            ),
            CanonicalResult(
                filePath: "/test/broken.html",
                relativePath: "broken.html",
                status: .error,
                existingURL: nil,
                expectedURL: URL(string: "https://21.dev/broken")!,
                errorMessage: "Parse error"
            )
        ]
        
        let report = CheckReport(results: results, baseURL: baseURL, scanDirectory: "/test")
        
        #expect(report.validCount == 1)
        #expect(report.missingCount == 1)
        #expect(report.mismatchCount == 1)
        #expect(report.errorCount == 1)
        #expect(report.totalCount == 4)
        #expect(report.isAllValid == false)
    }
    
    @Test("Report is Sendable")
    func isSendable() {
        let report = CheckReport(results: [], baseURL: baseURL, scanDirectory: "/test")
        let sendable: any Sendable = report
        #expect(sendable is CheckReport)
    }
}
