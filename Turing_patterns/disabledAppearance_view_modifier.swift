//
//  disabledAppearance_view_modifier.swift
//  Turing_patterns
//
//  Created by David Tudor on 21/07/2025.
//

import Foundation
import SwiftUI

extension View {
    func disabledAppearance(if bool: Bool) -> some View {
        modifier(DisabledAppearance(bool: bool))
    }
}

struct DisabledAppearance: ViewModifier {
    var bool: Bool
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(bool ? .gray : .primary)
            .opacity(bool ? 0.6 : 1.0)
    }
}
