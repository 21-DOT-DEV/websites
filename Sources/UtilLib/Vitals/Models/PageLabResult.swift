//
//  PageLabResult.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Lab results for one URL from PageSpeed Insights — one attempt per
/// form factor.
public struct PageLabResult: Codable, Equatable, Sendable {
    /// The measured URL.
    public let url: String
    /// The mobile-form-factor outcome.
    public let mobile: FormFactorResult
    /// The desktop-form-factor outcome.
    public let desktop: FormFactorResult

    /// Creates a page result with one outcome per form factor.
    public init(url: String, mobile: FormFactorResult, desktop: FormFactorResult) {
        self.url = url
        self.mobile = mobile
        self.desktop = desktop
    }
}
