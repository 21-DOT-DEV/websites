//
//  CredentialStoreSymlinkTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import UtilLib

/// Symlinked store paths — links resolve before every check and write
/// (the ssh StrictModes / gpg model), and a dangling link is
/// can't-answer, never absent.
@Suite("Vitals — CredentialStore symlinks")
struct VitalsCredentialStoreSymlinkTests {

    @Test("a symlinked store directory resolves and its target is checked")
    func resolveSymlinkedDir() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let real = dir.appendingPathComponent("real", isDirectory: true)
        let storeURL = real.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "linked"], at: storeURL)
        try chmod(0o700, at: real)
        let link = dir.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        let value = try await CredentialStore.resolve(
            .googleAPIKey,
            fileURL: link.appendingPathComponent("credentials.json"),
            environment: [:],
            keychain: FakeKeychain()
        )
        #expect(value == "linked")
    }

    @Test("a symlinked store file resolves to its target")
    func resolveSymlinkedFile() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let realFile = dir.appendingPathComponent("real-credentials.json")
        try writeStore(["google-api-key": "linked"], at: realFile)
        let linkFile = dir.appendingPathComponent("credentials.json")
        try FileManager.default.createSymbolicLink(at: linkFile, withDestinationURL: realFile)

        let value = try await CredentialStore.resolve(
            .googleAPIKey, fileURL: linkFile, environment: [:], keychain: FakeKeychain()
        )
        #expect(value == "linked")
    }

    @Test("a loose target behind a symlinked directory still refuses")
    func resolveSymlinkedDirLooseTarget() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let real = dir.appendingPathComponent("real", isDirectory: true)
        let storeURL = real.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "linked"], at: storeURL)
        try chmod(0o755, at: real) // the target, not the link, is loose
        let link = dir.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: link.appendingPathComponent("credentials.json"),
                environment: [:],
                keychain: FakeKeychain()
            )
        }
        #expect(error == .insecurePermissions(path: real.path, requiredMode: 0o700))
    }

    @Test("store through a symlinked directory writes the target")
    func storeSymlinkedDir() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let real = dir.appendingPathComponent("real", isDirectory: true)
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        try chmod(0o755, at: real)
        let link = dir.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        try CredentialStore.storeInFile(
            "written", for: .googleAPIKey,
            at: link.appendingPathComponent("credentials.json")
        )
        // The write landed at the canonical path and healed the real dir.
        #expect(try CredentialStore.readStore(
            at: real.appendingPathComponent("credentials.json")
        ) == ["google-api-key": "written"])
        #expect(try mode(of: real) == 0o700)
    }

    @Test("exists and readStore resolve a symlinked store directly")
    func existsReadStoreSymlinked() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let real = dir.appendingPathComponent("real", isDirectory: true)
        let storeURL = real.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "linked"], at: storeURL)
        try chmod(0o700, at: real)
        let link = dir.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        let linkedStore = link.appendingPathComponent("credentials.json")

        // `resolve` canonicalizes before consulting `readStore`; `exists`
        // and direct `readStore` callers pass the link — they must
        // resolve themselves or the lstat-mode check refuses forever.
        #expect(try CredentialStore.readStore(at: linkedStore) == ["google-api-key": "linked"])
        #expect(try await CredentialStore.exists(.googleAPIKey, target: .file, fileURL: linkedStore) == true)
    }

    @Test("a dangling store symlink is can't-answer, never absent")
    func danglingStoreLink() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let link = dir.appendingPathComponent("credentials.json")
        try FileManager.default.createSymbolicLink(
            at: link, withDestinationURL: dir.appendingPathComponent("missing-target")
        )

        // `resolvingSymlinksInPath` returns the link unchanged when the
        // target is missing — "absent" would let delete claim success
        // while the secret waits on an unmounted target, and store's
        // atomic write would replace the link itself.
        #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: link)
        }
        #expect(throws: CredentialError.self) {
            try CredentialStore.deleteFromFile(.googleAPIKey, at: link)
        }
        #expect(throws: CredentialError.self) {
            try CredentialStore.storeInFile("v", for: .googleAPIKey, at: link)
        }
        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey, fileURL: link, environment: [:], keychain: FakeKeychain()
            )
        }
        #expect(error == .storeFailed("\(link.path) is a dangling symlink — its target is missing"))
        // The refused write left the link intact.
        #expect(
            (try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) != nil
        )
    }

    @Test("a dangling link in the store's directory is can't-answer too")
    func danglingStoreDirLink() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let link = dir.appendingPathComponent("link", isDirectory: true)
        try FileManager.default.createSymbolicLink(
            at: link, withDestinationURL: dir.appendingPathComponent("missing-volume")
        )

        // The dangling component is mid-path — the resolved URL still
        // contains it, and "absent" would be the same lie.
        #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: link.appendingPathComponent("credentials.json"))
        }
    }
}
