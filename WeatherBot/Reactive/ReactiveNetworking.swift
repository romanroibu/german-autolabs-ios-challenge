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
