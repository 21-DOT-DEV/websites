//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
import Slipstream
@testable import DesignSystem

//
//  TDD tests for FAQItem auto-derived answer feature
//

@Suite("FAQItem Auto-Derived Answer Tests")
struct FAQItemAutoAnswerTests {
    
    // MARK: - New API Tests (content-only initializer)
    
    @Test("FAQItem can be created with question and content only")
    func testContentOnlyInitializer() throws {
        let item = FAQItem(question: "What is P256K?") {
            Text("P256K is a Swift library.")
        }
        
        #expect(item.question == "What is P256K?")
    }
    
    @Test("FAQItem auto-derives answer from simple Text content")
    func testAutoDerivesAnswerFromText() throws {
        let item = FAQItem(question: "What is P256K?") {
            Text("P256K is a Swift library for secp256k1.")
        }
        
        #expect(item.answer.contains("P256K is a Swift library"))
    }
    
    @Test("FAQItem auto-derives answer from rich content with links")
    func testAutoDerivesAnswerFromRichContent() throws {
        let item = FAQItem(question: "Where can I find docs?") {
            Div {
                Span("Visit our ")
                Link("documentation site", destination: URL(string: "https://docs.21.dev")!)
                Span(" for details.")
            }
        }
        
        let answer = item.answer
        #expect(answer.contains("Visit our"))
        #expect(answer.contains("documentation site"))
        #expect(answer.contains("for details"))
        // Should NOT contain HTML tags or attributes
        #expect(!answer.contains("<"))
        #expect(!answer.contains("href"))
    }
    
    @Test("FAQItem includeInJSONLD defaults to false with content-only init")
    func testIncludeInJSONLDDefaultsFalse() throws {
        let item = FAQItem(question: "Test?") {
            Text("Answer.")
        }
        
        #expect(item.includeInJSONLD == false)
    }
    
    @Test("FAQItem includeInJSONLD can be set to true with content-only init")
    func testIncludeInJSONLDCanBeTrue() throws {
        let item = FAQItem(
            question: "Test?",
            includeInJSONLD: true
        ) {
            Text("Answer.")
        }
        
        #expect(item.includeInJSONLD == true)
    }
    
    @Test("FAQItem content is accessible")
    func testContentAccessible() throws {
        let item = FAQItem(question: "Test?") {
            Text("Test answer content.")
        }
        
        let html = try renderHTML(item.content)
        #expect(html.contains("Test answer content"))
    }
    
    // MARK: - Schema Integration Tests
    
    @Test("FAQ schema uses auto-derived answer")
    func testSchemaUsesAutoDerivedAnswer() throws {
        let item = FAQItem(
            question: "What is this?",
            includeInJSONLD: true
        ) {
            Div {
                Span("This is ")
                Link("the answer", destination: URL(string: "https://example.com")!)
                Span(".")
            }
        }
        
        let faq = FAQ(items: [item])
        let graph = SchemaGraph(faq.schema)
        let jsonLD = try graph.render()
        
        // JSON-LD should contain the plain text answer
        #expect(jsonLD.contains("This is"))
        #expect(jsonLD.contains("the answer"))
        // Should NOT contain HTML
        #expect(!jsonLD.contains("<a"))
        #expect(!jsonLD.contains("href"))
    }
}
