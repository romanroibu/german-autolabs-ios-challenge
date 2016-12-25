//
//  ReactiveNetworking.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public protocol NetworkService {
    func load<T>(_ request: Request<T>) -> SignalProducer<T, AnyError>
}

public final class ReactiveURLSession: NetworkService {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
    }

    public func load<T>(_ request: Request<T>) -> SignalProducer<T, AnyError> {
        return self.session
            .reactive
            .data(with: request.urlRequest)
            .flatMap(.latest) { (data, response) -> SignalProducer<T, AnyError> in
                //TODO: Return error signal if response code is not between 200 and 299
                do {
                    let value = try request.parse(data)
                    return SignalProducer(value: value)
                } catch {
                    let anyError = AnyError(error)
                    return SignalProducer(error: anyError)
                }
            }
    }
}
