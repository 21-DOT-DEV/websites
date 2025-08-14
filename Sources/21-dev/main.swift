//
//  main.swift
//  21-DOT-DEV/main.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

let homepage = BasePage(title: "21.dev - Bitcoin Development Tools") {
  SiteHeader(
    logoText: "21.dev",
    navigationLinks: [
      NavigationLink(title: "Blog", href: "/blog/"),
      NavigationLink(title: "P256K", href: "/p256k/"),
      NavigationLink(title: "Docs", href: "https://docs.21.dev/", isExternal: true)
    ]
  )
  HeroSection(
    headline: "Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow. 📱",
    primaryButton: HeroCTAButton(
      text: "Get Started",
      href: "https://docs.21.dev/",
      style: .primary,
      isExternal: true
    ),
    secondaryButton: HeroCTAButton(
      text: "View on GitHub",
      href: "https://github.com/21-dot-dev",
      style: .secondary,
      isExternal: true
    )
  )
}

let sitemap: Sitemap = [
  "index.html": homepage
]

// Assumes this file is located in a Sources/ sub-directory of a Swift package.
let projectURL = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()

let outputURL = projectURL.appending(path: "../Websites/21-dev")

try renderSitemap(sitemap, to: outputURL)
