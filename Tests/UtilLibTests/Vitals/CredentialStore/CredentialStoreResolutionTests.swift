//
//  CredentialStoreResolutionTests.swift
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

/// `CredentialStore.resolve` — the FR-005 layered chain: explicit file →
/// environment → Keychain → file store, with the encrypted store
/// outranking the plaintext one (spec 009's re-derived precedence — the
/// `security(1)` backend made Keychain reads prompt-free, retiring the
/// file-first rationale). The Keychain layer is proven through the
/// injected `FakeKeychain`.
@Suite("Vitals — CredentialStore resolution")
struct VitalsCredentialStoreResolutionTests {

    @Test("explicit --file beats environment, keychain, and file store")
    func explicitFileWins() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "file-store"], at: storeURL)

        let secretFile = dir.appendingPathComponent("secret.txt")
        try "explicit\n".write(to: secretFile, atomically: true, encoding: .utf8)

        let fake = FakeKeychain()
        try await fake.store("keychain", for: .googleAPIKey)

        let value = try await CredentialStore.resolve(
            .googleAPIKey,
            explicitFile: secretFile.path,
            fileURL: storeURL,
            environment: ["GOOGLE_API_KEY": "env"],
            keychain: fake
        )
        #expect(value == "explicit")
    }

    @Test("environment beats keychain and file store")
    func environmentWins() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "file-store"], at: storeURL)

        let fake = FakeKeychain()
        try await fake.store("keychain", for: .googleAPIKey)

        let value = try await CredentialStore.resolve(
            .googleAPIKey,
            fileURL: storeURL,
            environment: ["GOOGLE_API_KEY": "env"],
            keychain: fake
        )
        #expect(value == "env")
    }

    @Test("keychain beats file store — the encrypted store outranks plaintext")
    func keychainBeatsFile() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "file-store"], at: storeURL)

        let fake = FakeKeychain()
        try await fake.store("keychain", for: .googleAPIKey)

        let value = try await CredentialStore.resolve(
            .googleAPIKey,
            fileURL: storeURL,
            environment: [:],
            keychain: fake
        )
        #expect(value == "keychain")
    }

    @Test("file store resolves when keychain holds nothing")
    func fileWhenKeychainEmpty() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "file-store"], at: storeURL)

        let value = try await CredentialStore.resolve(
            .googleAPIKey,
            fileURL: storeURL,
            environment: [:],
            keychain: FakeKeychain()
        )
        #expect(value == "file-store")
    }

    @Test("keychain cancellation propagates rather than degrading")
    func keychainCancellationPropagates() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "file-store"], at: storeURL)

        let fake = FakeKeychain()
        await fake.setFailure(CancellationError())

        // A cancelled task must surface as cancelled — never silently
        // re-route to the file layer and return a secret.
        await #expect(throws: CancellationError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey, fileURL: storeURL, environment: [:], keychain: fake
            )
        }
    }

    @Test("a keychain that cannot answer degrades to the file layer")
    func keychainErrorDegrades() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "file-store"], at: storeURL)

        let fake = FakeKeychain()
        await fake.setFailure(CredentialError.storeFailed("keychain locked"))

        let value = try await CredentialStore.resolve(
            .googleAPIKey,
            fileURL: storeURL,
            environment: [:],
            keychain: fake
        )
        #expect(value == "file-store")
    }

    @Test("empty env var does not count as a credential")
    func emptyEnvSkipped() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: ["GOOGLE_API_KEY": ""],
                keychain: FakeKeychain()
            )
        }
        #expect(error == .notFound(.googleAPIKey, checkedFile: storeURL))
    }

    @Test("empty stored value does not count as a credential")
    func emptyStoredSkipped() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": ""], at: storeURL)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: FakeKeychain()
            )
        }
        #expect(error == .notFound(.googleAPIKey, checkedFile: storeURL))
    }

    @Test("missing credential names the provisioning path (SC-004)")
    func notFoundNamesProvisioning() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeURL = dir.appendingPathComponent("credentials.json")
        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .cloudflareAPIToken,
                fileURL: storeURL,
                environment: [:],
                keychain: FakeKeychain()
            )
        }
        #expect(error == .notFound(.cloudflareAPIToken, checkedFile: storeURL))
        #expect(error?.errorDescription?.contains("credentials store") == true)
        #expect(error?.errorDescription?.contains("CLOUDFLARE_API_TOKEN") == true)
        // The message names the store actually checked, not the default path.
        #expect(error?.errorDescription?.contains(storeURL.path) == true)
    }
}
