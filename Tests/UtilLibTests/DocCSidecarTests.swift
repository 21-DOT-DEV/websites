//
//  DocCSidecarTests.swift
//  websitesPackageTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

// MARK: - Fixtures

private enum SidecarFixture {
    static let articleJSON = """
    {
      "metadata": {
        "title": "Choosing Between P256K and ZKP",
        "role": "article",
        "roleHeading": "Article",
        "modules": [{ "name": "ZKP" }]
      },
      "abstract": [
        { "type": "text", "text": "Pick the right product for the job. " },
        { "type": "text", "text": "P256K covers signing; ZKP adds proofs." }
      ],
      "identifier": {
        "url": "doc://ZKP/documentation/ZKP/ChoosingP256KvsZKP",
        "interfaceLanguage": "swift"
      }
    }
    """

    static let symbolJSON = """
    {
      "metadata": {
        "title": "PrivateKey",
        "role": "symbol",
        "symbolKind": "struct",
        "modules": [{ "name": "P256K" }]
      },
      "abstract": [
        { "type": "text", "text": "A secp256k1 private key." }
      ],
      "identifier": {
        "url": "doc://P256K/documentation/P256K/Signing/PrivateKey",
        "interfaceLanguage": "swift"
      }
    }
    """

    static let collectionJSON = """
    {
      "metadata": {
        "title": "P256K",
        "role": "collection",
        "modules": [{ "name": "P256K" }]
      },
      "identifier": {
        "url": "doc://P256K/documentation/P256K"
      }
    }
    """

    static let landingJSON = """
    {
      "metadata": {
        "title": "Documentation",
        "role": "landingPage"
      }
    }
    """

    static let unknownRoleJSON = """
    {
      "metadata": {
        "title": "Mystery",
        "role": "futureRole42"
      }
    }
    """

    static let missingRoleJSON = """
    {
      "metadata": {
        "title": "No role here"
      }
    }
    """

    static let malformedJSON = """
    { this is not valid JSON
    """
}

// MARK: - DocCSidecar Decoding

@Suite("DocCSidecar Decoding")
struct DocCSidecarDecodingTests {

    private func decode(_ json: String) throws -> DocCSidecar {
        try JSONDecoder().decode(DocCSidecar.self, from: Data(json.utf8))
    }

    @Test("Decodes article sidecar with title, role, abstract, module")
    func decodeArticle() throws {
        let sidecar = try decode(SidecarFixture.articleJSON)
        #expect(sidecar.metadata.title == "Choosing Between P256K and ZKP")
        #expect(sidecar.semanticRole == .article)
        #expect(sidecar.moduleName == "ZKP")
        #expect(
            sidecar.concatenatedAbstract
                == "Pick the right product for the job. P256K covers signing; ZKP adds proofs."
        )
        #expect(sidecar.identifier?.url == "doc://ZKP/documentation/ZKP/ChoosingP256KvsZKP")
    }

    @Test("Decodes symbol sidecar with symbolKind")
    func decodeSymbol() throws {
        let sidecar = try decode(SidecarFixture.symbolJSON)
        #expect(sidecar.metadata.title == "PrivateKey")
        #expect(sidecar.semanticRole == .symbol)
        #expect(sidecar.metadata.symbolKind == "struct")
        #expect(sidecar.moduleName == "P256K")
        #expect(sidecar.concatenatedAbstract == "A secp256k1 private key.")
    }

    @Test("Maps role 'collection' to .collection")
    func decodeCollection() throws {
        let sidecar = try decode(SidecarFixture.collectionJSON)
        #expect(sidecar.semanticRole == .collection)
        #expect(sidecar.concatenatedAbstract == nil)
    }

    @Test("Maps role 'collectionGroup' to .collection")
    func decodeCollectionGroup() throws {
        let json = SidecarFixture.collectionJSON
            .replacingOccurrences(of: "\"role\": \"collection\"", with: "\"role\": \"collectionGroup\"")
        let sidecar = try decode(json)
        #expect(sidecar.semanticRole == .collection)
    }

    @Test("Maps role 'landingPage' to .landingPage")
    func decodeLandingPage() throws {
        let sidecar = try decode(SidecarFixture.landingJSON)
        #expect(sidecar.semanticRole == .landingPage)
    }

    @Test("Unknown role surfaces as .other(role)")
    func decodeUnknownRole() throws {
        let sidecar = try decode(SidecarFixture.unknownRoleJSON)
        #expect(sidecar.semanticRole == .other("futureRole42"))
    }

    @Test("Missing role becomes .unknown")
    func decodeMissingRole() throws {
        let sidecar = try decode(SidecarFixture.missingRoleJSON)
        #expect(sidecar.semanticRole == .unknown)
        #expect(sidecar.metadata.title == "No role here")
    }

    @Test("concatenatedAbstract is nil when abstract is missing")
    func emptyAbstract() throws {
        let sidecar = try decode(SidecarFixture.collectionJSON)
        #expect(sidecar.concatenatedAbstract == nil)
    }

    @Test("Ignores unknown top-level fields without throwing")
    func ignoresUnknownFields() throws {
        let json = """
        {
          "metadata": { "title": "X", "role": "article", "platforms": [] },
          "abstract": [],
          "identifier": { "url": "doc://X/documentation/X" },
          "primaryContentSections": [{ "kind": "content", "content": [] }],
          "topicSections": [],
          "schemaVersion": { "major": 0, "minor": 3, "patch": 0 }
        }
        """
        let sidecar = try decode(json)
        #expect(sidecar.metadata.title == "X")
        #expect(sidecar.concatenatedAbstract == nil)
    }
}

// MARK: - DocCSidecarLoader Path Derivation

@Suite("DocCSidecarLoader Path Derivation")
struct DocCSidecarLoaderPathTests {

    @Test("Derives sidecar path from index.html")
    func deriveFromIndex() {
        let path = DocCSidecarLoader.deriveSidecarRelativePath(
            from: "documentation/p256k/p256k/context/index.html"
        )
        #expect(path == "data/documentation/p256k/p256k/context.json")
    }

    @Test("Derives sidecar path from .html (no index)")
    func deriveFromHTML() {
        let path = DocCSidecarLoader.deriveSidecarRelativePath(
            from: "documentation/p256k/p256k/signing.html"
        )
        #expect(path == "data/documentation/p256k/p256k/signing.json")
    }

    @Test("Module-root index.html maps to module-named sidecar")
    func deriveModuleRoot() {
        let path = DocCSidecarLoader.deriveSidecarRelativePath(
            from: "documentation/p256k/index.html"
        )
        #expect(path == "data/documentation/p256k.json")
    }

    @Test("Top-level documentation/index.html maps to data/documentation.json")
    func deriveTopLevel() {
        let path = DocCSidecarLoader.deriveSidecarRelativePath(
            from: "documentation/index.html"
        )
        #expect(path == "data/documentation.json")
    }
}

// MARK: - DocCSidecarLoader Disk Loading

@Suite("DocCSidecarLoader Disk Loading")
struct DocCSidecarLoaderDiskTests {

    /// Creates a fresh temp directory and writes the given (relativePath →
    /// sidecar JSON) entries. Returns the temp directory.
    private func makeTempDocsRoot(
        files: [String: String],
        function: String = #function
    ) throws -> URL {
        let tempBase = FileManager.default.temporaryDirectory
            .appendingPathComponent("DocCSidecarLoaderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempBase, withIntermediateDirectories: true)

        for (relPath, contents) in files {
            let fileURL = tempBase.appendingPathComponent(relPath)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return tempBase
    }

    @Test("load() returns decoded sidecar for an article page")
    func loadArticle() throws {
        let root = try makeTempDocsRoot(files: [
            "data/documentation/zkp/choosingp256kvszkp.json": SidecarFixture.articleJSON
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let sidecar = try DocCSidecarLoader.load(
            relativePath: "documentation/zkp/choosingp256kvszkp/index.html",
            in: root.path
        )
        #expect(sidecar.semanticRole == .article)
        #expect(sidecar.metadata.title == "Choosing Between P256K and ZKP")
    }

    @Test("load() throws fileNotFound for missing sidecar")
    func loadMissingThrows() throws {
        let root = try makeTempDocsRoot(files: [:])
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(throws: DocCSidecarLoader.LoadError.self) {
            _ = try DocCSidecarLoader.load(
                relativePath: "documentation/p256k/index.html",
                in: root.path
            )
        }
    }

    @Test("load() throws invalidJSON for malformed sidecar")
    func loadMalformedThrows() throws {
        let root = try makeTempDocsRoot(files: [
            "data/documentation/p256k.json": SidecarFixture.malformedJSON
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(throws: DocCSidecarLoader.LoadError.self) {
            _ = try DocCSidecarLoader.load(
                relativePath: "documentation/p256k/index.html",
                in: root.path
            )
        }
    }

    @Test("loadIfPresent returns .missing when sidecar absent")
    func tolerantMissing() throws {
        let root = try makeTempDocsRoot(files: [:])
        defer { try? FileManager.default.removeItem(at: root) }

        let outcome = DocCSidecarLoader.loadIfPresent(
            relativePath: "documentation/index.html",
            in: root.path
        )
        switch outcome {
        case .missing:
            break
        default:
            Issue.record("Expected .missing for absent sidecar, got: \(outcome)")
        }
    }

    @Test("loadIfPresent returns .loaded for valid sidecar")
    func tolerantLoaded() throws {
        let root = try makeTempDocsRoot(files: [
            "data/documentation/p256k/p256k/signing/privatekey.json": SidecarFixture.symbolJSON
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let outcome = DocCSidecarLoader.loadIfPresent(
            relativePath: "documentation/p256k/p256k/signing/privatekey/index.html",
            in: root.path
        )
        switch outcome {
        case .loaded(let sidecar):
            #expect(sidecar.semanticRole == .symbol)
            #expect(sidecar.metadata.title == "PrivateKey")
        default:
            Issue.record("Expected .loaded, got: \(outcome)")
        }
    }

    @Test("loadIfPresent returns .failed for malformed sidecar")
    func tolerantFailed() throws {
        let root = try makeTempDocsRoot(files: [
            "data/documentation/zkp.json": SidecarFixture.malformedJSON
        ])
        defer { try? FileManager.default.removeItem(at: root) }

        let outcome = DocCSidecarLoader.loadIfPresent(
            relativePath: "documentation/zkp/index.html",
            in: root.path
        )
        switch outcome {
        case .failed(let path, let message):
            #expect(path.hasSuffix("data/documentation/zkp.json"))
            #expect(!message.isEmpty)
        default:
            Issue.record("Expected .failed, got: \(outcome)")
        }
    }
}
