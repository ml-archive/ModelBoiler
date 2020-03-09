//
//  ModelBoilerTests.swift
//  ModelBoilerTests
//
//  Created by Jakob Mygind on 09/03/2020.
//  Copyright © 2020 Nodes. All rights reserved.
//

import XCTest

class ModelBoilerTests: XCTestCase {
    
    func testExample() throws {
        struct TestStruct: Codable, Equatable {
            init(
                string: String,
                optionalString: String?,
                dictionary: [String : Int],
                optionalDictionary: [String : Int]?
            ) {
                self.string = string
                self.optionalString = optionalString
                self.dictionary = dictionary
                self.optionalDictionary = optionalDictionary
            }
            
            let string: String
            let optionalString: String?
            let dictionary: [String: Int]
            let optionalDictionary: [String: Int]?
            
            enum CodingKeys: String, CodingKey {
                case string = "string"
                case optionalString = "optionalString"
                case dictionary = "dictionary"
                case optionalDictionary = "optionalDictionary"
            }
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(string, forKey: .string)
                try container.encode(optionalString, forKey: .optionalString)
                try container.encode(dictionary, forKey: .dictionary)
                try container.encode(optionalDictionary, forKey: .optionalDictionary)
            }
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                string = try container.decode(String.self, forKey: .string)
                optionalString = try container.decodeIfPresent(String.self, forKey: .optionalString)
                dictionary = try container.decode([String: Int].self, forKey: .dictionary)
                optionalDictionary = try container.decodeIfPresent([String: Int].self, forKey: .optionalDictionary)
            }
        }
        
        do {
            let str = """
        {
            "string": "Test",
            "dictionary": { "Test": 1 }
        }
        """
            
            let test = try JSONDecoder().decode(TestStruct.self, from: str.data(using: .utf8)!)
            
            let compare = TestStruct(string: "Test", optionalString: nil, dictionary: ["Test": 1], optionalDictionary: nil)
            
            XCTAssertEqual(test, compare)
        }
        
        let str = """
               {
                   "string": "Test",
                   "dictionary": { "Test": 1 },
                    "optionalDictionary": { "Test": 2 },
                    "optionalString": "MyOptional"
               }
               """
        
        let test = try JSONDecoder().decode(TestStruct.self, from: str.data(using: .utf8)!)
        
        let compare = TestStruct(string: "Test", optionalString: "MyOptional", dictionary: ["Test": 1], optionalDictionary: ["Test": 2])
        
        XCTAssertEqual(test, compare)
        
    }
    
}
