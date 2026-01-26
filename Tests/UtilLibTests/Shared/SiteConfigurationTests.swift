//
//  SiteConfigurationTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import UtilLib

@Suite("SiteName Enum Tests")
struct SiteNameTests {
    
    // MARK: - Raw Value Tests
    
    @Test("SiteName raw values match expected site identifiers")
    func rawValues() {
        #expect(SiteName.dev21.rawValue == "21-dev")
        #expect(SiteName.docs21dev.rawValue == "docs-21-dev")
        #expect(SiteName.md21dev.rawValue == "md-21-dev")
    }
    
    @Test("SiteName can be initialized from raw value")
    func initFromRawValue() {
        #expect(SiteName(rawValue: "21-dev") == .dev21)
        #expect(SiteName(rawValue: "docs-21-dev") == .docs21dev)
        #expect(SiteName(rawValue: "md-21-dev") == .md21dev)
        #expect(SiteName(rawValue: "invalid") == nil)
    }
    
    // MARK: - Base URL Tests
    
    @Test("SiteName baseURL returns correct URLs")
    func baseURLs() {
        #expect(SiteName.dev21.baseURL == "https://21.dev")
        #expect(SiteName.docs21dev.baseURL == "https://docs.21.dev")
        #expect(SiteName.md21dev.baseURL == "https://md.21.dev")
    }
    
    // MARK: - Output Directory Tests
    
    @Test("SiteName outputDirectory returns correct paths")
    func outputDirectories() {
        #expect(SiteName.dev21.outputDirectory == "Websites/21-dev")
        #expect(SiteName.docs21dev.outputDirectory == "Websites/docs-21-dev")
        #expect(SiteName.md21dev.outputDirectory == "Websites/md-21-dev")
    }
    
    // MARK: - CaseIterable Tests
    
    @Test("SiteName allCases contains all three sites")
    func allCases() {
        #expect(SiteName.allCases.count == 3)
        #expect(SiteName.allCases.contains(.dev21))
        #expect(SiteName.allCases.contains(.docs21dev))
        #expect(SiteName.allCases.contains(.md21dev))
    }
}

@Suite("URLDiscoveryStrategy Tests")
struct URLDiscoveryStrategyTests {
    
    @Test("htmlFiles strategy stores directory path")
    func htmlFilesStrategy() {
        let strategy = URLDiscoveryStrategy.htmlFiles(directory: "Websites/21-dev")
        if case .htmlFiles(let dir) = strategy {
            #expect(dir == "Websites/21-dev")
        } else {
            Issue.record("Expected htmlFiles strategy")
        }
    }
    
    @Test("markdownFiles strategy stores directory path")
    func markdownFilesStrategy() {
        let strategy = URLDiscoveryStrategy.markdownFiles(directory: "Websites/md-21-dev")
        if case .markdownFiles(let dir) = strategy {
            #expect(dir == "Websites/md-21-dev")
        } else {
            Issue.record("Expected markdownFiles strategy")
        }
    }
    
    @Test("sitemapDictionary strategy exists")
    func sitemapDictionaryStrategy() {
        let strategy = URLDiscoveryStrategy.sitemapDictionary
        if case .sitemapDictionary = strategy {
            // Pass
        } else {
            Issue.record("Expected sitemapDictionary strategy")
        }
    }
}

@Suite("LastmodStrategy Tests")
struct LastmodStrategyTests {
    
    @Test("All lastmod strategies are defined")
    func allStrategies() {
        let strategies: [LastmodStrategy] = [
            .gitCommitDate,
            .packageVersionState,
            .currentDate
        ]
        #expect(strategies.count == 3)
    }
}

@Suite("SiteConfiguration Tests")
struct SiteConfigurationTests {
    
    @Test("SiteConfiguration.for returns correct config for dev21")
    func configForDev21() {
        let config = SiteConfiguration.for(.dev21)
        
        #expect(config.name == .dev21)
        #expect(config.baseURL == "https://21.dev")
        #expect(config.outputDirectory == "Websites/21-dev")
        
        if case .htmlFiles = config.urlDiscoveryStrategy {
            // Pass - 21.dev uses HTML files
        } else {
            Issue.record("Expected htmlFiles strategy for dev21")
        }
        
        if case .gitCommitDate = config.lastmodStrategy {
            // Pass - 21.dev uses git commit dates
        } else {
            Issue.record("Expected gitCommitDate strategy for dev21")
        }
    }
    
    @Test("SiteConfiguration.for returns correct config for docs21dev")
    func configForDocs21dev() {
        let config = SiteConfiguration.for(.docs21dev)
        
        #expect(config.name == .docs21dev)
        #expect(config.baseURL == "https://docs.21.dev")
        #expect(config.outputDirectory == "Websites/docs-21-dev")
        
        if case .htmlFiles = config.urlDiscoveryStrategy {
            // Pass - docs uses HTML files from DocC
        } else {
            Issue.record("Expected htmlFiles strategy for docs21dev")
        }
        
        if case .packageVersionState = config.lastmodStrategy {
            // Pass - docs uses package version state
        } else {
            Issue.record("Expected packageVersionState strategy for docs21dev")
        }
    }
    
    @Test("SiteConfiguration.for returns correct config for md21dev")
    func configForMd21dev() {
        let config = SiteConfiguration.for(.md21dev)
        
        #expect(config.name == .md21dev)
        #expect(config.baseURL == "https://md.21.dev")
        #expect(config.outputDirectory == "Websites/md-21-dev")
        
        if case .markdownFiles = config.urlDiscoveryStrategy {
            // Pass - md uses markdown files
        } else {
            Issue.record("Expected markdownFiles strategy for md21dev")
        }
        
        if case .packageVersionState = config.lastmodStrategy {
            // Pass - md uses package version state
        } else {
            Issue.record("Expected packageVersionState strategy for md21dev")
        }
    }
}
