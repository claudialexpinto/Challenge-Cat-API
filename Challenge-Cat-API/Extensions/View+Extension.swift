//
//  View+Extension.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 05/09/2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

