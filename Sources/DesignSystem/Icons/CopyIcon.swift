//
//  CopyIcon.swift
//  21-DOT-DEV/DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//

import Foundation
import Slipstream

/// A copy clipboard icon component
public struct CopyIcon: View {
    public init() {}
    
    public var body: some View {
        RawHTML("""
        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>
            <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>
        </svg>
        """)
    }
}
