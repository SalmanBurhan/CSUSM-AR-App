//
//  ExploreARView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import SwiftUI
import ARKit

struct ExploreARView: UIViewControllerRepresentable {
    
    let locations: [Concept3DLocation]

    init(_ locations: [Concept3DLocation]) {
        self.locations = locations
    }
    
    func makeUIViewController(context: Context) -> ExploreARViewController {
        return ExploreARViewController(locations)
    }
    
    func updateUIViewController(_ uiViewController: ExploreARViewController, context: Context) { }
}

