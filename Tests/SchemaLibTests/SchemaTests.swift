//
//  SchemaTests.swift
//  SchemaLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import SchemaLib

@Suite("Schema Model Tests")
struct SchemaTests {
    
    // MARK: - SchemaGraph Tests
    
    @Test("SchemaGraph uses simple format for single schema")
    func testSchemaGraphSingleSchema() throws {
        let faqSchema = FAQPageSchema(questions: [
            QuestionSchema(question: "Test?", answer: "Answer.")
        ])
        
        let graph = SchemaGraph(faqSchema)
        let json = try graph.render()
        
        #expect(json.contains("@context"))
        #expect(json.contains("schema.org"))
        #expect(json.contains("FAQPage"))
        // Single schema should NOT use @graph
        #expect(!json.contains("@graph"))
    }
    
    @Test("SchemaGraph uses @graph format for multiple schemas")
    func testSchemaGraphMultipleSchemas() throws {
        let orgSchema = OrganizationSchema(name: "Test Org")
        let faqSchema = FAQPageSchema(questions: [
            QuestionSchema(question: "Q?", answer: "A.")
        ])
        
        let graph = SchemaGraph([orgSchema, faqSchema])
        let json = try graph.render()
        
        #expect(json.contains("@context"))
        #expect(json.contains("@graph"))
        #expect(json.contains("Organization"))
        #expect(json.contains("FAQPage"))
    }
    
    @Test("SchemaGraph combines multiple schema content")
    func testSchemaGraphCombinesContent() throws {
        let orgSchema = OrganizationSchema(name: "Test Org")
        let faqSchema = FAQPageSchema(questions: [
            QuestionSchema(question: "Q?", answer: "A.")
        ])
        
        let graph = SchemaGraph([orgSchema, faqSchema])
        let json = try graph.render()
        
        #expect(json.contains("Organization"))
        #expect(json.contains("FAQPage"))
        #expect(json.contains("Test Org"))
    }
    
    // MARK: - OrganizationSchema Tests
    
    @Test("OrganizationSchema encodes required fields")
    func testOrganizationSchemaRequired() throws {
        let schema = OrganizationSchema(name: "21.dev")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("Organization"))
        #expect(json.contains("21.dev"))
    }
    
    @Test("OrganizationSchema encodes optional fields")
    func testOrganizationSchemaOptional() throws {
        let schema = OrganizationSchema(
            id: "https://21.dev/#organization",
            name: "21.dev",
            url: "https://21.dev",
            logo: "https://21.dev/logo.png",
            description: "Building tools for developers",
            sameAs: ["https://github.com/21-DOT-DEV", "https://x.com/21dotdev"]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("@id"))
        #expect(json.contains("21.dev"))
        #expect(json.contains("logo"))
        #expect(json.contains("description"))
        #expect(json.contains("sameAs"))
        #expect(json.contains("github.com"))
    }
    
    // MARK: - SoftwareApplicationSchema Tests
    
    @Test("SoftwareApplicationSchema encodes required fields")
    func testSoftwareApplicationSchemaRequired() throws {
        let schema = SoftwareApplicationSchema(name: "P256K")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("SoftwareApplication"))
        #expect(json.contains("P256K"))
    }
    
    @Test("SoftwareApplicationSchema encodes all fields")
    func testSoftwareApplicationSchemaFull() throws {
        let schema = SoftwareApplicationSchema(
            name: "P256K",
            description: "Swift secp256k1 library",
            applicationCategory: "DeveloperApplication",
            operatingSystem: "iOS, macOS, Linux",
            url: "https://21.dev/packages/p256k/",
            downloadUrl: "https://github.com/21-DOT-DEV/swift-secp256k1",
            author: SchemaReference(id: "https://21.dev/#organization"),
            license: "https://opensource.org/licenses/MIT",
            programmingLanguage: "Swift",
            softwareVersion: "1.0.0"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("SoftwareApplication"))
        #expect(json.contains("P256K"))
        #expect(json.contains("DeveloperApplication"))
        #expect(json.contains("Swift"))
        #expect(json.contains("@id"))
    }
    
    @Test("SchemaReference encodes @id correctly")
    func testSchemaReference() throws {
        let schema = SoftwareApplicationSchema(
            name: "Test",
            author: SchemaReference(id: "https://example.com/#org")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("\"@id\""))
        #expect(json.contains("example.com"))
    }
    
    // MARK: - FAQPageSchema Tests
    
    @Test("FAQPageSchema encodes from questions")
    func testFAQPageSchemaFromQuestions() throws {
        let schema = FAQPageSchema(questions: [
            QuestionSchema(question: "What is this?", answer: "A test."),
            QuestionSchema(question: "How does it work?", answer: "It works well.")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("FAQPage"))
        #expect(json.contains("mainEntity"))
        #expect(json.contains("What is this?"))
        #expect(json.contains("How does it work?"))
    }
    
    // MARK: - QuestionSchema Tests
    
    @Test("QuestionSchema encodes Question type")
    func testQuestionSchema() throws {
        let question = QuestionSchema(question: "Test question?", answer: "Test answer.")
        let faq = FAQPageSchema(questions: [question])
        let graph = SchemaGraph(faq)
        let json = try graph.render()
        
        #expect(json.contains("\"@type\" : \"Question\""))
        #expect(json.contains("Test question?"))
        #expect(json.contains("acceptedAnswer"))
    }
    
    // MARK: - AnswerSchema Tests
    
    @Test("AnswerSchema encodes Answer type")
    func testAnswerSchema() throws {
        let question = QuestionSchema(question: "Q?", answer: "The detailed answer.")
        let faq = FAQPageSchema(questions: [question])
        let graph = SchemaGraph(faq)
        let json = try graph.render()
        
        #expect(json.contains("\"@type\" : \"Answer\""))
        #expect(json.contains("The detailed answer."))
    }
    
    // MARK: - SoftwareSourceCodeSchema Tests
    
    @Test("SoftwareSourceCodeSchema encodes required fields")
    func testSoftwareSourceCodeSchemaRequired() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "P256K",
            codeRepository: "https://github.com/21-DOT-DEV/swift-secp256k1"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("SoftwareSourceCode"))
        #expect(json.contains("P256K"))
        #expect(json.contains("codeRepository"))
        #expect(json.contains("github.com"))
    }
    
    @Test("SoftwareSourceCodeSchema encodes all fields")
    func testSoftwareSourceCodeSchemaFull() throws {
        let schema = SoftwareSourceCodeSchema(
            id: "https://21.dev/packages/p256k/#software",
            name: "P256K",
            description: "Swift secp256k1 library",
            url: "https://21.dev/packages/p256k/",
            mainEntityOfPage: WebPageSchema(id: "https://21.dev/packages/p256k/"),
            codeRepository: "https://github.com/21-DOT-DEV/swift-secp256k1",
            programmingLanguage: ComputerLanguageSchema(name: "Swift"),
            license: "https://opensource.org/licenses/MIT",
            author: SchemaReference(id: "https://21.dev/#organization"),
            runtimePlatform: ["iOS", "macOS", "Linux"]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("SoftwareSourceCode"))
        #expect(json.contains("P256K"))
        #expect(json.contains("Swift secp256k1 library"))
        #expect(json.contains("programmingLanguage"))
        #expect(json.contains("ComputerLanguage"))
        #expect(json.contains("license"))
        #expect(json.contains("runtimePlatform"))
        #expect(json.contains("iOS"))
        #expect(json.contains("@id"))
        #expect(json.contains("#software"))
        #expect(json.contains("\"url\""))
        #expect(json.contains("mainEntityOfPage"))
        #expect(json.contains("WebPage"))
    }
    
    @Test("SoftwareSourceCodeSchema encodes @id and mainEntityOfPage")
    func testSoftwareSourceCodeSchemaIdentifiers() throws {
        let schema = SoftwareSourceCodeSchema(
            id: "https://example.com/#software",
            name: "Test",
            url: "https://example.com/",
            mainEntityOfPage: WebPageSchema(id: "https://example.com/"),
            codeRepository: "https://github.com/test/repo"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("\"@id\""))
        #expect(json.contains("#software"))
        #expect(json.contains("\"url\""))
        #expect(json.contains("\"mainEntityOfPage\""))
        #expect(json.contains("\"@type\" : \"WebPage\""))
    }
    
    // MARK: - Author Reference Tests
    
    @Test("Author encodes as SchemaReference")
    func testAuthorAsReference() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            codeRepository: "https://github.com/test/repo",
            author: SchemaReference(id: "https://21.dev/#organization")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("author"))
        #expect(json.contains("#organization"))
    }
    
    @Test("SoftwareSourceCodeSchema encodes sameAs when provided")
    func testSoftwareSourceCodeSchemaWithSameAs() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "P256K",
            codeRepository: "https://github.com/21-DOT-DEV/swift-secp256k1",
            sameAs: [
                "https://github.com/21-DOT-DEV/swift-secp256k1",
                "https://docs.21.dev/documentation/p256k/"
            ]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("sameAs"))
        #expect(json.contains("docs.21.dev"))
    }
    
    // MARK: - WebPageSchema Tests
    
    @Test("WebPageSchema encodes WebPage type with @id")
    func testWebPageSchema() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            mainEntityOfPage: WebPageSchema(id: "https://example.com/page/"),
            codeRepository: "https://github.com/test/repo"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("\"@type\" : \"WebPage\""))
        #expect(json.contains("\"@id\""))
        #expect(json.contains("example.com"))
    }
    
    // MARK: - ComputerLanguageSchema Tests
    
    @Test("ComputerLanguageSchema encodes ComputerLanguage type")
    func testComputerLanguageSchema() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            codeRepository: "https://github.com/test/repo",
            programmingLanguage: ComputerLanguageSchema(name: "Swift")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("\"@type\" : \"ComputerLanguage\""))
        #expect(json.contains("\"name\" : \"Swift\""))
    }
    
    // MARK: - PotentialActionSchema Tests
    
    @Test("PotentialActionSchema encodes actions")
    func testPotentialActionSchema() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            codeRepository: "https://github.com/test/repo",
            potentialAction: [
                PotentialActionSchema(type: .read, target: "https://docs.example.com/"),
                PotentialActionSchema(type: .view, target: "https://github.com/example/repo")
            ]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("potentialAction"))
        #expect(json.contains("ReadAction"))
        #expect(json.contains("ViewAction"))
        #expect(json.contains("target"))
    }
    
    // MARK: - Extended SoftwareSourceCode Properties Tests
    
    @Test("SoftwareSourceCodeSchema encodes softwareVersion and keywords")
    func testSoftwareSourceCodeSchemaExtended() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            codeRepository: "https://github.com/test/repo",
            softwareVersion: "1.0.0",
            keywords: ["swift", "crypto", "bitcoin"]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("softwareVersion"))
        #expect(json.contains("1.0.0"))
        #expect(json.contains("keywords"))
        #expect(json.contains("swift"))
        #expect(json.contains("bitcoin"))
    }
    
    @Test("SoftwareSourceCodeSchema encodes applicationCategory")
    func testSoftwareSourceCodeSchemaApplicationCategory() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            codeRepository: "https://github.com/test/repo",
            applicationCategory: ["DeveloperApplication", "Cryptography Library"]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("applicationCategory"))
        #expect(json.contains("DeveloperApplication"))
        #expect(json.contains("Cryptography Library"))
    }
    
    @Test("SoftwareSourceCodeSchema encodes creator and isBasedOn")
    func testSoftwareSourceCodeSchemaCreatorAndIsBasedOn() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "Test",
            codeRepository: "https://github.com/test/repo",
            creator: SchemaReference(id: "https://example.com/#org"),
            isBasedOn: "https://github.com/bitcoin-core/secp256k1"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("creator"))
        #expect(json.contains("#org"))
        #expect(json.contains("isBasedOn"))
        #expect(json.contains("bitcoin-core"))
    }
    
    // MARK: - MediaObjectSchema Tests
    
    @Test("MediaObjectSchema encodes @type, contentUrl, and encodingFormat")
    func testMediaObjectSchemaEncoding() throws {
        let schema = MediaObjectSchema(
            contentUrl: "https://docs.21.dev/data/documentation/p256k/context.md",
            encodingFormat: "text/markdown"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("\"@type\" : \"MediaObject\""))
        #expect(json.contains("\"contentUrl\""))
        #expect(json.contains("context.md"))
        #expect(json.contains("\"encodingFormat\""))
        #expect(json.contains("markdown"))
    }
    
    @Test("MediaObjectSchema omits no fields")
    func testMediaObjectSchemaAllFields() throws {
        let schema = MediaObjectSchema(
            contentUrl: "https://example.com/file.txt",
            encodingFormat: "text/plain"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        // Verify all three keys are present
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(parsed["@type"] as? String == "MediaObject")
        #expect(parsed["contentUrl"] as? String == "https://example.com/file.txt")
        #expect(parsed["encodingFormat"] as? String == "text/plain")
    }
    
    // MARK: - WebSiteSchema Tests
    
    @Test("WebSiteSchema encodes @type and url")
    func testWebSiteSchemaEncoding() throws {
        let schema = WebSiteSchema(url: "https://docs.21.dev/llms.txt")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("\"@type\" : \"WebSite\""))
        #expect(json.contains("\"url\""))
        #expect(json.contains("llms.txt"))
    }
    
    @Test("WebSiteSchema round-trips through JSON")
    func testWebSiteSchemaRoundTrip() throws {
        let schema = WebSiteSchema(url: "https://21.dev")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(parsed["@type"] as? String == "WebSite")
        #expect(parsed["url"] as? String == "https://21.dev")
    }
    
    @Test("WebSiteSchema encodes @id when provided")
    func testWebSiteSchemaWithId() throws {
        let schema = WebSiteSchema(
            id: "https://21.dev/#website",
            name: "21.dev",
            url: "https://21.dev/"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(parsed["@id"] as? String == "https://21.dev/#website")
        #expect(parsed["name"] as? String == "21.dev")
        #expect(parsed["url"] as? String == "https://21.dev/")
    }
    
    @Test("WebSiteSchema omits @id when nil (backward compat)")
    func testWebSiteSchemaOmitsId() throws {
        let schema = WebSiteSchema(url: "https://21.dev/")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("@id"))
    }
    
    // MARK: - WebPageSchema Extended Tests
    
    @Test("WebPageSchema reference-only init encodes only @type and @id")
    func testWebPageSchemaReferenceOnly() throws {
        let schema = WebPageSchema(id: "https://example.com/page/")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "WebPage")
        #expect(parsed["@id"] as? String == "https://example.com/page/")
        // Optional fields must be absent
        #expect(parsed["isPartOf"] == nil)
        #expect(parsed["name"] == nil)
        #expect(parsed["url"] == nil)
        #expect(parsed["inLanguage"] == nil)
        #expect(parsed["description"] == nil)
        #expect(parsed["mainEntity"] == nil)
    }
    
    @Test("WebPageSchema full init encodes all fields")
    func testWebPageSchemaFull() throws {
        let schema = WebPageSchema(
            id: "https://21.dev/blog/hello/#webpage",
            isPartOf: SchemaReference(id: "https://21.dev/#website"),
            name: "Hello World",
            url: "https://21.dev/blog/hello/",
            description: "A blog post",
            mainEntity: SchemaReference(id: "https://21.dev/blog/hello/#blogposting")
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "WebPage")
        #expect(parsed["@id"] as? String == "https://21.dev/blog/hello/#webpage")
        #expect(parsed["name"] as? String == "Hello World")
        #expect(parsed["url"] as? String == "https://21.dev/blog/hello/")
        #expect(parsed["inLanguage"] as? String == "en-US")
        #expect(parsed["description"] as? String == "A blog post")
        
        let isPartOf = parsed["isPartOf"] as? [String: Any]
        #expect(isPartOf?["@id"] as? String == "https://21.dev/#website")
        
        let mainEntity = parsed["mainEntity"] as? [String: Any]
        #expect(mainEntity?["@id"] as? String == "https://21.dev/blog/hello/#blogposting")
    }
    
    @Test("WebPageSchema defaults inLanguage to en-US")
    func testWebPageSchemaDefaultLanguage() throws {
        let schema = WebPageSchema(
            id: "https://example.com/#webpage",
            isPartOf: SchemaReference(id: "https://example.com/#website"),
            name: "Test",
            url: "https://example.com/"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["inLanguage"] as? String == "en-US")
    }
    
    // MARK: - BlogPostingSchema Tests
    
    @Test("BlogPostingSchema encodes required fields")
    func testBlogPostingSchemaRequired() throws {
        let schema = BlogPostingSchema(
            headline: "Hello World",
            datePublished: "2025-10-15"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("BlogPosting"))
        #expect(json.contains("Hello World"))
        #expect(json.contains("2025-10-15"))
        // Optional fields should be absent
        #expect(!json.contains("@id"))
        #expect(!json.contains("dateModified"))
        #expect(!json.contains("author"))
    }
    
    @Test("BlogPostingSchema encodes all fields")
    func testBlogPostingSchemaFull() throws {
        let schema = BlogPostingSchema(
            id: "https://21.dev/blog/hello/#blogposting",
            headline: "Hello World",
            datePublished: "2025-10-15",
            dateModified: "2025-10-16",
            description: "Welcome to 21.dev",
            author: SchemaReference(id: "https://21.dev/#organization"),
            url: "https://21.dev/blog/hello/",
            mainEntityOfPage: SchemaReference(id: "https://21.dev/blog/hello/#webpage")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "BlogPosting")
        #expect(parsed["@id"] as? String == "https://21.dev/blog/hello/#blogposting")
        #expect(parsed["headline"] as? String == "Hello World")
        #expect(parsed["datePublished"] as? String == "2025-10-15")
        #expect(parsed["dateModified"] as? String == "2025-10-16")
        #expect(parsed["description"] as? String == "Welcome to 21.dev")
        #expect(parsed["url"] as? String == "https://21.dev/blog/hello/")
        #expect(parsed["inLanguage"] as? String == "en-US")
        
        let author = parsed["author"] as? [String: Any]
        #expect(author?["@id"] as? String == "https://21.dev/#organization")
        
        let meop = parsed["mainEntityOfPage"] as? [String: Any]
        #expect(meop?["@id"] as? String == "https://21.dev/blog/hello/#webpage")
    }
    
    @Test("BlogPostingSchema defaults inLanguage to en-US")
    func testBlogPostingSchemaDefaultLanguage() throws {
        let schema = BlogPostingSchema(
            headline: "Test",
            datePublished: "2025-01-01"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["inLanguage"] as? String == "en-US")
    }
    
    @Test("BlogPostingSchema in @graph with WebPage and Organization")
    func testBlogPostingInGraph() throws {
        let blogPosting = BlogPostingSchema(
            id: "https://21.dev/blog/hello/#blogposting",
            headline: "Hello",
            datePublished: "2025-10-15",
            author: SchemaReference(id: "https://21.dev/#organization"),
            mainEntityOfPage: SchemaReference(id: "https://21.dev/blog/hello/#webpage")
        )
        let webPage = WebPageSchema(
            id: "https://21.dev/blog/hello/#webpage",
            isPartOf: SchemaReference(id: "https://21.dev/#website"),
            name: "Hello",
            url: "https://21.dev/blog/hello/",
            mainEntity: SchemaReference(id: "https://21.dev/blog/hello/#blogposting")
        )
        let org = OrganizationSchema(
            id: "https://21.dev/#organization",
            name: "21.dev"
        )
        
        let graph = SchemaGraph([blogPosting, webPage, org])
        let json = try graph.render()
        
        #expect(json.contains("@graph"))
        #expect(json.contains("BlogPosting"))
        #expect(json.contains("WebPage"))
        #expect(json.contains("Organization"))
        // Verify bidirectional references
        #expect(json.contains("#blogposting"))
        #expect(json.contains("#webpage"))
        #expect(json.contains("#organization"))
    }
    
    // MARK: - renderCompact Tests
    
    @Test("renderCompact produces valid JSON without pretty-print whitespace")
    func testRenderCompactNoWhitespace() throws {
        let schema = OrganizationSchema(name: "Test Org")
        let graph = SchemaGraph(schema)
        
        let compact = try graph.renderCompact()
        let pretty = try graph.render()
        
        // Compact must be shorter (no indentation/newlines)
        #expect(compact.count < pretty.count)
        // Compact must not contain newlines
        #expect(!compact.contains("\n"))
        // Compact must still be valid JSON
        let data = compact.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(parsed["@type"] as? String == "Organization")
        #expect(parsed["name"] as? String == "Test Org")
    }
    
    @Test("renderCompact and render produce semantically identical JSON")
    func testRenderCompactSemanticallyEqual() throws {
        let schema = FAQPageSchema(questions: [
            QuestionSchema(question: "Q?", answer: "A.")
        ])
        let graph = SchemaGraph(schema)
        
        let compactData = try graph.renderCompact().data(using: .utf8)!
        let prettyData = try graph.render().data(using: .utf8)!
        
        let compactObj = try JSONSerialization.jsonObject(with: compactData)
        let prettyObj = try JSONSerialization.jsonObject(with: prettyData)
        
        // Re-serialize both to sorted-keys canonical form for comparison
        let opts: JSONSerialization.WritingOptions = [.sortedKeys]
        let compactCanonical = try JSONSerialization.data(withJSONObject: compactObj, options: opts)
        let prettyCanonical = try JSONSerialization.data(withJSONObject: prettyObj, options: opts)
        
        #expect(compactCanonical == prettyCanonical)
    }
    
    @Test("renderCompact uses sorted keys")
    func testRenderCompactSortedKeys() throws {
        let schema = MediaObjectSchema(
            contentUrl: "https://example.com/file.md",
            encodingFormat: "text/markdown"
        )
        let graph = SchemaGraph(schema)
        let compact = try graph.renderCompact()
        
        // With sorted keys, @context < @type < contentUrl < encodingFormat
        let contextIdx = compact.range(of: "@context")!.lowerBound
        let typeIdx = compact.range(of: "@type")!.lowerBound
        let contentIdx = compact.range(of: "contentUrl")!.lowerBound
        let formatIdx = compact.range(of: "encodingFormat")!.lowerBound
        
        #expect(contextIdx < typeIdx)
        #expect(typeIdx < contentIdx)
        #expect(contentIdx < formatIdx)
    }
    
    // MARK: - OrganizationSchema foundingDate Tests
    
    @Test("OrganizationSchema encodes foundingDate when provided")
    func testOrganizationSchemaFoundingDate() throws {
        let schema = OrganizationSchema(
            id: "https://21.dev/#organization",
            name: "21.dev",
            url: "https://21.dev",
            logo: "https://github.com/21-DOT-DEV.png",
            foundingDate: "2024",
            description: "Open-source tools for Bitcoin developers",
            sameAs: ["https://github.com/21-DOT-DEV"]
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["foundingDate"] as? String == "2024")
        #expect(parsed["logo"] as? String == "https://github.com/21-DOT-DEV.png")
        #expect(parsed["description"] as? String == "Open-source tools for Bitcoin developers")
    }
    
    @Test("OrganizationSchema omits foundingDate when nil")
    func testOrganizationSchemaOmitsFoundingDate() throws {
        let schema = OrganizationSchema(name: "Test Org")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("foundingDate"))
    }
    
    // MARK: - SearchActionSchema Tests
    
    @Test("SearchActionSchema encodes SearchAction with EntryPoint target")
    func testSearchActionSchemaEncoding() throws {
        let schema = WebSiteSchema(
            id: "https://21.dev/#website",
            name: "21.dev",
            url: "https://21.dev/",
            potentialAction: SearchActionSchema(
                targetURLTemplate: "https://21.dev/search?q={search_term_string}"
            )
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let action = parsed["potentialAction"] as? [String: Any]
        #expect(action?["@type"] as? String == "SearchAction")
        #expect(action?["query-input"] as? String == "required name=search_term_string")
        
        let target = action?["target"] as? [String: Any]
        #expect(target?["@type"] as? String == "EntryPoint")
        #expect(target?["urlTemplate"] as? String == "https://21.dev/search?q={search_term_string}")
    }
    
    @Test("WebSiteSchema omits potentialAction when nil")
    func testWebSiteSchemaOmitsPotentialAction() throws {
        let schema = WebSiteSchema(url: "https://21.dev/")
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("potentialAction"))
        #expect(!json.contains("SearchAction"))
    }
    
    // MARK: - WebPageSchema CollectionPage Tests
    
    @Test("WebPageSchema encodes CollectionPage type when specified")
    func testWebPageSchemaCollectionPage() throws {
        let schema = WebPageSchema(
            id: "https://21.dev/blog/#webpage",
            pageType: .collectionPage,
            isPartOf: SchemaReference(id: "https://21.dev/#website"),
            name: "Blog",
            url: "https://21.dev/blog/"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "CollectionPage")
        #expect(parsed["@id"] as? String == "https://21.dev/blog/#webpage")
    }
    
    @Test("WebPageSchema encodes breadcrumb reference when provided")
    func testWebPageSchemaWithBreadcrumb() throws {
        let schema = WebPageSchema(
            id: "https://docs.21.dev/documentation/p256k/signing/#webpage",
            isPartOf: SchemaReference(id: "https://docs.21.dev/#website"),
            name: "Signing",
            url: "https://docs.21.dev/documentation/p256k/signing/",
            breadcrumb: SchemaReference(id: "https://docs.21.dev/documentation/p256k/signing/#breadcrumb")
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let breadcrumb = parsed["breadcrumb"] as? [String: Any]
        #expect(breadcrumb?["@id"] as? String == "https://docs.21.dev/documentation/p256k/signing/#breadcrumb")
    }
    
    @Test("WebPageSchema omits breadcrumb when nil")
    func testWebPageSchemaOmitsBreadcrumb() throws {
        let schema = WebPageSchema(
            id: "https://docs.21.dev/documentation/p256k/#webpage",
            isPartOf: SchemaReference(id: "https://docs.21.dev/#website"),
            name: "P256K",
            url: "https://docs.21.dev/documentation/p256k/"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["breadcrumb"] == nil)
    }
    
    @Test("WebPageSchema defaults to WebPage type")
    func testWebPageSchemaDefaultType() throws {
        let schema = WebPageSchema(id: "https://example.com/")
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "WebPage")
    }
    
    // MARK: - BlogPostingSchema Extended Fields Tests
    
    @Test("BlogPostingSchema encodes image, publisher, wordCount, articleSection, keywords")
    func testBlogPostingSchemaExtendedFields() throws {
        let schema = BlogPostingSchema(
            id: "https://21.dev/blog/hello/#blogposting",
            headline: "Hello World",
            datePublished: "2025-10-15",
            description: "Welcome to 21.dev",
            image: "https://21.dev/images/hello-world.jpg",
            author: SchemaReference(id: "https://21.dev/#organization"),
            publisher: SchemaReference(id: "https://21.dev/#organization"),
            url: "https://21.dev/blog/hello/",
            wordCount: 350,
            articleSection: "announcement",
            keywords: ["announcement", "welcome", "first post"],
            mainEntityOfPage: SchemaReference(id: "https://21.dev/blog/hello/#webpage")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["image"] as? String == "https://21.dev/images/hello-world.jpg")
        #expect(parsed["wordCount"] as? Int == 350)
        #expect(parsed["articleSection"] as? String == "announcement")
        
        let keywords = parsed["keywords"] as? [String]
        #expect(keywords == ["announcement", "welcome", "first post"])
        
        let publisher = parsed["publisher"] as? [String: Any]
        #expect(publisher?["@id"] as? String == "https://21.dev/#organization")
    }
    
    @Test("BlogPostingSchema omits new optional fields when nil")
    func testBlogPostingSchemaOmitsNewFields() throws {
        let schema = BlogPostingSchema(
            headline: "Minimal Post",
            datePublished: "2025-01-01"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("image"))
        #expect(!json.contains("publisher"))
        #expect(!json.contains("wordCount"))
        #expect(!json.contains("articleSection"))
        #expect(!json.contains("keywords"))
    }
    
    // MARK: - SoftwareSourceCodeSchema publisher Tests
    
    @Test("SoftwareSourceCodeSchema encodes publisher when provided")
    func testSoftwareSourceCodeSchemaPublisher() throws {
        let schema = SoftwareSourceCodeSchema(
            name: "P256K",
            codeRepository: "https://github.com/21-DOT-DEV/swift-secp256k1",
            author: SchemaReference(id: "https://21.dev/#organization"),
            publisher: SchemaReference(id: "https://21.dev/#organization")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let publisher = parsed["publisher"] as? [String: Any]
        #expect(publisher?["@id"] as? String == "https://21.dev/#organization")
        
        let author = parsed["author"] as? [String: Any]
        #expect(author?["@id"] as? String == "https://21.dev/#organization")
    }
    
    // MARK: - ItemListSchema Tests
    
    @Test("ItemListSchema encodes ItemList with ListItem elements")
    func testItemListSchemaEncoding() throws {
        let schema = ItemListSchema(items: [
            ListItemSchema(position: 1, url: "https://21.dev/blog/hello-world/", name: "Hello World"),
            ListItemSchema(position: 2, url: "https://21.dev/blog/second-post/", name: "Second Post")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "ItemList")
        
        let items = parsed["itemListElement"] as? [[String: Any]]
        #expect(items?.count == 2)
        
        #expect(items?[0]["@type"] as? String == "ListItem")
        #expect(items?[0]["position"] as? Int == 1)
        #expect(items?[0]["url"] as? String == "https://21.dev/blog/hello-world/")
        #expect(items?[0]["name"] as? String == "Hello World")
        
        #expect(items?[1]["position"] as? Int == 2)
        #expect(items?[1]["url"] as? String == "https://21.dev/blog/second-post/")
    }
    
    @Test("ListItemSchema omits name when nil")
    func testListItemSchemaOmitsName() throws {
        let schema = ItemListSchema(items: [
            ListItemSchema(position: 1, url: "https://example.com/page/")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let items = parsed["itemListElement"] as? [[String: Any]]
        #expect(items?[0]["name"] == nil)
        #expect(items?[0]["url"] as? String == "https://example.com/page/")
    }
    
    @Test("ItemListSchema encodes @id when provided")
    func testItemListSchemaWithId() throws {
        let schema = ItemListSchema(id: "https://21.dev/blog/#itemlist", items: [
            ListItemSchema(position: 1, url: "https://21.dev/blog/hello/", name: "Hello")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@id"] as? String == "https://21.dev/blog/#itemlist")
        #expect(parsed["@type"] as? String == "ItemList")
    }
    
    @Test("ItemListSchema omits @id when nil")
    func testItemListSchemaOmitsId() throws {
        let schema = ItemListSchema(items: [
            ListItemSchema(position: 1, url: "https://example.com/")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("@id"))
    }
    
    @Test("ListItemSchema encodes description when provided")
    func testListItemSchemaWithDescription() throws {
        let schema = ItemListSchema(items: [
            ListItemSchema(position: 1, url: "https://example.com/pkg/", name: "P256K", description: "Swift secp256k1 library")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let items = parsed["itemListElement"] as? [[String: Any]]
        #expect(items?[0]["description"] as? String == "Swift secp256k1 library")
    }
    
    @Test("ListItemSchema omits description when nil")
    func testListItemSchemaOmitsDescription() throws {
        let schema = ItemListSchema(items: [
            ListItemSchema(position: 1, url: "https://example.com/page/", name: "Test")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("description"))
    }
    
    // MARK: - BreadcrumbListSchema Tests
    
    @Test("BreadcrumbListSchema encodes BreadcrumbList with ListItem elements")
    func testBreadcrumbListSchemaEncoding() throws {
        let schema = BreadcrumbListSchema(items: [
            BreadcrumbItemSchema(position: 1, name: "Home", item: "https://21.dev/"),
            BreadcrumbItemSchema(position: 2, name: "Packages", item: "https://21.dev/packages/"),
            BreadcrumbItemSchema(position: 3, name: "P256K")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@type"] as? String == "BreadcrumbList")
        
        let items = parsed["itemListElement"] as? [[String: Any]]
        #expect(items?.count == 3)
        
        #expect(items?[0]["@type"] as? String == "ListItem")
        #expect(items?[0]["position"] as? Int == 1)
        #expect(items?[0]["name"] as? String == "Home")
        #expect(items?[0]["item"] as? String == "https://21.dev/")
        
        #expect(items?[1]["position"] as? Int == 2)
        #expect(items?[1]["name"] as? String == "Packages")
        #expect(items?[1]["item"] as? String == "https://21.dev/packages/")
        
        #expect(items?[2]["position"] as? Int == 3)
        #expect(items?[2]["name"] as? String == "P256K")
    }
    
    @Test("BreadcrumbItemSchema omits item URL for final breadcrumb (current page)")
    func testBreadcrumbItemSchemaOmitsItemForCurrentPage() throws {
        let schema = BreadcrumbListSchema(items: [
            BreadcrumbItemSchema(position: 1, name: "Home", item: "https://21.dev/"),
            BreadcrumbItemSchema(position: 2, name: "Blog")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let items = parsed["itemListElement"] as? [[String: Any]]
        #expect(items?[0]["item"] as? String == "https://21.dev/")
        #expect(items?[1]["item"] == nil)
        #expect(items?[1]["name"] as? String == "Blog")
    }
    
    @Test("BreadcrumbListSchema encodes @id when provided")
    func testBreadcrumbListSchemaWithId() throws {
        let schema = BreadcrumbListSchema(id: "https://docs.21.dev/documentation/p256k/#breadcrumb", items: [
            BreadcrumbItemSchema(position: 1, name: "P256K", item: "https://docs.21.dev/documentation/p256k/")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        let data = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(parsed["@id"] as? String == "https://docs.21.dev/documentation/p256k/#breadcrumb")
        #expect(parsed["@type"] as? String == "BreadcrumbList")
    }
    
    @Test("BreadcrumbListSchema omits @id when nil")
    func testBreadcrumbListSchemaOmitsId() throws {
        let schema = BreadcrumbListSchema(items: [
            BreadcrumbItemSchema(position: 1, name: "Home", item: "https://21.dev/")
        ])
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(!json.contains("@id"))
    }
    
    @Test("BreadcrumbListSchema works in @graph with other schemas")
    func testBreadcrumbListSchemaInGraph() throws {
        let orgSchema = OrganizationSchema(name: "21.dev")
        let breadcrumbs = BreadcrumbListSchema(items: [
            BreadcrumbItemSchema(position: 1, name: "Home", item: "https://21.dev/"),
            BreadcrumbItemSchema(position: 2, name: "Blog")
        ])
        
        let graph = SchemaGraph([orgSchema, breadcrumbs])
        let json = try graph.render()
        
        #expect(json.contains("@graph"))
        #expect(json.contains("Organization"))
        #expect(json.contains("BreadcrumbList"))
    }

    // MARK: - Inline JSON-LD safety (`<` / `>` escape)

    @Test("renderCompact escapes `<` as \\u003c so inline <script> blocks are safe")
    func testRenderCompactEscapesLessThan() throws {
        let blog = BlogPostingSchema(
            headline: "</script><img src=x onerror=alert(1)>",
            datePublished: "2026-01-01"
        )
        let json = try SchemaGraph(blog).renderCompact()

        // Raw `</script>` must NEVER appear in the rendered JSON-LD —
        // it would prematurely terminate the surrounding <script> block.
        #expect(!json.contains("</script>"))
        // Both `<` and `>` must appear escaped. (JSONEncoder also escapes `/`
        // to `\/`, which is independently safe; we don't assert on it because
        // that's encoder-default behavior, not our post-process.)
        #expect(json.contains("\\u003c"))
        #expect(json.contains("\\u003e"))
    }

    @Test("render (pretty) also escapes `<` and `>`")
    func testRenderPrettyEscapesAngleBrackets() throws {
        let blog = BlogPostingSchema(
            headline: "title with < and > characters",
            datePublished: "2026-01-01"
        )
        let json = try SchemaGraph(blog).render()

        #expect(!json.contains("with <"))
        #expect(!json.contains("> characters"))
        #expect(json.contains("\\u003c"))
        #expect(json.contains("\\u003e"))
    }

    @Test("Escape preserves valid JSON parseability")
    func testEscapePreservesJSONParseability() throws {
        let blog = BlogPostingSchema(
            headline: "Round-trip </script> safety",
            datePublished: "2026-01-01"
        )
        let json = try SchemaGraph(blog).renderCompact()
        // The escaped bytes still represent the original string after JSON decoding.
        let parsed = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        #expect(parsed?["headline"] as? String == "Round-trip </script> safety")
    }

    // MARK: - TechArticleSchema Tests

    @Test("TechArticleSchema encodes minimal fields")
    func testTechArticleSchemaMinimal() throws {
        let schema = TechArticleSchema(headline: "Getting Started")
        let graph = SchemaGraph(schema)
        let json = try graph.render()

        #expect(json.contains("\"@type\""))
        #expect(json.contains("TechArticle"))
        #expect(json.contains("Getting Started"))
        #expect(json.contains("\"inLanguage\""))
        #expect(json.contains("en-US"))
    }

    @Test("TechArticleSchema encodes all optional fields")
    func testTechArticleSchemaFull() throws {
        let schema = TechArticleSchema(
            id: "https://docs.21.dev/documentation/zkp/choosingp256kvszkp/#techarticle",
            headline: "Choosing Between P256K and ZKP",
            description: "Decision boundary between the two products.",
            url: "https://docs.21.dev/documentation/zkp/choosingp256kvszkp/",
            inLanguage: "en-US",
            isPartOf: SchemaReference(id: "https://docs.21.dev/#website"),
            mainEntityOfPage: SchemaReference(id: "https://docs.21.dev/documentation/zkp/choosingp256kvszkp/#webpage"),
            publisher: SchemaReference(id: "https://21.dev/#organization")
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()

        // JSONEncoder escapes `/` as `\/`, so assert structurally via JSONSerialization.
        let parsed = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        #expect(parsed?["headline"] as? String == "Choosing Between P256K and ZKP")
        #expect(parsed?["description"] as? String == "Decision boundary between the two products.")
        #expect(parsed?["url"] as? String == "https://docs.21.dev/documentation/zkp/choosingp256kvszkp/")
        let isPartOf = parsed?["isPartOf"] as? [String: String]
        #expect(isPartOf?["@id"] == "https://docs.21.dev/#website")
        let publisher = parsed?["publisher"] as? [String: String]
        #expect(publisher?["@id"] == "https://21.dev/#organization")
    }

    @Test("TechArticleSchema omits nil optional fields")
    func testTechArticleSchemaOmitsNil() throws {
        let schema = TechArticleSchema(headline: "Title")
        let graph = SchemaGraph(schema)
        let json = try graph.render()

        #expect(!json.contains("\"description\""))
        #expect(!json.contains("\"url\""))
        #expect(!json.contains("\"isPartOf\""))
        #expect(!json.contains("\"publisher\""))
        #expect(!json.contains("\"@id\""))
    }

    @Test("TechArticleSchema participates in @graph alongside WebPage")
    func testTechArticleInGraph() throws {
        let webPage = WebPageSchema(
            id: "https://docs.21.dev/x/#webpage",
            isPartOf: SchemaReference(id: "https://docs.21.dev/#website"),
            name: "Choosing Between P256K and ZKP",
            url: "https://docs.21.dev/x/",
            mainEntity: SchemaReference(id: "https://docs.21.dev/x/#techarticle")
        )
        let article = TechArticleSchema(
            id: "https://docs.21.dev/x/#techarticle",
            headline: "Choosing Between P256K and ZKP",
            mainEntityOfPage: SchemaReference(id: "https://docs.21.dev/x/#webpage")
        )
        let graph = SchemaGraph([webPage, article])
        let json = try graph.render()

        #expect(json.contains("\"@graph\""))
        #expect(json.contains("\"WebPage\""))
        #expect(json.contains("\"TechArticle\""))
        #expect(json.contains("#webpage"))
        #expect(json.contains("#techarticle"))
    }

    // MARK: - APIReferenceSchema Tests

    @Test("APIReferenceSchema encodes minimal fields")
    func testAPIReferenceSchemaMinimal() throws {
        let schema = APIReferenceSchema(headline: "EventLoop")
        let graph = SchemaGraph(schema)
        let json = try graph.render()

        #expect(json.contains("APIReference"))
        #expect(json.contains("EventLoop"))
    }

    @Test("APIReferenceSchema encodes API-specific fields")
    func testAPIReferenceSchemaSpecificFields() throws {
        let schema = APIReferenceSchema(
            id: "https://docs.21.dev/documentation/event/eventloop/#apireference",
            headline: "EventLoop",
            description: "A libevent-backed event loop.",
            url: "https://docs.21.dev/documentation/event/eventloop/",
            programmingLanguage: "Swift",
            codeRepository: "https://github.com/21-DOT-DEV/swift-event",
            about: "Event"
        )
        let graph = SchemaGraph(schema)
        let json = try graph.render()

        let parsed = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        #expect(parsed?["programmingLanguage"] as? String == "Swift")
        #expect(parsed?["codeRepository"] as? String == "https://github.com/21-DOT-DEV/swift-event")
        #expect(parsed?["about"] as? String == "Event")
    }

    @Test("APIReferenceSchema omits API-specific fields when nil")
    func testAPIReferenceSchemaOmitsNilSpecific() throws {
        let schema = APIReferenceSchema(headline: "EventLoop")
        let graph = SchemaGraph(schema)
        let json = try graph.render()

        #expect(!json.contains("\"programmingLanguage\""))
        #expect(!json.contains("\"codeRepository\""))
        #expect(!json.contains("\"about\""))
    }

    @Test("APIReferenceSchema bidirectional refs with WebPage")
    func testAPIReferenceBidirectionalRefs() throws {
        let pageURL = "https://docs.21.dev/documentation/event/eventloop/"
        let webPage = WebPageSchema(
            id: "\(pageURL)#webpage",
            isPartOf: SchemaReference(id: "https://docs.21.dev/#website"),
            name: "EventLoop",
            url: pageURL,
            mainEntity: SchemaReference(id: "\(pageURL)#apireference")
        )
        let api = APIReferenceSchema(
            id: "\(pageURL)#apireference",
            headline: "EventLoop",
            mainEntityOfPage: SchemaReference(id: "\(pageURL)#webpage")
        )
        let graph = SchemaGraph([webPage, api])
        let json = try graph.render()

        #expect(json.contains("\"mainEntity\""))
        #expect(json.contains("\"mainEntityOfPage\""))
        #expect(json.contains("#webpage"))
        #expect(json.contains("#apireference"))
    }
}
