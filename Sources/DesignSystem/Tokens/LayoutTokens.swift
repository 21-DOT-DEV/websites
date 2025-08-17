//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Design tokens for layout constraints and spacing.
public enum MaxWidth: Sendable {
    case fourXL    // max-w-4xl
    case sixXL     // max-w-6xl  
    case full      // max-w-full
    
    /// CSS class name for the max-width constraint
    public var cssClass: String {
        switch self {
        case .fourXL: return "max-w-4xl"
        case .sixXL: return "max-w-6xl"
        case .full: return "max-w-full"
        }
    }
}
