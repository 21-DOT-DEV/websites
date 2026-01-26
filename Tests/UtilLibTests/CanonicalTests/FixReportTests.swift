//
//  FixReportTests.swift
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

@Suite("FixResult Tests")
struct FixResultTests {
    
    @Test("Create added result")
    func createAddedResult() {
        let result = FixResult(
            filePath: "/test/index.html",
            action: .added,
            errorMessage: nil
        )
        
        #expect(result.filePath == "/test/index.html")
        #expect(result.action == .added)
        #expect(result.errorMessage == nil)
    }
    
    @Test("Create skipped result")
    func createSkippedResult() {
        let result = FixResult(
            filePath: "/test/about.html",
            action: .skipped,
            errorMessage: nil
        )
        
        #expect(result.action == .skipped)
    }
    
    @Test("Create failed result with message")
    func createFailedResult() {
        let result = FixResult(
            filePath: "/test/broken.html",
            action: .failed,
            errorMessage: "Cannot write to file"
        )
        
        #expect(result.action == .failed)
        #expect(result.errorMessage == "Cannot write to file")
    }
    
    @Test("FixAction raw values")
    func fixActionRawValues() {
        #expect(FixAction.added.rawValue == "added")
        #expect(FixAction.updated.rawValue == "updated")
        #expect(FixAction.skipped.rawValue == "skipped")
        #expect(FixAction.failed.rawValue == "failed")
    }
}

@Suite("FixReport Tests")
struct FixReportTests {
    
    @Test("Empty report has zero counts")
    func emptyReport() {
        let report = FixReport(results: [])
        
        #expect(report.addedCount == 0)
        #expect(report.updatedCount == 0)
        #expect(report.skippedCount == 0)
        #expect(report.failedCount == 0)
        #expect(report.isSuccess == true)
    }
    
    @Test("Report counts added results")
    func countsAddedResults() {
        let results = [
            FixResult(filePath: "/test/a.html", action: .added, errorMessage: nil),
            FixResult(filePath: "/test/b.html", action: .added, errorMessage: nil)
        ]
        
        let report = FixReport(results: results)
        
        #expect(report.addedCount == 2)
        #expect(report.isSuccess == true)
    }
    
    @Test("Report counts updated results")
    func countsUpdatedResults() {
        let results = [
            FixResult(filePath: "/test/c.html", action: .updated, errorMessage: nil)
        ]
        
        let report = FixReport(results: results)
        
        #expect(report.updatedCount == 1)
        #expect(report.isSuccess == true)
    }
    
    @Test("Report counts skipped results")
    func countsSkippedResults() {
        let results = [
            FixResult(filePath: "/test/d.html", action: .skipped, errorMessage: nil),
            FixResult(filePath: "/test/e.html", action: .skipped, errorMessage: nil),
            FixResult(filePath: "/test/f.html", action: .skipped, errorMessage: nil)
        ]
        
        let report = FixReport(results: results)
        
        #expect(report.skippedCount == 3)
        #expect(report.isSuccess == true)
    }
    
    @Test("Report counts failed results")
    func countsFailedResults() {
        let results = [
            FixResult(filePath: "/test/g.html", action: .failed, errorMessage: "Error")
        ]
        
        let report = FixReport(results: results)
        
        #expect(report.failedCount == 1)
        #expect(report.isSuccess == false)
    }
    
    @Test("Mixed results report")
    func mixedResultsReport() {
        let results = [
            FixResult(filePath: "/test/a.html", action: .added, errorMessage: nil),
            FixResult(filePath: "/test/b.html", action: .updated, errorMessage: nil),
            FixResult(filePath: "/test/c.html", action: .skipped, errorMessage: nil),
            FixResult(filePath: "/test/d.html", action: .failed, errorMessage: "Error")
        ]
        
        let report = FixReport(results: results)
        
        #expect(report.addedCount == 1)
        #expect(report.updatedCount == 1)
        #expect(report.skippedCount == 1)
        #expect(report.failedCount == 1)
        #expect(report.isSuccess == false)
    }
    
    @Test("Report is Sendable")
    func isSendable() {
        let report = FixReport(results: [])
        let sendable: any Sendable = report
        #expect(sendable is FixReport)
    }
}
