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

                let (total, present, missing) = try AgentDirectiveInjector.verify(at: path)

                if verbose {
                    for path in missing {
                        print("❌ Missing: \(path)")
                    }
                    if !missing.isEmpty { print() }
                }

                print("✅ \(present) with directive")
                if !missing.isEmpty {
                    print("❌ \(missing.count) missing directive")
                    if !verbose {
                        for path in missing.prefix(10) { print("  - \(path)") }
                        if missing.count > 10 { print("  ... (\(missing.count - 10) more)") }
                    }
                    print()
                    print("Result: \(missing.count) of \(total) file\(total == 1 ? "" : "s") missing directive")
                    throw ExitCode.failure
                }
                print()
                print("Result: All \(total) documentation file\(total == 1 ? "" : "s") have directive ✓")
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
            } else {
                let modifiedCount = report.injectedCount
                print()
                if dryRun {
                    print("No files were modified (dry run)")
                } else {
                    print("Result: \(modifiedCount) file\(modifiedCount == 1 ? "" : "s") injected")
                }
            }

            // Auto-verify after injection (unless dry run)
            if !dryRun {
                let (_, _, missing) = try AgentDirectiveInjector.verify(at: path)
                if !missing.isEmpty {
                    print("❌ Verification failed: \(missing.count) file\(missing.count == 1 ? "" : "s") still missing directive")
                    throw ExitCode.failure
                }
                print("✅ Verified: all documentation files have agent directive")
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
        }
    }
}
