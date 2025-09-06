//
//  Sitemap.swift
//  21-DOT-DEV/Sitemap.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

@main
struct SiteGenerator {
    static func main() throws {
        // Assumes this file is located in a Sources/ sub-directory of a Swift package.
        let projectURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let outputURL = projectURL.appending(path: "../Websites/21-dev")
        
        let stylemap = [
            "static/style.input.css": Homepage.cssComponents,
            "p256k/static/style.input.css": P256KPage.cssComponents
        ]
        
        for style in stylemap {
            try renderStyles(
                from: style.value,
                baseCSS: projectURL.appending(path: "../Resources/21-dev/static/style.base.css"),
                to: projectURL.appending(path: "../Resources/21-dev/\(style.key)")
            )
        }
        
        // Then render site
        let sitemap: Sitemap = [
            "index.html": Homepage.page,
            "p256k/index.html": P256KPage.page
        ]
        
        try renderSitemap(sitemap, to: outputURL)
    }
}
