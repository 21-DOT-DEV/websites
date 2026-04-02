//
//  FAQPageSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org FAQPage type for FAQ structured data.
/// https://schema.org/FAQPage
public struct FAQPageSchema: Schema {
    public static let schemaType = "FAQPage"
    
    private let type = "FAQPage"
    public let mainEntity: [QuestionSchema]
    
    /// Creates an FAQPage schema from an array of questions.
    public init(questions: [QuestionSchema]) {
        self.mainEntity = questions
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case mainEntity
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(mainEntity, forKey: .mainEntity)
    }
}

/// Schema.org Question type for FAQ items.
/// https://schema.org/Question
public struct QuestionSchema: Encodable, Sendable {
    private let type = "Question"
    public let name: String
    public let acceptedAnswer: AnswerSchema
    
    /// Creates a Question schema.
    public init(question: String, answer: String) {
        self.name = question
        self.acceptedAnswer = AnswerSchema(text: answer)
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name
        case acceptedAnswer
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(acceptedAnswer, forKey: .acceptedAnswer)
    }
}

/// Schema.org Answer type for FAQ answers.
/// https://schema.org/Answer
public struct AnswerSchema: Encodable, Sendable {
    private let type = "Answer"
    public let text: String
    
    /// Creates an Answer schema.
    public init(text: String) {
        self.text = text
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case text
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(text, forKey: .text)
    }
}
