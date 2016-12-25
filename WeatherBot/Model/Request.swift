//
//  Request.swift
//  WeatherBot
//
//  Created by Roman Roibu on 25/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation
import Result

public struct Request<T> {
    let urlRequest: URLRequest
    let parse: (Data) throws -> T

    public init(_ url: URL, parse: @escaping (Data) throws -> T) {
        self.init(URLRequest(url: url), parse: parse)
    }

    public init(_ url: URL, parseJSON: @escaping (Any) throws -> T) {
        self.init(URLRequest(url: url), parseJSON: parseJSON)
    }

    public init(_ urlRequest: URLRequest, parse: @escaping (Data) throws -> T) {
        self.urlRequest = urlRequest
        self.parse = parse
    }

    public init(_ urlRequest: URLRequest, parseJSON: @escaping (Any) throws -> T) {
        self.urlRequest = urlRequest
        self.parse = { data in
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return try parseJSON(json)
        }
    }
}
