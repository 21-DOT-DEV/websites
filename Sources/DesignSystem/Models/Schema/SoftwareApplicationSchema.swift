//
//  SoftwareApplicationSchema.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org SoftwareApplication type for software/library structured data.
/// https://schema.org/SoftwareApplication
public struct SoftwareApplicationSchema: Schema {
    public static let schemaType = "SoftwareApplication"
    
    private let type = "SoftwareApplication"
    public let name: String
    public let description: String?
    public let applicationCategory: String?
    public let operatingSystem: String?
    public let url: String?
    public let downloadUrl: String?
    public let author: SchemaReference?
    public let license: String?
    public let programmingLanguage: String?
    public let softwareVersion: String?
    
    /// Creates a SoftwareApplication schema.
    /// - Parameters:
    ///   - name: Application/library name
    ///   - description: Brief description
    ///   - applicationCategory: Category (e.g., "DeveloperApplication", "Library")
    ///   - operatingSystem: Supported OS (e.g., "iOS, macOS, Linux")
    ///   - url: Project URL
    ///   - downloadUrl: Download/repository URL
    ///   - author: Reference to an Organization or Person schema via @id
    ///   - license: License URL or name
    ///   - programmingLanguage: Primary programming language
    ///   - softwareVersion: Current version
    public init(
        name: String,
        description: String? = nil,
        applicationCategory: String? = nil,
        operatingSystem: String? = nil,
        url: String? = nil,
        downloadUrl: String? = nil,
        author: SchemaReference? = nil,
        license: String? = nil,
        programmingLanguage: String? = nil,
        softwareVersion: String? = nil
    ) {
        self.name = name
        self.description = description
        self.applicationCategory = applicationCategory
        self.operatingSystem = operatingSystem
        self.url = url
        self.downloadUrl = downloadUrl
        self.author = author
        self.license = license
        self.programmingLanguage = programmingLanguage
        self.softwareVersion = softwareVersion
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name
        case description
        case applicationCategory
        case operatingSystem
        case url
        case downloadUrl
        case author
        case license
        case programmingLanguage
        case softwareVersion
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(applicationCategory, forKey: .applicationCategory)
        try container.encodeIfPresent(operatingSystem, forKey: .operatingSystem)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(downloadUrl, forKey: .downloadUrl)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(license, forKey: .license)
        try container.encodeIfPresent(programmingLanguage, forKey: .programmingLanguage)
        try container.encodeIfPresent(softwareVersion, forKey: .softwareVersion)
    }
}

/// A reference to another schema entity via @id.
/// Used to link schemas in the @graph (e.g., SoftwareApplication's author → Organization).
public struct SchemaReference: Encodable, Sendable {
    public let id: String
    
    /// Creates a reference to another schema by its @id.
    public init(id: String) {
        self.id = id
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "@id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}
