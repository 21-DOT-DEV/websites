//
//  SchemaTests.swift
//  DesignSystemTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import Slipstream

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
    
    @Test("FAQPageSchema filters by includeInJSONLD")
    func testFAQPageSchemaFiltering() throws {
        let items = [
            FAQItem(question: "Included?", includeInJSONLD: true) { Text("Yes.") },
            FAQItem(question: "Excluded?") { Text("No.") }
        ]
        
        let schema = FAQPageSchema(items: items)
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("Included?"))
        #expect(!json.contains("Excluded?"))
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
}
