//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Enumeration of supported sponsor logos with their corresponding views.
public enum SponsorLogo: Sendable {
    case geyser
    case openSats
    
    /// Creates the appropriate logo view for the sponsor
    @ViewBuilder
    public func logoView() -> some View {
        switch self {
        case .geyser:
            GeyserLogo()
        case .openSats:
            OpenSatsLogo()
        }
    }
}
