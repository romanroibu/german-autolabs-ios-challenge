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

public protocol LocationService {
    static var singleCoordinate: SignalProducer<Coordinate, LocationError> { get }
    static func requestAuthorization(desired: LocationAuthorizationLevel) -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError>
}

extension LocationService {
    public static func authorized<T>(_ signal: SignalProducer<T, LocationError>, desiredLevel: LocationAuthorizationLevel = .whenInUse) -> SignalProducer<T, LocationError> {
        return self.requestAuthorization(desired: desiredLevel)
            .take(last: 1)
            .flatMapError { error in
                return SignalProducer(error: LocationError.authorization(error))
            }
            .flatMap(.latest) { level -> SignalProducer<T, LocationError> in
                //TODO: if level is lower than desired, signal an error
                return signal
            }
    }
}

extension CLLocationManager: LocationService {
    public static var singleCoordinate: SignalProducer<Coordinate, LocationError> {
        return self.singleLocation.map { location in
            (location.coordinate.latitude, location.coordinate.longitude)
        }
    }

    public static var singleLocation: SignalProducer<CLLocation, LocationError> {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers //TODO: add accuracy param

        let delegate = ReactiveLocationDelegate()
        manager.delegate = delegate

        let errorSignal = SignalProducer(delegate.didFail)
            .map { $0 as NSError }
            .flatMap(.latest) { error -> SignalProducer<CLLocation, LocationError> in
                let clerror = CLError(_nsError: error)
                let locationError = LocationError(clerror: clerror)
                return SignalProducer<CLLocation, LocationError>(error: locationError)
            }

        let locationSignal = SignalProducer(delegate.didUpdateLocations)
            .promoteErrors(LocationError.self)
            .map { $0.last! }

        return merge([errorSignal, locationSignal])
            .take(first: 1)
            .on(starting: {
                    manager.requestLocation()
                },
                terminated: {
                    //Capture strong reference to avoid deallocation
                    _ = manager
                    _ = delegate
                })
    }

    public static func requestAuthorization(desired: LocationAuthorizationLevel = .whenInUse) -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError> {
        let manager = CLLocationManager()
        let delegate = ReactiveLocationDelegate()

        manager.delegate = delegate

        let authorizationChanges = SignalProducer(delegate.didChangeAuthorizationStatus)
            .on(started: {
                    switch desired {
                    case .always: manager.requestAlwaysAuthorization()
                    case .whenInUse: manager.requestWhenInUseAuthorization()
                    }
                },
                terminated: {
                    //Capture strong reference to avoid deallocation
                    _ = manager
                    _ = delegate
                })
            .filter { $0 != .notDetermined }
            .promoteErrors(LocationAuthorizationError.self)
            .take(first: 1)
            .flatMap(.latest, transform: self.authorizationLevel)

        return SignalProducer<CLAuthorizationStatus, LocationAuthorizationError> { observer, disposable in
                observer.send(value: CLLocationManager.authorizationStatus())
                observer.sendCompleted()
            }
            .flatMap(.latest) { status -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError> in
                if case .notDetermined = status {
                    return authorizationChanges
                } else {
                    return self.authorizationLevel(from: status)
                }
            }
    }

    internal static func authorizationLevel(from status: CLAuthorizationStatus) -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError> {
        switch status {
        case .authorizedAlways:
            return SignalProducer(value: .always)
        case .authorizedWhenInUse:
            return SignalProducer(value: .whenInUse)
        case .denied:
            return SignalProducer(error: .denied)
        case .restricted:
            return SignalProducer(error: .restricted)
        case .notDetermined:
            assertionFailure("Should be determined by now")
            return SignalProducer(error: .restricted)
        }
    }
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
