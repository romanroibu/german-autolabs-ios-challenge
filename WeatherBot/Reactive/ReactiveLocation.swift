//
//  ReactiveLocation.swift
//  WeatherBot
//
//  Created by Roman Roibu on 24/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import CoreLocation
import ReactiveSwift
import Result

public typealias Coordinate = (latitude: Double, longitude: Double)

public enum LocationError: Error {
    case unknown
    case locationUnknown
    case denied
    case network
    case deferredFailed
    case deferredAccuracyTooLow
    case deferredCanceled
    case authorization(LocationAuthorizationError)
}

extension LocationError {
    internal init(clerror: CLError) {
        switch clerror.code {
        case .locationUnknown: self = .locationUnknown
        case .denied: self = .denied
        case .network: self = .network
        case .deferredFailed: self = .deferredFailed
        case .deferredAccuracyTooLow: self = .deferredAccuracyTooLow
        case .deferredCanceled: self = .deferredCanceled
        default: self = .unknown
        }
    }
}

public enum LocationAuthorizationLevel {
    case whenInUse
    case always
}

public enum LocationAuthorizationError: Error {
    case denied
    case restricted
}

public protocol ReactiveLocationService {
    static var singleCoordinate: SignalProducer<Coordinate, LocationError> { get }
    static func requestAuthorization(desired: LocationAuthorizationLevel) -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError>
}

internal final class ReactiveLocationDelegate: NSObject, CLLocationManagerDelegate {

    private let didChangeAuthorizationStatusPipe = Signal<CLAuthorizationStatus, NoError>.pipe()

    private let didUpdateLocationsPipe = Signal<[CLLocation], NoError>.pipe()

    private let didFailPipe = Signal<Error, NoError>.pipe()

    internal var didChangeAuthorizationStatus: Signal<CLAuthorizationStatus, NoError> {
        return self.didChangeAuthorizationStatusPipe.output
    }

    internal var didUpdateLocations: Signal<[CLLocation], NoError> {
        return self.didUpdateLocationsPipe.output
    }

    internal var didFail: Signal<Error, NoError> {
        return self.didFailPipe.output
    }

    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeAuthorizationStatusPipe.input.send(value: status)
    }

    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFailPipe.input.send(value: error)
    }

    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdateLocationsPipe.input.send(value: locations)
    }
}
