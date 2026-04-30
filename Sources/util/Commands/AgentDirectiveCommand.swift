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
        subcommands: [Inject.self, Audit.self]
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

// MARK: - Audit Subcommand

extension AgentDirectiveCommand {
    /// Apply the hybrid prose-based indexing policy to the downloaded DocC
    /// archives and report which symbol pages should be added to (or removed
    /// from) the registry's `indexablePages` allowlist.
    ///
    /// See `IndexabilityAuditor` in UtilLib for the policy specification.
    struct Audit: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "audit",
            abstract: "Audit DocC archives against the hybrid indexability policy (bidirectional drift)",
            discussion: """
                Walks every module's DocC sidecar tree under --archives-root,
                applies the hybrid policy (Type ≥200, Method ≥300, Aside ≥100
                authored chars), and reports drift in BOTH directions vs.
                `external-archives.json`'s `indexablePages`:

                  • STALE entries (SEO priority): pages currently in the allowlist
                    but no longer pass the policy. They appear in the sitemap as
                    thin content and risk Google Helpful Content demotion of the
                    whole domain. ACTION: remove from `indexablePages`.

                  • NEWLY-DISCOVERED pages (editorial polish): pages that pass
                    the policy but aren't in the allowlist. Currently `noindex`
                    and excluded from the sitemap (single-page traffic loss).
                    ACTION: review and add to `indexablePages` if they belong
                    in search.

                Run this after bumping an archive's `tag` in the registry, or
                as an advisory CI step on every build. Manually review the
                report and reconcile both directions in the next registry PR.
                """
        )

        @Option(
            name: .long,
            help: "Directory containing per-module DocC sidecar trees (e.g., 'p256k/', 'tor/')."
        )
        var archivesRoot: String = "Websites/docs-21-dev/data/documentation"

        @Option(
            name: .long,
            help: "Path to external-archives.json (defaults to the standard registry location)."
        )
        var registry: String = ArchiveRegistry.defaultRelativePath

        @Flag(name: .long, help: "Exit non-zero when ANY drift exists (stale entries or newly-discovered pages).")
        var strict: Bool = false

        @Flag(name: .shortAndLong, help: "Show every eligible page, not just the gap.")
        var verbose: Bool = false

        mutating func validate() throws {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: archivesRoot, isDirectory: &isDir),
                  isDir.boolValue else {
                throw ValidationError("--archives-root does not exist or is not a directory: \(archivesRoot)")
            }
            guard FileManager.default.fileExists(atPath: registry) else {
                throw ValidationError("--registry file not found: \(registry)")
            }
        }

        mutating func run() throws {
            let registryURL = URL(fileURLWithPath: registry)
            let archivesURL = URL(fileURLWithPath: archivesRoot)
            let registryModel: ArchiveRegistry
            do {
                registryModel = try ArchiveRegistry.load(from: registryURL)
            } catch {
                print("❌ Failed to load registry: \(error)")
                throw ExitCode.failure
            }

            let report: IndexabilityAuditor.AuditReport
            do {
                report = try IndexabilityAuditor.audit(
                    archivesRoot: archivesURL,
                    registry: registryModel
                )
            } catch let auditError as IndexabilityAuditor.AuditError {
                print("❌ \(auditError.description)")
                throw ExitCode.failure
            }

            print("Audit against \(registryModel.allIndexablePages.count) currently-allowlisted pages.")
            print("Scanned \(report.modules.count) module(s); applied hybrid policy:")
            print("  - Framework / Module landings: Overview ≥ \(IndexabilityAuditor.frameworkOverviewMinChars) chars")
            print("  - Type pages (Structure/Class/Enum/Protocol/Actor/Type Alias): Overview ≥ \(IndexabilityAuditor.typeOverviewMinChars) chars")
            print("  - Method pages (Method/Init/Property/Subscript/Operator/Case): Discussion ≥ \(IndexabilityAuditor.methodDiscussionMinChars) chars")
            print("  - Aside-bearing pages: Discussion ≥ \(IndexabilityAuditor.asideDiscussionMinChars) chars")
            print()

            // Stale entries lead — they're the SEO-relevant drift signal
            // (thin pages still in the sitemap risk Helpful Content demotion).
            // Newly-discovered entries follow as the secondary editorial signal.
            for moduleReport in report.modules {
                let staleCount = moduleReport.staleEntries.count
                let newCount = moduleReport.newlyDiscovered.count
                let bullet: String
                if staleCount > 0 {
                    bullet = "⚠️"
                } else if newCount > 0 {
                    bullet = "+"
                } else {
                    bullet = "✓"
                }
                print("\(bullet) \(moduleReport.module): \(moduleReport.eligible.count) eligible, \(staleCount) stale, \(newCount) new")

                // Stale entries first (louder).
                for entry in moduleReport.staleEntries {
                    print("    ⚠ \(entry.path)    [\(entry.reason)]")
                }
                // Then newly-discovered.
                if verbose {
                    for entry in moduleReport.eligible {
                        let mark = moduleReport.newlyDiscovered.contains(entry) ? "+" : " "
                        print("    \(mark) \(entry.path)    [\(entry.reason)]")
                    }
                } else {
                    for entry in moduleReport.newlyDiscovered {
                        print("    + \(entry.path)    [\(entry.reason)]")
                    }
                }
            }

            print()
            print("Total: \(report.totalEligible) eligible, \(report.totalStaleEntries) stale, \(report.totalNewlyDiscovered) new.")

            if strict, report.hasGap {
                print()
                if report.totalStaleEntries > 0 {
                    print("❌ --strict: \(report.totalStaleEntries) stale allowlist entr\(report.totalStaleEntries == 1 ? "y" : "ies") detected.")
                    print("   Remove from external-archives.json's indexablePages — these pages are thin-content liabilities.")
                }
                if report.totalNewlyDiscovered > 0 {
                    print("❌ --strict: \(report.totalNewlyDiscovered) newly-eligible page(s) not in allowlist.")
                    print("   Add to external-archives.json's indexablePages and rerun.")
                }
                throw ExitCode.failure
            }
        }
    }
}
