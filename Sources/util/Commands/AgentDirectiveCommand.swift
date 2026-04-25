//
//  AgentDirectiveCommand.swift
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

struct AgentDirectiveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent-directive",
        abstract: "Inject agent directive tags into HTML documentation files",
        subcommands: [Inject.self]
    )
}

extension AgentDirectiveCommand {
    struct Inject: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "inject",
            abstract: "Add agent directive tags guiding AI agents to markdown versions"
        )

        @Option(name: .long, help: "Directory containing HTML files to process")
        var path: String

        @Option(name: .long, help: "Base URL for the site (e.g., https://docs.21.dev)")
        var baseURL: String

        @Flag(name: .long, help: "Replace existing directive tags")
        var force: Bool = false

        @Flag(name: .long, help: "Preview changes without modifying files")
        var dryRun: Bool = false

        @Flag(name: .long, help: "Verify-only mode: check without modifying, exit non-zero on issues")
        var check: Bool = false

        @Flag(name: .shortAndLong, help: "Show detailed output for each file")
        var verbose: Bool = false

        @Option(
            name: .long,
            help: ArgumentHelp(
                "Maximum acceptable DocC sidecar parse-failure rate (0.0–1.0).",
                discussion: """
                The sidecar failure rate is computed as failed / (loaded + failed),
                excluding pages where no sidecar exists (e.g., top-level landing
                pages). The injection step succeeds even when individual sidecars
                fail to parse — it then exits non-zero only if the rate strictly
                exceeds this threshold. Defaults to 0.05 (5%).
                """
            )
        )
        var sidecarFailureThreshold: Double = 0.05

        mutating func validate() throws {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw ValidationError("Path does not exist or is not a directory: \(path)")
            }

            guard let url = URL(string: baseURL),
                  let scheme = url.scheme,
                  scheme == "http" || scheme == "https" else {
                throw ValidationError("Invalid base URL. Must include scheme (e.g., https://docs.21.dev)")
            }
        }

        mutating func run() throws {
            guard let url = URL(string: baseURL) else {
                throw ExitCode.failure
            }

            // --check: verify-only mode
            if check {
                print("Checking agent directives in \(path)...")
                print()

                let (total, present, missing, noindexIssues) = try AgentDirectiveInjector.verify(at: path)

                if verbose {
                    for path in missing {
                        print("❌ Missing: \(path)")
                    }
                    if !missing.isEmpty { print() }
                    for issue in noindexIssues {
                        print("🚫 \(issue)")
                    }
                    if !noindexIssues.isEmpty { print() }
                }

                print("✅ \(present) with directive")
                if !missing.isEmpty {
                    print("❌ \(missing.count) missing directive")
                    if !verbose {
                        for path in missing.prefix(10) { print("  - \(path)") }
                        if missing.count > 10 { print("  ... (\(missing.count - 10) more)") }
                    }
                }
                if !noindexIssues.isEmpty {
                    print("🚫 \(noindexIssues.count) noindex issue\(noindexIssues.count == 1 ? "" : "s")")
                    if !verbose {
                        for issue in noindexIssues.prefix(10) { print("  - \(issue)") }
                        if noindexIssues.count > 10 { print("  ... (\(noindexIssues.count - 10) more)") }
                    }
                }
                if !missing.isEmpty || !noindexIssues.isEmpty {
                    print()
                    print("Result: \(missing.count + noindexIssues.count) issue\(missing.count + noindexIssues.count == 1 ? "" : "s") in \(total) file\(total == 1 ? "" : "s")")
                    throw ExitCode.failure
                }
                print()
                print("Result: All \(total) documentation file\(total == 1 ? "" : "s") have directive and correct noindex status ✓")
                return
            }

            let modeText = dryRun ? " (dry run)" : ""
            print("Injecting agent directives in \(path)...\(modeText)")
            print()

            let report = try AgentDirectiveInjector.injectDirectory(
                at: path,
                baseURL: url,
                force: force,
                dryRun: dryRun
            )

            if verbose {
                printVerboseOutput(report)
            }

            printSummary(report, dryRun: dryRun)

            if !report.isSuccess {
                print()
                print("Result: \(report.failedCount) file\(report.failedCount == 1 ? "" : "s") failed")
                throw ExitCode.failure
            }

            // DocC sidecar failure-rate gate. Sidecar failures don't fail
            // individual injections (the directive still gets emitted with
            // slug-derived fallbacks), but a high enough rate signals a
            // systemic regression and should fail the build.
            if report.exceedsSidecarFailureThreshold(sidecarFailureThreshold) {
                print()
                let percent = String(format: "%.2f%%", report.sidecarFailureRate * 100)
                let limit = String(format: "%.2f%%", sidecarFailureThreshold * 100)
                print("❌ DocC sidecar failure rate \(percent) exceeds threshold \(limit)")
                print("   loaded: \(report.sidecarLoadedCount), failed: \(report.sidecarFailedCount), missing: \(report.sidecarMissingCount)")
                throw ExitCode.failure
            }

            let modifiedCount = report.injectedCount
            print()
            if dryRun {
                print("No files were modified (dry run)")
            } else {
                print("Result: \(modifiedCount) file\(modifiedCount == 1 ? "" : "s") injected")
            }

            // Auto-verify after injection (unless dry run)
            if !dryRun {
                let (_, _, missing, noindexIssues) = try AgentDirectiveInjector.verify(at: path)
                if !missing.isEmpty {
                    print("❌ Verification failed: \(missing.count) file\(missing.count == 1 ? "" : "s") still missing directive")
                    throw ExitCode.failure
                }
                if !noindexIssues.isEmpty {
                    print("❌ Verification failed: \(noindexIssues.count) noindex issue\(noindexIssues.count == 1 ? "" : "s")")
                    throw ExitCode.failure
                }
                print("✅ Verified: all documentation files have agent directive and correct noindex status")
            }
        }

        private func printVerboseOutput(_ report: InjectionReport) {
            for result in report.results {
                let fileName = URL(fileURLWithPath: result.filePath).lastPathComponent
                switch result.action {
                case .injected:
                    print("✅ Injected: \(result.relativePath)")
                case .skipped:
                    print("⏭️ Skipped: \(fileName)")
                case .failed:
                    print("❌ Failed: \(fileName)")
                    if let error = result.errorMessage {
                        print("   Error: \(error)")
                    }
                }
                if result.sidecarStatus == .failed, let message = result.sidecarFailureMessage {
                    print("   ⚠️  Sidecar parse failure: \(message)")
                }
            }
            print()
        }

        private func printSummary(_ report: InjectionReport, dryRun: Bool) {
            let prefix = dryRun ? "Would inject: " : ""
            if report.injectedCount > 0 {
                print("✅ \(prefix)\(report.injectedCount) file\(report.injectedCount == 1 ? "" : "s")")
            }
            if report.skippedCount > 0 {
                print("⏭️ Skipped: \(report.skippedCount) file\(report.skippedCount == 1 ? "" : "s")\(force ? "" : " (use --force to replace)")")
            }
            if report.failedCount > 0 {
                print("❌ Failed: \(report.failedCount) file\(report.failedCount == 1 ? "" : "s")")
            }
            if report.noindexedCount > 0 {
                print("🚫 Noindexed: \(report.noindexedCount) file\(report.noindexedCount == 1 ? "" : "s")")
            }
            if report.indexedCount > 0 {
                print("✅ Indexed: \(report.indexedCount) file\(report.indexedCount == 1 ? "" : "s")")
            }

            // DocC sidecar diagnostics — only print when at least one page
            // had a sidecar attempt resolve (loaded or failed). Pages with
            // status `.missing` are expected and would otherwise drown out
            // the signal.
            let sidecarTotal = report.sidecarLoadedCount + report.sidecarFailedCount
            if sidecarTotal > 0 {
                let percent = String(format: "%.2f%%", report.sidecarFailureRate * 100)
                print("📄 DocC sidecars: \(report.sidecarLoadedCount) loaded, \(report.sidecarFailedCount) failed (\(percent))")
            }
        }
    }
}
