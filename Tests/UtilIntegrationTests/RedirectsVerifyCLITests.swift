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
}
