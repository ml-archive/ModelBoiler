//
//  Parser.swift
//  Model Boiler
//
//  Created by Jakob Mygind on 10/03/2020.
//  Copyright © 2020 Nodes. All rights reserved.
//

import Foundation

struct Parser<A> {
    let run: (inout Substring) -> A?
}

extension Parser where A == String {

    static func predicate(_ predicate: @escaping (Character) -> Bool) -> Parser {
        Parser { str in
            let match = str.prefix(while: predicate)
            guard !match.isEmpty else { return nil }
            str.removeFirst(match.count)
            return String(match)
        }
    }

    static let upper: Parser = .predicate { $0.isUppercase }

    static let lower: Parser = .predicate { $0.isLowercase }

    static var word: Parser<String> {
        Parser { str in
            if let lowerMatch = Parser.lower.run(&str) {
                return lowerMatch
            }
            if let upperThenLower = zip(Parser.upper, .lower).run(&str) {
                return upperThenLower.0 + upperThenLower.1
            }
            return Parser.upper.run(&str)
        }
    }
}

extension Parser {
    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        Parser<B> { str in
            guard let match = self.run(&str) else {
                return nil
            }
            return f(match)
        }
    }
}

func zip<A, B>(_ pa: Parser<A>, _ pb: Parser<B>) -> Parser<(A, B)> {
    Parser { str in
        let originalString = str
        guard let a = pa.run(&str) else {
            return nil
        }
        guard let b = pb.run(&str) else {
            str = originalString
            return nil
        }
        return (a, b)
    }
}
