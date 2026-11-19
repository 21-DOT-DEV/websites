//
//  RedirectsVerifyCLITests.swift
//  UtilitiesCLITests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import Subprocess
import System

@Suite("Redirects Verify CLI Tests")
struct RedirectsVerifyCLITests {

    /// An argument-validation failure exits non-zero with the reason on stderr.
    @Test("redirects verify requires --site or --file")
    func requiresSiteOrFile() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("--site or --file"))
    }

    @Test("redirects verify rejects --site and --file together")
    func rejectsSiteAndFileTogether() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--site", "21-dev",
                        "--file", "/tmp/whatever", "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("Cannot specify both"))
    }

    @Test("redirects verify rejects an unknown site")
    func rejectsUnknownSite() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--site", "bogus",
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("Invalid site name"))
    }

    @Test("redirects verify rejects a missing rules file")
    func rejectsMissingFile() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify",
                        "--file", "/nonexistent/dir/_redirects",
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("does not exist, is not readable, or is not a regular file"))
    }

    @Test("redirects verify rejects a missing rules file under --site")
    func rejectsMissingSiteFile() async throws {
        // --site resolves Resources/<site>/_redirects relative to the working
        // directory; an empty one puts the file check on the missing path.
        let empty = FileManager.default.temporaryDirectory
            .appendingPathComponent("redirects-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: empty.path) }

        let result = try await Subprocess.run(
            .path(FilePath("\(FileManager.default.currentDirectoryPath)/.build/debug/util")),
            arguments: ["redirects", "verify", "--site", "21-dev",
                        "--base-url", "http://127.0.0.1:9"],
            workingDirectory: FilePath(empty.path),
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("does not exist, is not readable, or is not a regular file"))
    }

    @Test("redirects verify rejects a --base-url carrying a path, query, or fragment")
    func rejectsNonOriginBaseURL() async throws {
        let fixture = try makeRulesFile("docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        for baseURL in ["https://example.com/some/path",
                        "https://example.com/?q=1",
                        "https://example.com/#frag"] {
            let result = try await Subprocess.run(
                .path(FilePath(".build/debug/util")),
                arguments: ["redirects", "verify", "--file", fixture,
                            "--base-url", baseURL],
                output: .string(limit: 4096),
                error: .string(limit: 4096)
            )

            guard case .exited(let code) = result.terminationStatus else {
                Issue.record("Unexpected termination")
                return
            }
            #expect(code != 0)
            #expect((result.standardError ?? "").contains("Invalid --base-url"))
        }
    }

    @Test("redirects verify rejects a FIFO — a blocking read would hang the gate",
          .timeLimit(.minutes(1)))
    func rejectsNonRegularFile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("redirects-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: directory.path) }
        let fifo = directory.appendingPathComponent("_redirects").path
        guard mkfifo(fifo, 0o644) == 0 else {
            Issue.record("could not create FIFO fixture")
            return
        }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fifo,
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("regular file"))
    }

    @Test("redirects verify accepts a symlinked _redirects — file or directory link")
    func acceptsSymlinkedRulesFile() async throws {
        // The gate resolves symlinks before the regular-file check — a link
        // at the file itself or at a directory component (e.g. a linked
        // Resources/) must reach the verifier, not the rejection path.
        // `dirlink/_redirects` is the discriminating case: NSString's
        // resolvingSymlinksInPath leaves a relative path unresolved once an
        // intermediate component is a link, so the final symlink reports as
        // .typeSymbolicLink — the path the fix exists to handle.
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("redirects-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            atPath: "\(directory.path)/realdir", withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: directory.path) }
        try "/docs https://docs.21.dev/documentation/ 301"
            .write(toFile: "\(directory.path)/realdir/realfile", atomically: true, encoding: .utf8)
        try FileManager.default.createSymbolicLink(
            atPath: "\(directory.path)/realdir/_redirects", withDestinationPath: "realfile")
        try FileManager.default.createSymbolicLink(
            atPath: "\(directory.path)/filelink", withDestinationPath: "realdir/_redirects")
        try FileManager.default.createSymbolicLink(
            atPath: "\(directory.path)/dirlink", withDestinationPath: "realdir")

        let util = FilePath("\(FileManager.default.currentDirectoryPath)/.build/debug/util")
        for (arg, workingDir) in [("\(directory.path)/filelink", nil as FilePath?),
                                  ("dirlink/_redirects", FilePath(directory.path))] {
            let result = try await Subprocess.run(
                .path(util),
                arguments: ["redirects", "verify", "--file", arg,
                            "--base-url", "http://127.0.0.1:9"],
                workingDirectory: workingDir,
                output: .string(limit: 8192),
                error: .string(limit: 4096)
            )

            guard case .exited(let code) = result.terminationStatus else {
                Issue.record("Unexpected termination")
                return
            }
            // Validation must pass — the link resolves to a regular file. The
            // unreachable probe still fails the run, but on the rule.
            #expect(code != 0)
            #expect(!(result.standardError ?? "").contains("regular file"))
            #expect((result.standardOutput ?? "").contains("Verifying redirects on"))
        }
    }

    @Test("redirects verify rejects a credentialed --base-url without echoing it")
    func rejectsCredentialBaseURLWithoutEcho() async throws {
        let fixture = try makeRulesFile("docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", "https://user:pass@example.com"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        // The rejected value must not reach output — it may carry credentials.
        #expect(!(result.standardError ?? "").contains("user:pass"))
        #expect(!(result.standardOutput ?? "").contains("user:pass"))
        #expect((result.standardError ?? "").contains("Invalid --base-url"))
    }

    @Test("redirects verify rejects an empty-host --base-url")
    func rejectsEmptyHostBaseURL() async throws {
        let fixture = try makeRulesFile("docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", "https://"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardError ?? "").contains("Invalid --base-url"))
    }

    @Test("redirects verify fails closed on a zero-rule file")
    func zeroRuleFileFailsClosed() async throws {
        let fixture = try makeRulesFile("# only comments\n\n# nothing else\n")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardOutput ?? "").contains("nothing was verified"))
    }

    @Test("redirects verify fails closed when every rule skips — nothing proven")
    func allSkippedFileFailsClosed() async throws {
        // A wildcard 200 with no deployed file matching its target skips —
        // an all-skipped report must not pass the gate.
        let fixture = try makeRulesFile("/.well-known/* /well-known/:splat 200\n")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        #expect((result.standardOutput ?? "").contains("nothing was proven"))
    }

    @Test("redirects verify names a rule that fails probing — the gate branch")
    func reportsPerRuleFailure() async throws {
        // An unreachable deployment turns the probe into a transport error:
        // the rule fails, its ❌ line names the declaration, and the exit
        // is non-zero — the behavior that makes this a deploy gate.
        let fixture = try makeRulesFile("/docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("❌ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("probe request failed"))
        #expect(output.contains("1 rule failed verification"))
        // --file derives the deployed root from the rules file's parent —
        // the printed root must be that (resolved, absolute) directory,
        // not "."; the fixture dir's unique name must appear on the line.
        let fixtureDir = ((fixture as NSString).deletingLastPathComponent as NSString).lastPathComponent
        #expect(output.contains("Deployed root: /"))
        #expect(output.contains(fixtureDir))
    }

    // MARK: - Loopback edge probes (FR-002..FR-006)

    @Test("redirects verify exits 0 when the edge answers every rule as declared",
          .timeLimit(.minutes(1)))
    func cleanDeploymentPasses() async throws {
        let fixture = try makeRulesFile("/docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 301, location: "https://docs.21.dev/documentation/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("1 redirect rule verified ✓"))
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" } == ["HEAD /docs"])
    }

    @Test("redirects verify proves a wildcard rule through the probe token",
          .timeLimit(.minutes(1)))
    func wildcardProbePasses() async throws {
        // The emulator expands :splat in the Location itself — the pass is
        // only possible when the verifier's probed request path matches the
        // same wildcard semantics the emulator applies.
        let fixture = try makeRulesFile("/p256k/* /documentation/p256k/:splat/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/p256k/*", status: 301, location: "/documentation/p256k/:splat/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("Probe token: redirects-verify-probe"))
        #expect(output.contains("✅ /p256k/* → /documentation/p256k/:splat/ (301)"))
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" }
                == ["HEAD /p256k/redirects-verify-probe"])
    }

    @Test("redirects verify proves a 200 rewrite through a real deployed target",
          .timeLimit(.minutes(1)))
    func rewriteProbePasses() async throws {
        // A 200 wildcard is only provable through a deployed file its target
        // expands to, on a deployment that can't SPA-fallback — the fixture
        // carries both well-known/nostr.json and 404.html.
        let fixture = try makeDeployment(
            "/.well-known/* /well-known/:splat 200\n",
            files: ["well-known/nostr.json": "{}", "404.html": "<html></html>"])
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/.well-known/*", status: 200),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        #expect((result.standardOutput ?? "").contains("✅ /.well-known/* → /well-known/:splat (200)"))
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" }
                == ["HEAD /.well-known/nostr.json"])
    }

    @Test("redirects verify fails naming the rule on a status mismatch",
          .timeLimit(.minutes(1)))
    func reportsStatusMismatch() async throws {
        let fixture = try makeRulesFile("/docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 404),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("❌ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("expected status 301, got 404"))
        #expect(output.contains("1 rule failed verification"))
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" } == ["HEAD /docs"])
    }

    @Test("redirects verify fails naming the rule on a Location mismatch",
          .timeLimit(.minutes(1)))
    func reportsLocationMismatch() async throws {
        let fixture = try makeRulesFile("/docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 301, location: "https://docs.21.dev/wrong/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("❌ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("expected Location \"https://docs.21.dev/documentation/\", got \"https://docs.21.dev/wrong/\""))
        #expect(output.contains("1 rule failed verification"))
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" } == ["HEAD /docs"])
    }

    @Test("redirects verify retries with GET when HEAD is refused",
          .timeLimit(.minutes(1)))
    func getFallbackPasses() async throws {
        let fixture = try makeRulesFile("/docs https://docs.21.dev/documentation/ 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 301, location: "https://docs.21.dev/documentation/", headStatus: 405),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        #expect((result.standardOutput ?? "").contains("✅ /docs → https://docs.21.dev/documentation/ (301)"))
        // The wire sequence proves the retry actually happened — a pass
        // alone can't tell a refused-HEAD fallback from a direct HEAD hit.
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" }
                == ["HEAD /docs", "GET /docs"])
    }

    @Test("redirects verify refuses an edge-looping rule before any request",
          .timeLimit(.minutes(1)))
    func edgeRefusalSendsNoRequest() async throws {
        // A target looping through its own source is refused at the edge —
        // the rule fails with the refusal named and no probe may fire.
        let fixture = try makeRulesFile("/loop /loop 301")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/loop", status: 301, location: "/loop"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("❌ /loop → /loop (301)"))
        #expect(output.contains("edge would not apply this rule: target loops back through the rule's own source"))
        #expect(edge.recordedRequests.isEmpty)
    }

    @Test("redirects verify reports skips alongside passes without failing",
          .timeLimit(.minutes(1)))
    func mixedSkipPasses() async throws {
        // The 200 wildcard's target expands to no deployed file — a stated
        // skip that must not fail the run while the literal rule passes.
        let fixture = try makeRulesFile("/docs https://docs.21.dev/documentation/ 301\n/old/* /missing/:splat 200\n")
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 301, location: "https://docs.21.dev/documentation/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("⏭️ /old/* → /missing/:splat (200)"))
        #expect(output.contains("no deployed file matches the rule's target"))
        #expect(output.contains("Skipped: 1"))
        // The skipped wildcard must never be probed.
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" } == ["HEAD /docs"])
    }

    @Test("redirects verify proves every rule in the real 21-dev file against the emulated edge",
          .timeLimit(.minutes(1)))
    func realSiteFile21Dev() async throws {
        // Mirrors Resources/21-dev/_redirects rule-for-rule: an emulator entry
        // the file can't express is a coverage gap, and an added rule the
        // mirror lacks fails loudly (the emulator 404s unmatched probes).
        let edge = RedirectEdgeEmulator(rules: [
            .init("/.well-known/*", status: 200),
            .init("/security.txt", status: 301, location: "/.well-known/security.txt"),
            .init("/docs", status: 301, location: "https://docs.21.dev/documentation/"),
            .init("/api", status: 301, location: "https://docs.21.dev/documentation/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--site", "21-dev",
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅ /security.txt → /.well-known/security.txt (301)"))
        #expect(output.contains("✅ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("✅ /api → https://docs.21.dev/documentation/ (301)"))
        #expect(!output.contains("❌"))
        // The /.well-known rewrite passes where Websites/21-dev exists and
        // skips where it doesn't — only the exit code is stable across both.
        let requests = edge.recordedRequests.map { "\($0.method) \($0.path)" }
        #expect(requests.contains("HEAD /security.txt"))
        #expect(requests.contains("HEAD /docs"))
        #expect(requests.contains("HEAD /api"))
    }

    @Test("redirects verify proves every rule in the real docs-21-dev file against the emulated edge",
          .timeLimit(.minutes(1)))
    func realSiteFileDocs21Dev() async throws {
        // Mirrors Resources/docs-21-dev/_redirects rule-for-rule — literal
        // and 3xx wildcard rules all probe and pass on any machine; the
        // /.well-known rewrite probes only where Websites/docs-21-dev exists
        // (the docs site assembles in CI — there is no local equivalent).
        // The 0.25.x symbol-removal block is literal-only: ':'+letter inside
        // a source is a live :placeholder, so dead method URLs that would
        // match live sibling pages are left to 404.
        let edge = RedirectEdgeEmulator(rules: [
            .init("/.well-known/*", status: 200),
            .init("/security.txt", status: 301, location: "/.well-known/security.txt"),
            .init("/", status: 301, location: "/documentation/"),
            .init("/index.html", status: 301, location: "/documentation/"),
            .init("/p256k", status: 301, location: "/documentation/p256k/"),
            .init("/p256k/", status: 301, location: "/documentation/p256k/"),
            .init("/p256k/index.html", status: 301, location: "/documentation/p256k/"),
            .init("/p256k/*/index.html", status: 301, location: "/documentation/p256k/:splat/"),
            .init("/p256k/*/", status: 301, location: "/documentation/p256k/:splat/"),
            .init("/p256k/*", status: 301, location: "/documentation/p256k/:splat/"),
            .init("/zkp", status: 301, location: "/documentation/zkp/"),
            .init("/zkp/", status: 301, location: "/documentation/zkp/"),
            .init("/zkp/index.html", status: 301, location: "/documentation/zkp/"),
            .init("/zkp/*/index.html", status: 301, location: "/documentation/zkp/:splat/"),
            .init("/zkp/*/", status: 301, location: "/documentation/zkp/:splat/"),
            .init("/zkp/*", status: 301, location: "/documentation/zkp/:splat/"),
            .init("/documentation/p256k/p256k/musig/aggregatesignatures(_:)", status: 301, location: "/documentation/p256k/p256k/musig/"),
            .init("/documentation/p256k/p256k/musig/aggregatesignatures(_:)/", status: 301, location: "/documentation/p256k/p256k/musig/"),
            .init("/documentation/p256k/p256k/musig/aggregatesignatures(_:)/index.html", status: 301, location: "/documentation/p256k/p256k/musig/"),
            .init("/documentation/p256k/p256k/musig/xonlykey/cache", status: 301, location: "/documentation/p256k/p256k/musig/xonlykey/"),
            .init("/documentation/p256k/p256k/musig/xonlykey/cache/", status: 301, location: "/documentation/p256k/p256k/musig/xonlykey/"),
            .init("/documentation/p256k/p256k/musig/xonlykey/cache/index.html", status: 301, location: "/documentation/p256k/p256k/musig/xonlykey/"),
            .init("/documentation/p256k/p256k/schnorr/xonlykey/cache", status: 301, location: "/documentation/p256k/p256k/schnorr/xonlykey/"),
            .init("/documentation/p256k/p256k/schnorr/xonlykey/cache/", status: 301, location: "/documentation/p256k/p256k/schnorr/xonlykey/"),
            .init("/documentation/p256k/p256k/schnorr/xonlykey/cache/index.html", status: 301, location: "/documentation/p256k/p256k/schnorr/xonlykey/"),
            .init("/documentation/p256k/swift/array", status: 302, location: "/documentation/p256k/swift/"),
            .init("/documentation/p256k/swift/array/", status: 302, location: "/documentation/p256k/swift/"),
            .init("/documentation/p256k/swift/array/index.html", status: 302, location: "/documentation/p256k/swift/"),
            .init("/documentation/p256k/swift/arrayslice", status: 302, location: "/documentation/p256k/swift/"),
            .init("/documentation/p256k/swift/arrayslice/", status: 302, location: "/documentation/p256k/swift/"),
            .init("/documentation/p256k/swift/arrayslice/index.html", status: 302, location: "/documentation/p256k/swift/"),
            .init("/*/index.html", status: 301, location: "/:splat/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--site", "docs-21-dev",
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 16384),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅ /security.txt → /.well-known/security.txt (301)"))
        #expect(output.contains("✅ / → /documentation/ (301)"))
        #expect(output.contains("✅ /p256k/* → /documentation/p256k/:splat/ (301)"))
        #expect(output.contains("✅ /*/index.html → /:splat/ (301)"))
        #expect(!output.contains("❌"))

        // Exact wire evidence: every rule probes once, in file order, with
        // the token substituted into each wildcard source — except the
        // /.well-known rewrite, which probes through a real deployed file
        // and therefore only fires where Websites/docs-21-dev exists.
        let deterministicProbes: [String] = [
            "HEAD /security.txt",
            "HEAD /", "HEAD /index.html",
            "HEAD /p256k", "HEAD /p256k/", "HEAD /p256k/index.html",
            "HEAD /p256k/redirects-verify-probe/index.html",
            "HEAD /p256k/redirects-verify-probe/",
            "HEAD /p256k/redirects-verify-probe",
            "HEAD /zkp", "HEAD /zkp/", "HEAD /zkp/index.html",
            "HEAD /zkp/redirects-verify-probe/index.html",
            "HEAD /zkp/redirects-verify-probe/",
            "HEAD /zkp/redirects-verify-probe",
            "HEAD /documentation/p256k/p256k/musig/aggregatesignatures(_:)",
            "HEAD /documentation/p256k/p256k/musig/aggregatesignatures(_:)/",
            "HEAD /documentation/p256k/p256k/musig/aggregatesignatures(_:)/index.html",
            "HEAD /documentation/p256k/p256k/musig/xonlykey/cache",
            "HEAD /documentation/p256k/p256k/musig/xonlykey/cache/",
            "HEAD /documentation/p256k/p256k/musig/xonlykey/cache/index.html",
            "HEAD /documentation/p256k/p256k/schnorr/xonlykey/cache",
            "HEAD /documentation/p256k/p256k/schnorr/xonlykey/cache/",
            "HEAD /documentation/p256k/p256k/schnorr/xonlykey/cache/index.html",
            "HEAD /documentation/p256k/swift/array",
            "HEAD /documentation/p256k/swift/array/",
            "HEAD /documentation/p256k/swift/array/index.html",
            "HEAD /documentation/p256k/swift/arrayslice",
            "HEAD /documentation/p256k/swift/arrayslice/",
            "HEAD /documentation/p256k/swift/arrayslice/index.html",
            "HEAD /redirects-verify-probe/index.html",
        ]

        let requests = edge.recordedRequests.map { "\($0.method) \($0.path)" }
        if requests.first == "HEAD /.well-known/security.txt" {
            // CI: the docs site is built, well-known/security.txt is deployed,
            // and the rewrite is probed through it — all 32 rules pass.
            #expect(requests == ["HEAD /.well-known/security.txt"] + deterministicProbes)
            #expect(!output.contains("⏭️"))
            #expect(output.contains("32 redirect rules verified ✓"))
        } else {
            // No built docs site here — the rewrite is the file's single
            // honest skip (no deployed target to prove it through).
            #expect(requests == deterministicProbes)
            #expect(output.contains("⏭️ /.well-known/* → /well-known/:splat (200)"))
            #expect(output.contains("31 redirect rules verified ✓ (1 skipped)"))
        }
    }

    @Test("redirects verify fails a malformed line even when its rules pass",
          .timeLimit(.minutes(1)))
    func malformedLineFails() async throws {
        // Lines 2-3 can never reach the edge — the only honest report is to
        // name them; the passing rule still probes normally.
        let fixture = try makeRulesFile("""
        /docs https://docs.21.dev/documentation/ 301
        /a /b extra fields
        /docs /elsewhere 302
        """)
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 301, location: "https://docs.21.dev/documentation/"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("❌ line 2: /a /b extra fields"))
        #expect(output.contains("❌ line 3: /docs /elsewhere 302"))
        #expect(output.contains("duplicate of an earlier rule"))
        #expect(output.contains("Malformed: 2"))
        #expect(output.contains("invalid declarations"))
        // Malformed lines add failures; they don't preempt verification.
        #expect(edge.recordedRequests.map { "\($0.method) \($0.path)" } == ["HEAD /docs"])
    }

    @Test("redirects verify honors the edge's comment and numeric syntax",
          .timeLimit(.minutes(1)))
    func edgeSyntaxIsVerified() async throws {
        // `/a /b 301 # note` and `/c /d 301.0` are live rules at the edge —
        // the gate must verify them, not fail them as malformed.
        let fixture = try makeRulesFile("""
        /docs https://docs.21.dev/documentation/ 301 # canonical home
        /old /new 301.0
        /frag /here#section 301
        """)
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }
        let edge = RedirectEdgeEmulator(rules: [
            .init("/docs", status: 301, location: "https://docs.21.dev/documentation/"),
            .init("/old", status: 301, location: "/new"),
            .init("/frag", status: 301, location: "/here#section"),
        ])
        let baseURL = try await edge.start()
        defer { edge.cancel() }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", baseURL.absoluteString],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("✅ /docs → https://docs.21.dev/documentation/ (301)"))
        #expect(output.contains("✅ /old → /new (301)"))
        #expect(output.contains("✅ /frag → /here#section (301)"))
        #expect(!output.contains("Malformed"))
        #expect(edge.recordedRequests.map(\.path) == ["/docs", "/old", "/frag"])
    }

    @Test("redirects verify names malformed lines even when no rules parse",
          .timeLimit(.minutes(1)))
    func malformedOnlyFileFails() async throws {
        // A file of only malformed lines must not collapse to the
        // "nothing was verified" message — its lines are failures.
        let fixture = try makeRulesFile("""
        # notes
        /a /b extra fields
        /lonely
        """)
        defer { try? FileManager.default.removeItem(atPath: (fixture as NSString).deletingLastPathComponent) }

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["redirects", "verify", "--file", fixture,
                        "--base-url", "http://127.0.0.1:9"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
        let output = result.standardOutput ?? ""
        #expect(output.contains("❌ line 2: /a /b extra fields"))
        #expect(output.contains("❌ line 3: /lonely"))
        #expect(output.contains("Malformed: 2"))
        #expect(!output.contains("No rules parsed"))
    }

    /// Writes `_redirects` contents into a fresh temp directory and returns
    /// the file's path — the parent directory doubles as the deployed root.
    private func makeRulesFile(_ contents: String) throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("redirects-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("_redirects")
        try contents.write(to: file, atomically: true, encoding: .utf8)
        return file.path
    }

    /// Creates a fresh temp directory holding `_redirects` plus any deployed
    /// files — the directory doubles as the deployed root under `--file`, so
    /// `files` are written at site-relative paths (`well-known/nostr.json`,
    /// `404.html`) for real-target and SPA-fallback checks.
    private func makeDeployment(_ redirects: String, files: [String: String]) throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("redirects-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try redirects.write(to: directory.appendingPathComponent("_redirects"), atomically: true, encoding: .utf8)
        for (name, contents) in files {
            let path = directory.appendingPathComponent(name)
            try FileManager.default.createDirectory(
                at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.write(to: path, atomically: true, encoding: .utf8)
        }
        return directory.appendingPathComponent("_redirects").path
    }
}
