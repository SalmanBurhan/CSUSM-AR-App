//
//  VComponent.swift
//
//
//

/// A component enclosed by BEGIN: and END:.
@_documentation(visibility:private)
public protocol VComponent: VEncodable {
    /// The component's 'type' that is used in the BEGIN/END
    /// declaration.
    var component: String { get }

    /// The component's properties.
    var properties: [VContentLine?] { get }

    /// The component's children.
    var children: [VComponent] { get }
}

@_documentation(visibility:private)
public extension VComponent {
    var properties: [VContentLine?] { [] }
    var children: [VComponent] { [] }

    var contentLines: [VContentLine?] {
        [.line(Constant.Prop.begin, component)]
        + properties
        + children.flatMap(\.contentLines)
        + [.line(Constant.Prop.end, component)]
    }

    var vEncoded: String {
        contentLines
            .compactMap { $0?.vEncoded }
            .joined()
    }
}
