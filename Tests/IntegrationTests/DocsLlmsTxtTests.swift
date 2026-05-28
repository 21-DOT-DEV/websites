import Foundation
import Testing

@Suite("docs.21.dev llms.txt Tests")
struct DocsLlmsTxtTests {
    private enum Module: String, CaseIterable {
        case p256k
        case zkp
        case event
        case openssl
        case tor
        case bitcoin
        case bitcoinkernel
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var docsResources: URL {
        repositoryRoot
            .appendingPathComponent("Resources")
            .appendingPathComponent("docs-21-dev")
    }

    private var expectedFiles: [URL] {
        [docsResources.appendingPathComponent("llms.txt")] + Module.allCases.map { module in
            docsResources
                .appendingPathComponent("data")
                .appendingPathComponent("documentation")
                .appendingPathComponent(module.rawValue)
                .appendingPathComponent("llms.txt")
        }
    }

    @Test("Expected docs llms.txt files exist")
    func expectedDocsLlmsTxtFilesExist() {
        for file in expectedFiles {
            #expect(FileManager.default.fileExists(atPath: file.path))
        }
    }

    @Test("Root llms.txt uses expected catalog sections")
    func rootLlmsTxtUsesExpectedSections() throws {
        let content = try read(docsResources.appendingPathComponent("llms.txt"))

        #expect(content.contains("## Instructions"))
        #expect(content.contains("## Docs"))
        #expect(content.contains("## Optional"))
        #expect(!content.contains("## Modules"))
        #expect(!content.contains("## Related"))
        #expect(!content.contains("Interactive HTML Docs"))

        let docs = section(named: "Docs", in: content) ?? ""
        for module in ["P256K", "ZKP", "Event", "OpenSSL", "Tor", "Bitcoin", "BitcoinKernel"] {
            #expect(docs.contains("- [\(module)]"))
        }
    }

    @Test("Module llms.txt files use expected section ordering")
    func moduleLlmsTxtFilesUseExpectedSectionOrdering() throws {
        for module in Module.allCases {
            let content = try read(moduleFile(module))
            let headings = sectionHeadings(in: content)
            // "API" replaces the older "Symbols" heading per the llms.txt
            // research finding (see .specify/memory/llms-txt-research.md
            // Finding 8 — "API" is the broader convention used by FastHTML,
            // nbdev, Pydantic, etc.).
            let required = ["Instructions", "When to use this", "Documentation", "API"]

            for heading in required {
                #expect(headings.contains(heading))
            }

            #expect(required.isOrdered(in: headings))

            if headings.contains("Optional") {
                #expect((headings.firstIndex(of: "Optional") ?? 0) > (headings.firstIndex(of: "API") ?? Int.max))
            }
        }
    }

    @Test("Module llms.txt files keep expected instruction guidance")
    func moduleLlmsTxtFilesKeepExpectedInstructionGuidance() throws {
        let p256k = try read(moduleFile(.p256k))
        let zkp = try read(moduleFile(.zkp))
        let event = try read(moduleFile(.event))
        let openssl = try read(moduleFile(.openssl))
        let tor = try read(moduleFile(.tor))

        #expect(firstInstructionBullet(in: p256k)?.contains("Security Considerations") == true)
        #expect(firstInstructionBullet(in: event)?.contains("Production Considerations") == true)
        #expect(firstInstructionBullet(in: openssl)?.contains("Security Considerations") == true)
        #expect(firstInstructionBullet(in: tor)?.contains("Production Considerations") == true)
        #expect(firstInstructionBullet(in: zkp)?.contains("P256K Security Considerations") == true)

        #expect(p256k.contains("Construct a single `P256K.Context` per process and reuse it"))
        #expect(zkp.contains("Fetch [P256K's llms.txt]"))
        #expect(event.contains("Hand sockets off to a single owner"))
        #expect(openssl.contains("Compare digest values using constant-time comparison"))
        #expect(tor.contains("function signatures should accept `any TorSession`"))
    }

    @Test("Known bad markdown URLs are not introduced")
    func knownBadMarkdownURLsAreNotIntroduced() throws {
        for file in expectedFiles {
            let content = try read(file)
            #expect(!content.contains("https://docs.21.dev/data/documentation/p256k/choosingp256kvsswiftcrypto.md"))
            #expect(!content.contains("https://docs.21.dev/data/documentation/zkp/securityconsiderations.md"))
        }
    }

    @Test("Primary error types are not optional")
    func primaryErrorTypesAreNotOptional() throws {
        let eventOptional = try section(named: "Optional", in: read(moduleFile(.event))) ?? ""
        let opensslOptional = try section(named: "Optional", in: read(moduleFile(.openssl))) ?? ""
        let torOptional = try section(named: "Optional", in: read(moduleFile(.tor))) ?? ""

        #expect(!eventOptional.contains("SocketError"))
        #expect(!opensslOptional.contains("OpenSSLError"))
        #expect(!torOptional.contains("TorError"))
    }

    private func moduleFile(_ module: Module) -> URL {
        docsResources
            .appendingPathComponent("data")
            .appendingPathComponent("documentation")
            .appendingPathComponent(module.rawValue)
            .appendingPathComponent("llms.txt")
    }

    private func read(_ file: URL) throws -> String {
        try String(contentsOf: file, encoding: .utf8)
    }

    private func sectionHeadings(in content: String) -> [String] {
        content.components(separatedBy: .newlines).compactMap { line in
            guard line.hasPrefix("## ") else { return nil }
            return String(line.dropFirst(3))
        }
    }

    private func section(named name: String, in content: String) -> String? {
        var found = false
        var lines: [String] = []

        for line in content.components(separatedBy: .newlines) {
            if line == "## \(name)" {
                found = true
                continue
            }
            if found && line.hasPrefix("## ") {
                break
            }
            if found {
                lines.append(line)
            }
        }

        guard found else { return nil }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func firstInstructionBullet(in content: String) -> String? {
        section(named: "Instructions", in: content)?
            .components(separatedBy: .newlines)
            .first { $0.hasPrefix("- ") }
    }
}

private extension Array where Element == String {
    func isOrdered(in values: [String]) -> Bool {
        var currentIndex = -1

        for value in self {
            guard let nextIndex = values.firstIndex(of: value) else {
                return false
            }
            guard nextIndex > currentIndex else {
                return false
            }
            currentIndex = nextIndex
        }

        return true
    }
}
