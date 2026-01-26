//
//  SoftwareSourceCodeSchema.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org SoftwareSourceCode type for open source project structured data.
/// https://schema.org/SoftwareSourceCode
public struct SoftwareSourceCodeSchema: Schema {
    public static let schemaType = "SoftwareSourceCode"
    
    private let type = "SoftwareSourceCode"
    public let id: String?
    public let name: String
    public let description: String?
    public let url: String?
    public let mainEntityOfPage: WebPageSchema?
    public let codeRepository: String
    public let programmingLanguage: ComputerLanguageSchema?
    public let license: String?
    public let author: SchemaReference?
    public let creator: SchemaReference?
    public let runtimePlatform: [String]?
    public let sameAs: [String]?
    public let softwareVersion: String?
    public let keywords: [String]?
    public let isBasedOn: String?
    public let potentialAction: [PotentialActionSchema]?
    public let applicationCategory: [String]?
    
    /// Creates a SoftwareSourceCode schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/packages/p256k/#software)
    ///   - name: Project/library name
    ///   - description: Brief description of the source code
    ///   - url: Canonical landing page URL for the software
    ///   - mainEntityOfPage: WebPage that this entity is the main subject of
    ///   - codeRepository: URL to the source code repository (e.g., GitHub)
    ///   - programmingLanguage: Primary programming language as ComputerLanguage object
    ///   - license: License URL (e.g., https://opensource.org/licenses/MIT)
    ///   - author: Reference to the author organization/person (@id only)
    ///   - creator: Reference to the creator organization/person (@id only)
    ///   - runtimePlatform: Supported runtime platforms (e.g., iOS, macOS, Linux)
    ///   - sameAs: URLs of pages that represent the same entity (e.g., GitHub, docs)
    ///   - softwareVersion: Software version string
    ///   - keywords: Keywords for topical classification
    ///   - isBasedOn: URL of the project this is based on
    ///   - potentialAction: Actions that can be performed (e.g., ReadAction, ViewAction)
    ///   - applicationCategory: Categories for classification (e.g., DeveloperApplication)
    public init(
        id: String? = nil,
        name: String,
        description: String? = nil,
        url: String? = nil,
        mainEntityOfPage: WebPageSchema? = nil,
        codeRepository: String,
        programmingLanguage: ComputerLanguageSchema? = nil,
        license: String? = nil,
        author: SchemaReference? = nil,
        creator: SchemaReference? = nil,
        runtimePlatform: [String]? = nil,
        sameAs: [String]? = nil,
        softwareVersion: String? = nil,
        keywords: [String]? = nil,
        isBasedOn: String? = nil,
        potentialAction: [PotentialActionSchema]? = nil,
        applicationCategory: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.url = url
        self.mainEntityOfPage = mainEntityOfPage
        self.codeRepository = codeRepository
        self.programmingLanguage = programmingLanguage
        self.license = license
        self.author = author
        self.creator = creator
        self.runtimePlatform = runtimePlatform
        self.sameAs = sameAs
        self.softwareVersion = softwareVersion
        self.keywords = keywords
        self.isBasedOn = isBasedOn
        self.potentialAction = potentialAction
        self.applicationCategory = applicationCategory
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case name
        case description
        case url
        case mainEntityOfPage
        case codeRepository
        case programmingLanguage
        case license
        case author
        case creator
        case runtimePlatform
        case sameAs
        case softwareVersion
        case keywords
        case isBasedOn
        case potentialAction
        case applicationCategory
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(mainEntityOfPage, forKey: .mainEntityOfPage)
        try container.encode(codeRepository, forKey: .codeRepository)
        try container.encodeIfPresent(programmingLanguage, forKey: .programmingLanguage)
        try container.encodeIfPresent(license, forKey: .license)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(creator, forKey: .creator)
        try container.encodeIfPresent(runtimePlatform, forKey: .runtimePlatform)
        try container.encodeIfPresent(sameAs, forKey: .sameAs)
        try container.encodeIfPresent(softwareVersion, forKey: .softwareVersion)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encodeIfPresent(isBasedOn, forKey: .isBasedOn)
        try container.encodeIfPresent(potentialAction, forKey: .potentialAction)
        try container.encodeIfPresent(applicationCategory, forKey: .applicationCategory)
    }
}

/// Schema.org WebPage type for mainEntityOfPage references.
/// https://schema.org/WebPage
public struct WebPageSchema: Encodable, Sendable {
    private let type = "WebPage"
    public let id: String
    
    /// Creates a WebPage schema reference.
    /// - Parameter id: The canonical URL of the web page
    public init(id: String) {
        self.id = id
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
    }
}

/// Schema.org ComputerLanguage type for programming language.
/// https://schema.org/ComputerLanguage
public struct ComputerLanguageSchema: Encodable, Sendable {
    private let type = "ComputerLanguage"
    public let name: String
    
    /// Creates a ComputerLanguage schema.
    /// - Parameter name: The name of the programming language (e.g., "Swift")
    public init(name: String) {
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
    }
}

/// Schema.org Action type for potentialAction.
/// Supports ReadAction, ViewAction, DownloadAction, etc.
public struct PotentialActionSchema: Encodable, Sendable {
    public let type: ActionType
    public let target: String
    
    /// Action types for potentialAction.
    public enum ActionType: String, Sendable {
        case read = "ReadAction"
        case view = "ViewAction"
        case download = "DownloadAction"
    }
    
    /// Creates a PotentialAction schema.
    /// - Parameters:
    ///   - type: The type of action (ReadAction, ViewAction, etc.)
    ///   - target: The URL target of the action
    public init(type: ActionType, target: String) {
        self.type = type
        self.target = target
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case target
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(target, forKey: .target)
    }
}
