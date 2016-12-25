//
//  JSON.swift
//  WeatherBot
//
//  Created by Roman Roibu on 25/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

//TODO: Move definition inside JSON struct and drop 'JSON' prefix, once Swift allows nested definitions inside generic types
public enum JSONError: Swift.Error {
    case missing(key: String, type: Any.Type)
    case wrongType(expected: Any.Type, got: Any.Type)
}

public struct JSON<Key: RawRepresentable> {
    public typealias Error = JSONError

    private let json: Any

    public init(_ json: Any) {
        self.json = json
    }

    public func cast<T>() throws -> T {
        guard let object = self.json as? T else {
            throw JSON.Error.wrongType(expected: T.self, got: type(of: json))
        }
        return object
    }
}

extension JSON where Key.RawValue == String {
    public func optional<T>(forKey key: Key) throws -> T? {
        let object = try self.cast() as [String: Any]
        guard let anyValue = object[key.rawValue] else {
            return nil
        }
        guard let value = anyValue as? T else {
            throw JSON.Error.missing(key: key.rawValue, type: T.self)
        }
        return value
    }

    public func value<T>(forKey key: Key) throws -> T {
        let object = try self.cast() as [String: Any]
        guard let value = object[key.rawValue] as? T else {
            throw JSON.Error.missing(key: key.rawValue, type: T.self)
        }
        return value
    }
}
