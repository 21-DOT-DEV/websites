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
        abstract: "Normalize and verify internal links in HTML output",
        subcommands: [Rewrite.self, Check.self],
        defaultSubcommand: Rewrite.self
    )
}

extension LinksCommand {
    /// Verifies internal references resolve to files in the site output.
    ///
    /// Fails the build (exit 1) when generated HTML links to a path that
    /// doesn't exist — the Docusaurus `onBrokenLinks: 'throw'` model applied
    /// as a post-generation step. External URLs and non-HTTP schemes are
    /// skipped; a `_redirects` rule the edge would apply counts as valid.
    struct Check: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "check",
            abstract: "Fail on internal links that don't resolve to output files"
        )

        @Option(name: .long, help: "Site output directory containing HTML files")
        var path: String

        @Flag(name: .shortAndLong, help: "List every checked reference per file")
        var verbose: Bool = false

        mutating func validate() throws {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw ValidationError("Path does not exist or is not a directory: \(path)")
            }
        }

        mutating func run() throws {
            print("Checking internal links in \(path)...")
            print()

            let report = try InternalLinkChecker.checkDirectory(at: path)

            for file in report.filesWithBrokenLinks {
                print("❌ \(file.relativePath)")
                for link in file.brokenLinks {
                    print("   \(link.attribute)=\"\(link.rawValue)\" → \(link.resolvedPath) (\(link.reason))")
                }
            }
            if !report.filesWithBrokenLinks.isEmpty { print() }

            for warning in report.scanWarnings {
                print("⚠️  \(warning)")
            }
            for file in report.skippedFiles {
                print("⚠️  skipped \(file.relativePath): \(file.skippedReason ?? "unreadable")")
            }
            if !report.warnings.isEmpty { print() }

            print("Checked: \(report.totalChecked) internal reference\(report.totalChecked == 1 ? "" : "s") across \(report.results.count) file\(report.results.count == 1 ? "" : "s")")
            print("Skipped: \(report.totalSkipped) external/scheme/fragment reference\(report.totalSkipped == 1 ? "" : "s")")
            if !report.warnings.isEmpty {
                print("Warnings: \(report.warnings.count) unparseable file\(report.warnings.count == 1 ? "" : "s") or unreadable site config")
            }

            if verbose {
                print()
                for file in report.results where file.checkedCount > 0 || file.skippedReason != nil {
                    if file.skippedReason != nil {
                        continue // already named in the warnings block above
                    }
                    print("\(file.brokenLinks.isEmpty ? "✅" : "❌") \(file.relativePath) (\(file.checkedCount) checked)")
                    for reference in file.references {
                        switch reference.outcome {
                        case .resolved(let sitePath):
                            print("   ✓ \(reference.attribute.rawValue)=\"\(reference.rawValue)\" → \(sitePath)")
                        case .broken(let resolvedPath, let reason):
                            print("   ✗ \(reference.attribute.rawValue)=\"\(reference.rawValue)\" → \(resolvedPath) (\(reason))")
                        case .skipped:
                            continue
                        }
                    }
                }
            }

            print()
            if report.results.isEmpty || report.skippedFiles.count == report.results.count {
                print("Result: No HTML files could be checked under \(path) — nothing was verified")
                throw ExitCode.failure
            }
            if report.isSuccess {
                print("Result: All internal links resolve ✓")
            } else {
                print("Result: \(report.totalBroken) broken link\(report.totalBroken == 1 ? "" : "s") in \(report.filesWithBrokenLinks.count) file\(report.filesWithBrokenLinks.count == 1 ? "" : "s")")
                throw ExitCode.failure
            }
        }
    }
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
