//
//  ModelBoilerTests.swift
//  ModelBoilerTests
//
//  Created by Jakob Mygind on 09/03/2020.
//  Copyright © 2020 Nodes. All rights reserved.
//

import XCTest
@testable import Model_Boiler

class ModelBoilerTests: XCTestCase {
    
    func testParsing() throws {
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
    
    func testEmbedded() {
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
        }
    }
    
    func testTypeInference() throws {
        let str = """
        struct Test {
            var custom = CustomType()
            var custom2 = [CustomType]()
            var intVal = 1
            var doubleVal = 2.33
            var stringVal = "Hello"
            var boolVal = true
        }
        """
        
        let expected = """
        enum CodingKeys: String, CodingKey {
            case custom = "custom"
            case custom2 = "custom2"
            case intVal = "intVal"
            case doubleVal = "doubleVal"
            case stringVal = "stringVal"
            case boolVal = "boolVal"
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(custom, forKey: .custom)
            try container.encode(custom2, forKey: .custom2)
            try container.encode(intVal, forKey: .intVal)
            try container.encode(doubleVal, forKey: .doubleVal)
            try container.encode(stringVal, forKey: .stringVal)
            try container.encode(boolVal, forKey: .boolVal)
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            custom = try container.decode(CustomType.self, forKey: .custom)
            custom2 = try container.decode([CustomType].self, forKey: .custom2)
            intVal = try container.decode(Int.self, forKey: .intVal)
            doubleVal = try container.decode(Double.self, forKey: .doubleVal)
            stringVal = try container.decode(String.self, forKey: .stringVal)
            boolVal = try container.decode(Bool.self, forKey: .boolVal)
        }
        """
        let res = try XCTUnwrap(try Generator(source: str).generate())
        XCTAssertEqual(res, expected)
    }
}
