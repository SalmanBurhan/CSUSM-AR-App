//
//  NavigationToolbar.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/11/23.
//

import Foundation
import SwiftUI

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.backward")
                .font(.title3)
                .padding(11)
                .background {
                    Circle()
                        .fill(Color(.systemBackground))
                }
        }
    }
}

struct BackButtonModifier: ViewModifier {
    @Environment(\.dismiss) var dismiss
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton {
                        dismiss()
                    }
                }
            }
    }
}

extension View {
    func withCustomBackButton() -> some View {
        modifier(BackButtonModifier())
    }
}
