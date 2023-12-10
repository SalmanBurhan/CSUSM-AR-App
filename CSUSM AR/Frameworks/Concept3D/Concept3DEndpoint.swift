//
//  Concept3DEndpoint.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import Foundation

enum Concept3DEndpoint {
    case locations
    case location(_ id: Int)
    case categories(_ id: Int)
    case cmsImage(path: String, width: Int, height: Int, scaled: Bool = true)
    case iconImage(path: String)
}
