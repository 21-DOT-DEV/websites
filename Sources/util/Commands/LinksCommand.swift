//
//  LinksCommand.swift
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

struct LinksCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "links",
        abstract: "Normalize internal anchor href values in HTML output",
        subcommands: [Rewrite.self],
        defaultSubcommand: Rewrite.self
    )
}

extension LinksCommand {
    struct Rewrite: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "rewrite",
            abstract: "Strip trailing /index.html from <a href> values (use --check for CI verify-only mode)"
        )

        @Option(name: .long, help: "Directory containing HTML files to rewrite")
        var path: String

        @Flag(name: .long, help: "Preview changes without modifying files")
        var dryRun: Bool = false

        @Flag(name: .long, help: "Verify-only mode: report what would change, exit non-zero on issues")
        var check: Bool = false

        @Flag(name: .shortAndLong, help: "Show detailed output for each file")
        var verbose: Bool = false

        mutating func validate() throws {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw ValidationError("Path does not exist or is not a directory: \(path)")
            }
        }

        mutating func run() throws {
            // --check is dry-run + non-zero exit on drift.
            let effectiveDryRun = check || dryRun

            let modeText: String
            if check {
                modeText = " (check)"
            } else if dryRun {
                modeText = " (dry run)"
            } else {
                modeText = ""
            }
            print("Rewriting anchor links in \(path)...\(modeText)")
            print()

            let report = try LinkRewriter.rewriteDirectory(at: path, dryRun: effectiveDryRun)

            if verbose {
                printVerboseOutput(report)
            }

            printSummary(report, dryRun: effectiveDryRun)

            if !report.isSuccess {
                print()
                print("Result: \(report.failedCount) file\(report.failedCount == 1 ? "" : "s") failed")
                throw ExitCode.failure
            }

            // --check: drift detection. Any rewritable anchors == drift.
            if check {
                if report.totalLinksRewritten > 0 {
                    print()
                    print("Result: \(report.totalLinksRewritten) anchor\(report.totalLinksRewritten == 1 ? "" : "s") in \(report.rewrittenCount) file\(report.rewrittenCount == 1 ? "" : "s") would be rewritten")
                    throw ExitCode.failure
                }
                print()
                print("Result: All anchor links normalized ✓")
                return
            }

            print()
            if effectiveDryRun {
                print("No files were modified (dry run)")
            } else {
                print("Result: \(report.totalLinksRewritten) anchor\(report.totalLinksRewritten == 1 ? "" : "s") rewritten across \(report.rewrittenCount) file\(report.rewrittenCount == 1 ? "" : "s")")
            }
        }

        private func printVerboseOutput(_ report: LinkRewriteReport) {
            for result in report.results where result.action != .unchanged {
                let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
                switch result.action {
                case .rewritten:
                    print("✅ \(fileName) (\(result.rewriteCount) link\(result.rewriteCount == 1 ? "" : "s"))")
                case .failed:
                    print("❌ \(fileName)")
                    if let error = result.errorMessage {
                        print("   Error: \(error)")
                    }
                case .unchanged:
                    break
                }
            }
            print()
        }

        private func printSummary(_ report: LinkRewriteReport, dryRun: Bool) {
            let prefix = dryRun ? "Would rewrite: " : "Rewritten: "
            if report.rewrittenCount > 0 {
                print("✅ \(prefix)\(report.rewrittenCount) file\(report.rewrittenCount == 1 ? "" : "s") (\(report.totalLinksRewritten) anchor\(report.totalLinksRewritten == 1 ? "" : "s"))")
            }
            if report.unchangedCount > 0 {
                print("⏭️ Unchanged: \(report.unchangedCount) file\(report.unchangedCount == 1 ? "" : "s")")
            }
            if report.failedCount > 0 {
                print("❌ Failed: \(report.failedCount) file\(report.failedCount == 1 ? "" : "s")")
            }
        }
    }
}
