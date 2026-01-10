//
//  AccordionTests.swift
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

struct AccordionTests {
    
    // MARK: - Basic Structure Tests
    
    @Test("Accordion renders with details/summary HTML elements")
    func testAccordionUsesDetailsSummary() throws {
        let accordion = Accordion(items: [
            AccordionItem(
                question: "Test question?",
                answer: Text("Test answer")
            )
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        // Should use native details/summary elements
        #expect(html.contains("<details"))
        #expect(html.contains("<summary"))
        #expect(html.contains("</details>"))
        #expect(html.contains("</summary>"))
    }
    
    @Test("Accordion renders question in summary element")
    func testAccordionQuestionInSummary() throws {
        let accordion = Accordion(items: [
            AccordionItem(
                question: "What is P256K?",
                answer: Text("A Swift library")
            )
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        #expect(html.contains("<summary"))
        #expect(html.contains("What is P256K?"))
    }
    
    @Test("Accordion renders answer content after summary")
    func testAccordionAnswerContent() throws {
        let accordion = Accordion(items: [
            AccordionItem(
                question: "Question?",
                answer: Text("This is the answer content")
            )
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        #expect(html.contains("This is the answer content"))
        // Answer should be outside summary but inside details
        #expect(html.contains("</summary>"))
    }
    
    @Test("Accordion renders multiple items")
    func testAccordionMultipleItems() throws {
        let accordion = Accordion(items: [
            AccordionItem(question: "Question 1?", answer: Text("Answer 1")),
            AccordionItem(question: "Question 2?", answer: Text("Answer 2")),
            AccordionItem(question: "Question 3?", answer: Text("Answer 3"))
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        // Should have 3 details elements
        let detailsCount = html.components(separatedBy: "<details").count - 1
        #expect(detailsCount == 3)
        
        #expect(html.contains("Question 1?"))
        #expect(html.contains("Question 2?"))
        #expect(html.contains("Question 3?"))
        #expect(html.contains("Answer 1"))
        #expect(html.contains("Answer 2"))
        #expect(html.contains("Answer 3"))
    }
    
    // MARK: - Open State Tests
    
    @Test("Accordion items are closed by default")
    func testAccordionClosedByDefault() throws {
        let accordion = Accordion(items: [
            AccordionItem(question: "Question?", answer: Text("Answer"))
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        // Should NOT have open attribute by default
        #expect(!html.contains("<details open"))
    }
    
    @Test("Accordion respects isDefaultOpen parameter")
    func testAccordionDefaultOpen() throws {
        let accordion = Accordion(items: [
            AccordionItem(
                question: "Open question?",
                answer: Text("Visible answer"),
                isDefaultOpen: true
            )
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        // Should have open attribute
        #expect(html.contains("open"))
    }
    
    // MARK: - Rich Content Tests
    
    @Test("Accordion supports rich content in answers")
    func testAccordionRichContent() throws {
        let accordion = Accordion(items: [
            AccordionItem(
                question: "Where can I learn more?",
                answer: Div {
                    Span("Visit our ")
                    Link("documentation", destination: URL(string: "https://docs.example.com")!)
                    Span(" for more info.")
                }
            )
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        #expect(html.contains("Visit our"))
        #expect(html.contains("<a"))
        #expect(html.contains("documentation"))
        #expect(html.contains("https://docs.example.com"))
    }
    
    // MARK: - Empty/Edge Cases
    
    @Test("Accordion handles empty items array")
    func testAccordionEmptyArray() throws {
        let accordion = Accordion(items: [])
        
        let html = try TestUtils.renderHTML(accordion)
        
        // Should render container without crashing
        #expect(html.contains("<div"))
    }
    
    @Test("Accordion handles single item")
    func testAccordionSingleItem() throws {
        let accordion = Accordion(items: [
            AccordionItem(question: "Solo question?", answer: Text("Solo answer"))
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        #expect(html.contains("<details"))
        #expect(html.contains("Solo question?"))
        #expect(html.contains("Solo answer"))
    }
    
    // MARK: - Styling Tests
    
    @Test("Accordion applies styling classes")
    func testAccordionStyling() throws {
        let accordion = Accordion(items: [
            AccordionItem(question: "Styled question?", answer: Text("Styled answer"))
        ])
        
        let html = try TestUtils.renderHTML(accordion)
        
        // Should have styling classes for visual appearance
        #expect(html.contains("class="))
    }
    
    // MARK: - StyleModifier Tests
    
    @Test("Accordion StyleModifier provides icon rotation CSS")
    func testAccordionStyleModifierCSS() {
        let accordion = Accordion(items: [
            AccordionItem(question: "Test?", answer: Text("Answer"))
        ])
        
        // Should implement StyleModifier protocol
        #expect(accordion.componentName == "Accordion")
        #expect(accordion.style.contains("details[open] .accordion-icon"))
        #expect(accordion.style.contains("rotate(90deg)"))
        #expect(accordion.style.contains("transition"))
    }
}
