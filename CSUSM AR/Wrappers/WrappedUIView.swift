//
//  WrappedUIView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import Foundation
import SwiftUI

@_documentation(visibility:private)
struct WrappedUIView<T: UIView>: UIViewRepresentable {
    
    typealias UIViewType = T
    
    let unwrappedView: T
    var configure: (T) -> Void

    init(_ configure: @escaping (T) -> Void) {
        self.unwrappedView = T()
        self.configure = configure
    }

    func makeUIView(context: Context) -> T {
        self.configure(unwrappedView)
        return self.unwrappedView
    }

    func updateUIView(_ uiView: T, context: Context) {
        
    }
}
