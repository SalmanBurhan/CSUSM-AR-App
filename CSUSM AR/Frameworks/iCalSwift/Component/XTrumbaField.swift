//
//  XTrumbaField.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/9/23.
//

import Foundation

@_documentation(visibility:private)
public struct XTrumbaField {
    public var name: String?
    public var type: String?
    public var id: String?
    public var value: String?
    
    public init(
        name: String? = nil,
        type: String? = nil,
        id: String? = nil ,
        value: String? = nil
    ) {
        self.name = name
        self.type = type
        self.id = id
        self.value = value
    }
}
