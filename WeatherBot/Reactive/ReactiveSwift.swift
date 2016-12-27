//
//  ReactiveSwift.swift
//  WeatherBot
//
//  Created by Roman Roibu on 24/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public func merge<T, E>(_ signals: [SignalProducer<T, E>]) -> SignalProducer<T, E> {
    return SignalProducer<SignalProducer<T, E>, E>(signals).flatten(.merge)
}

extension Signal {
    public typealias Pipe = (output: Signal<Value, Error>, input: ReactiveSwift.Observer<Value, Error>)
}
