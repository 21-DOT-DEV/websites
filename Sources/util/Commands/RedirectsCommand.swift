//
//  RedirectsCommand.swift
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

/// CLI command for Cloudflare _redirects operations.
struct RedirectsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "redirects",
        abstract: "Cloudflare _redirects verification",
        subcommands: [Verify.self],
        defaultSubcommand: Verify.self
    )
}

extension RedirectsCommand {
    /// Verifies every rule in a `_redirects` file against a live deployment.
    ///
    /// Checks are derived from the file itself (Specs/007) so a new rule
    /// cannot ship unverified: each rule is probed and its observed status
    /// and `Location` asserted against the declaration. Rules the edge would
    /// not apply fail with the refusal named before any request fires; rules
    /// that cannot be proven are reported skipped with a reason. Exits
    /// non-zero when any rule fails — a deploy gate, not a lint.
    struct Verify: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "verify",
            abstract: "Verify _redirects rules against a deployed base URL"
        )

        @Option(name: .long, help: "Target site identifier (21-dev, docs-21-dev)")
        var site: String?

        @Option(name: .long, help: "Fixture _redirects file; its parent directory is used as the deployed root (alternative to --site)")
        var file: String?

        @Option(name: .long, help: "Deployment origin to verify against (e.g. https://<hash>.<project>.pages.dev)")
        var baseUrl: String

        mutating func validate() throws {
            // Must have either --site or --file
            if site == nil && file == nil {
                throw ValidationError("Either --site or --file is required")
            }

            // Cannot have both
            if site != nil && file != nil {
                throw ValidationError("Cannot specify both --site and --file")
            }

            // The file is the subject of the verification — a missing,
            // unreadable, or non-regular file is a usage error, never a
            // silent pass: a FIFO or device would block the read forever.
            // `resolveRulesFile` returns a resolved absolute path, so a
            // symlinked `_redirects` checks out as the file it points at.
            let location = try resolveRulesFile()
            let isRegularFile = (try? FileManager.default
                .attributesOfItem(atPath: location.path)[.type] as? FileAttributeType) == .typeRegular
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: location.path, isDirectory: &isDirectory),
                  !isDirectory.boolValue,
                  isRegularFile,
                  FileManager.default.isReadableFile(atPath: location.path) else {
                throw ValidationError("_redirects file does not exist, is not readable, or is not a regular file: \(location.path)")
            }

            _ = try validatedBaseURL()
        }

        mutating func run() async throws {
            let location = try resolveRulesFile()
            let baseURL = try validatedBaseURL()

            let rules: [RedirectRule]
            do {
                rules = RedirectsParser.parse(try String(contentsOfFile: location.path, encoding: .utf8))
            } catch {
                // A read failure mid-run is a verification failure, not a
                // usage error — name the underlying cause.
                print("❌ Could not read _redirects file at \(location.path): \(error.localizedDescription)")
                throw ExitCode.failure
            }

            // A file that parses to zero rules verifies nothing — fail
            // closed rather than pass a deploy on an empty suite (the
            // `links check` "nothing was verified" posture).
            guard !rules.isEmpty else {
                print("Result: No rules parsed from \(location.path) — nothing was verified")
                throw ExitCode.failure
            }

            var isDirectory: ObjCBool = false
            let deployedRootIsPresent = FileManager.default
                .fileExists(atPath: location.deployedRoot, isDirectory: &isDirectory)
                && isDirectory.boolValue

            print("Verifying redirects on \(baseURL.absoluteString)...")
            print("  Rules: \(location.path) (\(rules.count) rule\(rules.count == 1 ? "" : "s"))")
            print("  Deployed root: \(location.deployedRoot)\(deployedRootIsPresent ? "" : " (not found — real-target probes will skip)")")

            let verifier = RedirectsVerifier()
            let report = await verifier.verify(
                rules: rules,
                baseURL: baseURL,
                deployedRoot: deployedRootIsPresent ? location.deployedRoot : nil
            )
            print("  Probe token: \(report.probeToken)")
            print()

            for result in report.results {
                let declaration = "\(result.rule.source) → \(result.rule.target) (\(result.rule.status))"
                switch result.outcome {
                case .passed:
                    print("✅ \(declaration)")
                case .failed(let failure):
                    print("❌ \(declaration)")
                    print("   \(failure)")
                case .skipped(let skip):
                    print("⏭️ \(declaration)")
                    print("   \(skip)")
                }
            }
            print()

            print("Passed: \(report.passed.count)  Failed: \(report.failed.count)  Skipped: \(report.skipped.count)")
            print()

            // `isSuccess` requires at least one proven rule — an all-skipped
            // report means nothing was verified and the gate fails closed.
            if report.isSuccess {
                let skippedNote = report.skipped.isEmpty ? "" : " (\(report.skipped.count) skipped)"
                print("Result: \(report.passed.count) redirect rule\(report.passed.count == 1 ? "" : "s") verified ✓\(skippedNote)")
            } else if report.failed.isEmpty {
                print("Result: No rules could be verified — nothing was proven")
                throw ExitCode.failure
            } else {
                print("Result: \(report.failed.count) rule\(report.failed.count == 1 ? "" : "s") failed verification")
                throw ExitCode.failure
            }
        }

        /// Resolves where the `_redirects` file and the deployed output root
        /// live: `Resources/<site>/_redirects` + `Websites/<site>/` under
        /// `--site`; the given path + its parent directory under `--file`
        /// (the fixture escape hatch). The rules-file path is returned as a
        /// standardized, absolute, symlink-resolved path so the existence,
        /// type, readability, and read checks all act on one location —
        /// `resolvingSymlinksInPath` only fully resolves absolute input.
        /// Throws on an unknown site name.
        private func resolveRulesFile() throws -> (path: String, deployedRoot: String) {
            func resolved(_ path: String) -> String {
                URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
            }
            if let site {
                guard let siteName = SiteName(rawValue: site) else {
                    throw ValidationError("Invalid site name: \(site). Valid values: 21-dev, docs-21-dev")
                }
                return (resolved("Resources/\(siteName.rawValue)/_redirects"), siteName.outputDirectory)
            }
            let path = resolved(file ?? "")
            return (path, (path as NSString).deletingLastPathComponent)
        }

        /// Parses `--base-url` as a strict deployment origin: `http`/`https`
        /// scheme and host only — no path beyond "/", query, fragment, or
        /// embedded credentials (which would also leak into printed output).
        /// The verifier replaces the path per probe, so any other component
        /// could only be a mistake measuring a different deployment.
        private func validatedBaseURL() throws -> URL {
            guard let components = URLComponents(string: baseUrl),
                  let scheme = components.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  !(components.host ?? "").isEmpty,
                  components.path.isEmpty || components.path == "/",
                  components.query == nil,
                  components.fragment == nil,
                  components.user == nil,
                  components.password == nil,
                  let url = components.url else {
                // The raw value is not echoed: rejected inputs may carry
                // credentials that must not reach console or CI output.
                throw ValidationError("Invalid --base-url: expected an http(s) deployment origin — no path, query, fragment, or credentials")
            }
            return url
        }
    }
}
