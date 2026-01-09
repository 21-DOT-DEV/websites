//
//  FAQTests.swift
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
import TestUtils

struct FAQTests {
    
    // MARK: - Basic Structure Tests
    
    @Test("FAQ renders visual accordion with details/summary")
    func testFAQRendersAccordion() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "What is P256K?",
                answer: "P256K is a Swift library for secp256k1.",
                content: { Text("P256K is a Swift library for secp256k1.") }
            )
        ])
        
        let html = try TestUtils.renderHTML(faq)
        
        // Should render visual accordion
        #expect(html.contains("<details"))
        #expect(html.contains("<summary"))
        #expect(html.contains("What is P256K?"))
        #expect(html.contains("P256K is a Swift library"))
    }
    
    @Test("FAQ provides schema for BasePage integration")
    func testFAQProvidesSchema() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "Test question?",
                answer: "Test answer.",
                content: { Text("Test answer.") }
            )
        ])
        
        // FAQ should provide a schema for use with BasePage
        let schema = faq.schema
        let graph = SchemaGraph(schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("FAQPage"))
    }
    
    // MARK: - Schema Tests (JSON-LD is now rendered via BasePage, not inline)
    
    @Test("FAQ schema contains FAQPage type")
    func testFAQSchemaType() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "What is this?",
                answer: "This is a test.",
                content: { Text("This is a test.") }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("@context"))
        #expect(jsonLD.contains("schema.org"))
        #expect(jsonLD.contains("@type"))
        #expect(jsonLD.contains("FAQPage"))
    }
    
    @Test("FAQ schema contains Question and Answer types")
    func testFAQSchemaQuestionAnswer() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "How does it work?",
                answer: "It works great!",
                content: { Text("It works great!") }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("Question"))
        #expect(jsonLD.contains("Answer"))
        #expect(jsonLD.contains("name"))
        #expect(jsonLD.contains("acceptedAnswer"))
        #expect(jsonLD.contains("text"))
    }
    
    @Test("FAQ schema includes question text")
    func testFAQSchemaQuestionText() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "What makes P256K different?",
                answer: "Modern Swift APIs.",
                content: { Text("Modern Swift APIs.") }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("What makes P256K different?"))
    }
    
    @Test("FAQ schema includes answer text")
    func testFAQSchemaAnswerText() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "Question?",
                answer: "The answer with specific text.",
                content: { Text("The answer with specific text.") }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("The answer with specific text."))
    }
    
    @Test("FAQ schema supports HTML in answer text")
    func testFAQSchemaHTMLAnswer() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "Where can I learn more?",
                answer: "Visit our <a href=\"https://docs.example.com\">documentation</a> for details.",
                content: {
                    Div {
                        Text("Visit our ")
                        Link("documentation", destination: URL(string: "https://docs.example.com")!)
                        Text(" for details.")
                    }
                }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        // JSONEncoder escapes forward slashes
        #expect(jsonLD.contains("docs.example.com"))
    }
    
    // MARK: - Multiple Items Tests
    
    @Test("FAQ schema includes all items in mainEntity array")
    func testFAQSchemaMultipleItems() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "First question?",
                answer: "First answer.",
                content: { Text("First answer.") }
            ),
            FAQItem(
                question: "Second question?",
                answer: "Second answer.",
                content: { Text("Second answer.") }
            ),
            FAQItem(
                question: "Third question?",
                answer: "Third answer.",
                content: { Text("Third answer.") }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("mainEntity"))
        #expect(jsonLD.contains("First question?"))
        #expect(jsonLD.contains("Second question?"))
        #expect(jsonLD.contains("Third question?"))
    }
    
    // MARK: - FAQItem Model Tests
    
    @Test("FAQItem stores question correctly")
    func testFAQItemQuestion() {
        let item = FAQItem(
            question: "Test question?",
            answer: "Test answer.",
            content: { Text("Test answer.") }
        )
        
        #expect(item.question == "Test question?")
    }
    
    @Test("FAQItem stores answer HTML correctly")
    func testFAQItemAnswer() {
        let item = FAQItem(
            question: "Question?",
            answer: "HTML <b>answer</b> text.",
            content: { Text("Answer text.") }
        )
        
        #expect(item.answer == "HTML <b>answer</b> text.")
    }
    
    @Test("FAQItem generates valid JSON-LD object")
    func testFAQItemJSONLD() {
        let item = FAQItem(
            question: "What is this?",
            answer: "This is the answer.",
            content: { Text("This is the answer.") }
        )
        
        let jsonLD = item.jsonLD
        
        #expect(jsonLD.contains("\"@type\": \"Question\""))
        #expect(jsonLD.contains("\"name\": \"What is this?\""))
        #expect(jsonLD.contains("\"acceptedAnswer\""))
        #expect(jsonLD.contains("\"@type\": \"Answer\""))
        #expect(jsonLD.contains("\"text\": \"This is the answer.\""))
    }
    
    // MARK: - FAQ jsonLD Property Tests
    
    @Test("FAQ generates schema with correct structure")
    func testFAQSchemaStructure() throws {
        let items = [
            FAQItem(
                question: "Q1?",
                answer: "A1.",
                content: { Text("A1.") }
            ),
            FAQItem(
                question: "Q2?",
                answer: "A2.",
                content: { Text("A2.") }
            )
        ]
        
        let faq = FAQ(items: items)
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        // JSONEncoder escapes forward slashes, so check for key parts
        #expect(jsonLD.contains("@context"))
        #expect(jsonLD.contains("schema.org"))
        #expect(jsonLD.contains("\"@type\" : \"FAQPage\""))
        #expect(jsonLD.contains("mainEntity"))
        #expect(jsonLD.contains("Q1?"))
        #expect(jsonLD.contains("Q2?"))
    }
    
    // MARK: - Edge Cases
    
    @Test("FAQ handles empty items array")
    func testFAQEmptyItems() throws {
        let faq = FAQ(items: [])
        
        let html = try TestUtils.renderHTML(faq)
        
        // Should render without crashing
        #expect(html.contains("<div"))
    }
    
    @Test("FAQ handles special characters in question/answer")
    func testFAQSpecialCharacters() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "What about \"quotes\" & ampersands?",
                answer: "They're handled correctly.",
                content: { Text("They're handled correctly.") }
            )
        ])
        
        let html = try TestUtils.renderHTML(faq)
        
        // Should escape properly for JSON
        #expect(html.contains("quotes"))
        #expect(html.contains("ampersands"))
    }
    
    // MARK: - JSON-LD Filtering Tests
    
    @Test("FAQ excludes items with includeInJSONLD=false from JSON-LD")
    func testFAQExcludesItemsFromJSONLD() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "Included question?",
                answer: "Included answer.",
                includeInJSONLD: true,
                content: { Text("Included answer.") }
            ),
            FAQItem(
                question: "Excluded question?",
                answer: "Excluded answer.",
                includeInJSONLD: false,
                content: { Text("Excluded answer.") }
            )
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("Included question?"))
        #expect(!jsonLD.contains("Excluded question?"))
    }
    
    @Test("FAQ shows all items visually regardless of includeInJSONLD")
    func testFAQShowsAllItemsVisually() throws {
        let faq = FAQ(items: [
            FAQItem(
                question: "Visible question 1?",
                answer: "Answer 1.",
                includeInJSONLD: true,
                content: { Text("Answer 1.") }
            ),
            FAQItem(
                question: "Visible question 2?",
                answer: "Answer 2.",
                includeInJSONLD: false,
                content: { Text("Answer 2.") }
            )
        ])
        
        let html = try TestUtils.renderHTML(faq)
        
        // Both should appear in the visual accordion
        #expect(html.contains("Visible question 1?"))
        #expect(html.contains("Visible question 2?"))
    }
    
    @Test("FAQItem includeInJSONLD defaults to true")
    func testFAQItemIncludeInJSONLDDefault() {
        let item = FAQItem(
            question: "Default test?",
            answer: "Default answer.",
            content: { Text("Default answer.") }
        )
        
        #expect(item.includeInJSONLD == true)
    }
    
    @Test("FAQItem includeInJSONLD can be set to false")
    func testFAQItemIncludeInJSONLDFalse() {
        let item = FAQItem(
            question: "Test?",
            answer: "Answer.",
            includeInJSONLD: false,
            content: { Text("Answer.") }
        )
        
        #expect(item.includeInJSONLD == false)
    }
}
