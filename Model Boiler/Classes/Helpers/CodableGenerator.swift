//
//  CodableGenerator.swift
//  Model Boiler
//
//  Created by Jakob Mygind on 09/03/2020.
//  Copyright © 2020 Nodes. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSemantics

class Generator {
    
    let source: String
    
    init(source: String) {
        self.source = source
    }
    
    var encode: [String] = ["""
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
    """
    ]
    
    var initStrings: [String] = ["""
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
        """
    ]
    
    var codingKeys: [String] = ["""
            enum CodingKeys: String, CodingKey {
            """
    ]
    
    func addNode(name: String, type: String, isOptional: Bool = false) {
        encode.append("    try container.encode(\(name), forKey: .\(name))")
        if isOptional {
            initStrings.append("    \(name) = try container.decodeIfPresent(\(type.trimmingCharacters(in: .init(charactersIn: "?"))).self, forKey: .\(name))")
        } else {
            initStrings.append("    \(name) = try container.decode(\(type).self, forKey: .\(name))")
        }
        codingKeys.append("    case \(name) = \"\(name)\"")
    }
    
    func generate() throws -> String {
        var collector = DeclarationCollector()
        let tree = try SyntaxParser.parse(source: source)
        tree.walk(&collector)
        
        for v in collector.variables {
            addNode(name: v.name, type: v.typeAnnotation!, isOptional: v.typeAnnotation!.contains("?"))
        }
        
        encode.append("}\n")
        initStrings.append("}")
        codingKeys.append("}\n")
        
        return codingKeys.joined(separator: "\n") + encode.joined(separator: "\n") + initStrings.joined(separator: "\n")
    }
}

