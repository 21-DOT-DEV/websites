//
//  CanonicalCommand.swift
//  util
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import ArgumentParser
import Foundation
import UtilLib

struct CanonicalCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "canonical",
        abstract: "Check and fix canonical URL tags in HTML files",
        subcommands: [Check.self, Fix.self]
    )
}

extension CanonicalCommand {
    struct Check: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "check",
            abstract: "Audit HTML files for canonical URL issues"
        )
        
        @Option(name: .long, help: "Directory containing HTML files to scan")
        var path: String
        
        @Option(name: .long, help: "Base URL for canonical derivation (e.g., https://21.dev)")
        var baseURL: String
        
        @Flag(name: .shortAndLong, help: "Show detailed output for each file")
        var verbose: Bool = false
        
        mutating func validate() throws {
            // Validate path exists and is a directory
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw ValidationError("Path does not exist or is not a directory: \(path)")
            }
            
            // Validate base URL has scheme
            guard let url = URL(string: baseURL),
                  let scheme = url.scheme,
                  scheme == "http" || scheme == "https" else {
                throw ValidationError("Invalid base URL. Must include scheme (e.g., https://21.dev)")
            }
        }
        
        mutating func run() throws {
            guard let url = URL(string: baseURL) else {
                throw ExitCode.failure
            }
            
            print("Checking canonicals in \(path)...")
            print()
            
            let report = try CanonicalChecker.checkDirectory(at: path, baseURL: url)
            
            if verbose {
                printVerboseResults(report)
            }
            
            printSummary(report)
            
            if !report.isAllValid {
                let issueCount = report.mismatchCount + report.missingCount + report.errorCount
                print()
                print("Result: \(issueCount) issue\(issueCount == 1 ? "" : "s") found")
                throw ExitCode.failure
            } else {
                print()
                print("Result: All canonicals valid ✓")
            }
        }
        
        private func printVerboseResults(_ report: CheckReport) {
            for result in report.results {
                switch result.status {
                case .valid:
                    print("✅ \(result.relativePath) → \(result.expectedURL.absoluteString)")
                case .missing:
                    print("❌ \(result.relativePath) (missing)")
                case .mismatch:
                    print("⚠️ \(result.relativePath)")
                    print("   Expected: \(result.expectedURL.absoluteString)")
                    if let existing = result.existingURL {
                        print("   Found:    \(existing.absoluteString)")
                    }
                case .error:
                    print("⚠️ \(result.relativePath)")
                    if let message = result.errorMessage {
                        print("   Error: \(message)")
                    }
                }
            }
            print()
            print("Summary:")
        }
        
        private func printSummary(_ report: CheckReport) {
            print("✅ \(report.validCount) valid")
            if report.mismatchCount > 0 {
                print("⚠️ \(report.mismatchCount) mismatch")
            }
            if report.missingCount > 0 {
                print("❌ \(report.missingCount) missing")
            }
            if report.errorCount > 0 {
                print("⚠️ \(report.errorCount) error\(report.errorCount == 1 ? "" : "s")")
            }
        }
    }
    
    struct Fix: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "fix",
            abstract: "Add or update canonical URL tags in HTML files"
        )
        
        @Option(name: .long, help: "Directory containing HTML files to fix")
        var path: String
        
        @Option(name: .long, help: "Base URL for canonical derivation (e.g., https://21.dev)")
        var baseURL: String
        
        @Flag(name: .long, help: "Overwrite existing canonical tags")
        var force: Bool = false
        
        @Flag(name: .long, help: "Preview changes without modifying files")
        var dryRun: Bool = false
        
        @Flag(name: .shortAndLong, help: "Show detailed output for each file")
        var verbose: Bool = false
        
        mutating func validate() throws {
            // Validate path exists and is a directory
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw ValidationError("Path does not exist or is not a directory: \(path)")
            }
            
            // Validate base URL has scheme
            guard let url = URL(string: baseURL),
                  let scheme = url.scheme,
                  scheme == "http" || scheme == "https" else {
                throw ValidationError("Invalid base URL. Must include scheme (e.g., https://21.dev)")
            }
        }
        
        mutating func run() throws {
            guard let url = URL(string: baseURL) else {
                throw ExitCode.failure
            }
            
            let modeText = dryRun ? " (dry run)" : ""
            print("Fixing canonicals in \(path)...\(modeText)")
            print()
            
            // First check the directory
            let checkReport = try CanonicalChecker.checkDirectory(at: path, baseURL: url)
            
            // Then fix based on check results
            let fixReport = try CanonicalFixer.fixDirectory(
                checkReport: checkReport,
                force: force,
                dryRun: dryRun
            )
            
            if dryRun {
                printDryRunOutput(fixReport)
            } else if verbose {
                printVerboseOutput(fixReport)
            }
            
            printSummary(fixReport, dryRun: dryRun)
            
            if !fixReport.isSuccess {
                print()
                print("Result: \(fixReport.failedCount) file\(fixReport.failedCount == 1 ? "" : "s") failed")
                throw ExitCode.failure
            } else {
                let modifiedCount = fixReport.addedCount + fixReport.updatedCount
                print()
                if dryRun {
                    print("No files were modified (dry run)")
                } else {
                    print("Result: \(modifiedCount) file\(modifiedCount == 1 ? "" : "s") updated")
                }
            }
        }
        
        private func printDryRunOutput(_ report: FixReport) {
            let toAdd = report.results.filter { $0.action == .added }
            let toUpdate = report.results.filter { $0.action == .updated }
            let toSkip = report.results.filter { $0.action == .skipped }
            
            if !toAdd.isEmpty {
                print("Would add canonical to:")
                for result in toAdd.prefix(10) {
                    let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
                    print("  - \(fileName)")
                }
                if toAdd.count > 10 {
                    print("  ... (\(toAdd.count - 10) more)")
                }
                print()
            }
            
            if !toUpdate.isEmpty {
                print("Would update canonical in:")
                for result in toUpdate.prefix(10) {
                    let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
                    print("  - \(fileName)")
                }
                if toUpdate.count > 10 {
                    print("  ... (\(toUpdate.count - 10) more)")
                }
                print()
            }
            
            if !toSkip.isEmpty && verbose {
                print("Would skip (existing canonical):")
                for result in toSkip.prefix(5) {
                    let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
                    print("  - \(fileName)")
                }
                if toSkip.count > 5 {
                    print("  ... (\(toSkip.count - 5) more)")
                }
                print()
            }
        }
        
        private func printVerboseOutput(_ report: FixReport) {
            for result in report.results {
                let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
                switch result.action {
                case .added:
                    print("✅ Added: \(fileName)")
                case .updated:
                    print("✅ Updated: \(fileName)")
                case .skipped:
                    print("⏭️ Skipped: \(fileName)")
                case .failed:
                    print("❌ Failed: \(fileName)")
                    if let error = result.errorMessage {
                        print("   Error: \(error)")
                    }
                }
            }
            print()
        }
        
        private func printSummary(_ report: FixReport, dryRun: Bool) {
            let prefix = dryRun ? "Would " : ""
            if report.addedCount > 0 {
                print("✅ \(prefix)Added: \(report.addedCount) file\(report.addedCount == 1 ? "" : "s")")
            }
            if report.updatedCount > 0 {
                print("✅ \(prefix)Updated: \(report.updatedCount) file\(report.updatedCount == 1 ? "" : "s")")
            }
            if report.skippedCount > 0 {
                print("⚠️ Skipped: \(report.skippedCount) file\(report.skippedCount == 1 ? "" : "s")\(force ? "" : " (use --force to overwrite)")")
            }
            if report.failedCount > 0 {
                print("❌ Failed: \(report.failedCount) file\(report.failedCount == 1 ? "" : "s")")
            }
        }
    }
}
