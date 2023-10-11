//
//  ICalComponent.swift
//  
//
//

import Foundation
import SwiftSoup

public struct ICalComponent {
    let properties: [(name: String, value: String)]
    let children: [(name: String, value: String)]
    
    func findProperty(name: String) -> (name: String, value: String)? {
        return properties
            .filter { $0.name.hasPrefix(name) }
            .first
    }
    
    func findProperties(name: String) -> [(name: String, value: String)]? {
        return properties.filter { $0.name.hasPrefix(name) }
    }
    
    func findExtendProperties() -> [String: String] {
        var dict = [String: String]()
        
        properties
            .filter { $0.name.hasPrefix("X-") && !$0.name.hasPrefix(Constant.Prop.trumbaCustomField) }
            .forEach {
                dict[$0.name] = $0.value
            }
        
        return dict
    }
        
    // DateTime
    func buildProperty(of name: String) -> ICalDateTime? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
       
        return PropertyBuilder.buildDateTime(propName: prop.name, value: prop.value)
    }
    
    // Int
    func buildProperty(of name: String) -> Int? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
        
        return Int(prop.value)
    }
    
    // String
    func buildProperty(of name: String) -> String? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
        
        let value = prop.value
            .replacing(pattern: "\\\\,", with: ",")
            .replacing(pattern: "\\\\;", with: ";")
            .replacing(pattern: "\\\\[nN]", with: "\n")
            .replacing(pattern: "\\\\{2}", with: "\\\\")
        
        if (name == Constant.Prop.description) {
            return PropertyBuilder.buildDescription(html: value)
        }
        return try? Entities.unescape(value)
    }
    
    // Duration
    func buildProperty(of name: String) -> ICalDuration? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
        
        return PropertyBuilder.buildDuration(value: prop.value)
    }
    
    // Array
    func buildProperty(of name: String) -> [String] {
        guard let prop = findProperty(name: name) else {
            return []
        }
        
        return prop.value.components(separatedBy: ",")
    }
    
    // RRule
    func buildProperty(of name: String) -> ICalRRule? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
        
        return PropertyBuilder.buildRRule(value: prop.value)
    }
    
    // URL
    func buildProperty(of name: String) -> URL? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
        
        if name == Constant.Prop.trumbaImage {
            return PropertyBuilder.buildImage(value: prop.value)
        }
        return URL(string: prop.value)
    }

    // Attachment
    func buildProperty(of name: String) -> [ICalAttachment]? {
        guard let properties = findProperties(name: name) else {
            return nil
        }
        
        return properties.compactMap { prop in
            PropertyBuilder.buildAttachment(propName: prop.name, value: prop.value)
        }
    }
    
    // DateTimes
    func buildProperty(of name: String) -> ICalDateTimes? {
        guard let prop = findProperty(name: name) else {
            return nil
        }
        
        return PropertyBuilder.buildDateTimes(propName: prop.name, value: prop.value)
    }
    
    func buildProperty(of name: String) -> [XTrumbaField]? {
        guard let properties = findProperties(name: name) else {
            return nil
        }
        
        return properties.compactMap({ prop in
            PropertyBuilder.buildTrumbaField(propName: prop.name, value: prop.value)
        })
    }
}
