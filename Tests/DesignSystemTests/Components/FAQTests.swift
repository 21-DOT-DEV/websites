//
//  FAQTests.swift
//  DesignSystemTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
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
    
    // MARK: - Composition Tests (FAQ uses Accordion internally)
    
    @Test("FAQ renders same structure as Accordion")
    func testFAQUsesAccordionInternally() throws {
        // Create equivalent items for both components
        let faqItem = FAQItem(question: "Test question?") {
            Text("Test answer content")
        }
        let accordionItem = AccordionItem(
            question: "Test question?",
            answer: Text("Test answer content")
        )
        
        let faq = FAQ(items: [faqItem])
        let accordion = Accordion(items: [accordionItem])
        
        let faqHTML = try TestUtils.renderHTML(faq)
        let accordionHTML = try TestUtils.renderHTML(accordion)
        
        // Both should use details/summary structure
        #expect(faqHTML.contains("<details"))
        #expect(accordionHTML.contains("<details"))
        #expect(faqHTML.contains("<summary"))
        #expect(accordionHTML.contains("<summary"))
        
        // Both should contain the question and answer
        #expect(faqHTML.contains("Test question?"))
        #expect(accordionHTML.contains("Test question?"))
        #expect(faqHTML.contains("Test answer content"))
        #expect(accordionHTML.contains("Test answer content"))
    }
    
    // MARK: - Basic Structure Tests
    
    @Test("FAQ renders visual accordion with details/summary")
    func testFAQRendersAccordion() throws {
        let faq = FAQ(items: [
            FAQItem(question: "What is P256K?") {
                Text("P256K is a Swift library for secp256k1.")
            }
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
            FAQItem(question: "Test question?", includeInJSONLD: true) {
                Text("Test answer.")
            }
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
            FAQItem(question: "What is this?", includeInJSONLD: true) {
                Text("This is a test.")
            }
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
            FAQItem(question: "How does it work?", includeInJSONLD: true) {
                Text("It works great!")
            }
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
            FAQItem(question: "What makes P256K different?", includeInJSONLD: true) {
                Text("Modern Swift APIs.")
            }
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("What makes P256K different?"))
    }
    
    @Test("FAQ schema includes answer text")
    func testFAQSchemaAnswerText() throws {
        let faq = FAQ(items: [
            FAQItem(question: "Question?", includeInJSONLD: true) {
                Text("The answer with specific text.")
            }
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("The answer with specific text."))
    }
    
    @Test("FAQ schema extracts plain text from rich content")
    func testFAQSchemaPlainTextFromRichContent() throws {
        let faq = FAQ(items: [
            FAQItem(question: "Where can I learn more?", includeInJSONLD: true) {
                Div {
                    Text("Visit our ")
                    Link("documentation", destination: URL(string: "https://docs.example.com")!)
                    Text(" for details.")
                }
            }
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        // Plain text is extracted from content - URLs are not included, only link text
        #expect(jsonLD.contains("Visit our"))
        #expect(jsonLD.contains("documentation"))
        #expect(jsonLD.contains("for details"))
    }
    
    // MARK: - Multiple Items Tests
    
    @Test("FAQ schema includes all items in mainEntity array")
    func testFAQSchemaMultipleItems() throws {
        let faq = FAQ(items: [
            FAQItem(question: "First question?", includeInJSONLD: true) {
                Text("First answer.")
            },
            FAQItem(question: "Second question?", includeInJSONLD: true) {
                Text("Second answer.")
            },
            FAQItem(question: "Third question?", includeInJSONLD: true) {
                Text("Third answer.")
            }
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
        let item = FAQItem(question: "Test question?") {
            Text("Test answer.")
        }
        
        #expect(item.question == "Test question?")
    }
    
    @Test("FAQItem derives answer from content")
    func testFAQItemAnswer() {
        let item = FAQItem(question: "Question?") {
            Text("Answer text.")
        }
        
        #expect(item.answer.contains("Answer text"))
    }
    
    // MARK: - FAQ Schema Tests
    
    @Test("FAQ generates schema with correct structure")
    func testFAQSchemaStructure() throws {
        let items = [
            FAQItem(question: "Q1?", includeInJSONLD: true) {
                Text("A1.")
            },
            FAQItem(question: "Q2?", includeInJSONLD: true) {
                Text("A2.")
            }
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
            FAQItem(question: "What about \"quotes\" & ampersands?") {
                Text("They're handled correctly.")
            }
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
            FAQItem(question: "Included question?", includeInJSONLD: true) {
                Text("Included answer.")
            },
            FAQItem(question: "Excluded question?") {
                Text("Excluded answer.")
            }
        ])
        
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        #expect(jsonLD.contains("Included question?"))
        #expect(!jsonLD.contains("Excluded question?"))
    }
    
    @Test("FAQ shows all items visually regardless of includeInJSONLD")
    func testFAQShowsAllItemsVisually() throws {
        let faq = FAQ(items: [
            FAQItem(question: "Visible question 1?", includeInJSONLD: true) {
                Text("Answer 1.")
            },
            FAQItem(question: "Visible question 2?") {
                Text("Answer 2.")
            }
        ])
        
        let html = try TestUtils.renderHTML(faq)
        
        // Both should appear in the visual accordion
        #expect(html.contains("Visible question 1?"))
        #expect(html.contains("Visible question 2?"))
    }
    
    @Test("FAQItem includeInJSONLD defaults to false for SEO safety")
    func testFAQItemIncludeInJSONLDDefault() {
        let item = FAQItem(question: "Default test?") {
            Text("Default answer.")
        }
        
        #expect(item.includeInJSONLD == false)
    }
    
    @Test("FAQItem includeInJSONLD can be set to true")
    func testFAQItemIncludeInJSONLDTrue() {
        let item = FAQItem(question: "Test?", includeInJSONLD: true) {
            Text("Answer.")
        }
        
        #expect(item.includeInJSONLD == true)
    }
}
