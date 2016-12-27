//
//  ErrorDescription.swift
//  WeatherBot
//
//  Created by Roman Roibu on 27/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation
import Result

extension AnyError: LocalizedError {
    public var errorDescription: String? {
        if let localizedError = self.error as? LocalizedError {
            return localizedError.errorDescription
        } else {
            return self.description
        }
    }
}

extension InputAudioError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .noAudioDevice:
            //TODO: provide localized error description
            return String(describing: self)
        case .audioInputFailure(let error):
            return error.localizedDescription
        case .authorization(let error):
            return error.localizedDescription
        }
    }
}

extension InputAudioAuthorizationError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .denied:
            //TODO: provide localized error description
            return String(describing: self)
        case .restricted:
            //TODO: provide localized error description
            return String(describing: self)
        }
    }
}

extension LocationError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .unknown:
            //TODO: provide localized error description
            return String(describing: self)
        case .network:
            //TODO: provide localized error description
            return String(describing: self)
        case .locationUnknown:
            //TODO: provide localized error description
            return String(describing: self)
        case .denied:
            //TODO: provide localized error description
            return String(describing: self)
        case .deferredFailed:
            //TODO: provide localized error description
            return String(describing: self)
        case .deferredCanceled:
            //TODO: provide localized error description
            return String(describing: self)
        case .deferredAccuracyTooLow:
            //TODO: provide localized error description
            return String(describing: self)
        case .authorization(let error):
            return error.localizedDescription
        }
    }
}

extension LocationAuthorizationError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .denied:
            //TODO: provide localized error description
            return String(describing: self)
        case .restricted:
            //TODO: provide localized error description
            return String(describing: self)
        }
    }
}

extension SpeechRecognizerError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .localeNotSupported:
            //TODO: provide localized error description
            return String(describing: self)
        case .recognizerNotAvailable:
            //TODO: provide localized error description
            return String(describing: self)
        case .speech(let error):
            return error.localizedDescription
        case .authorization(let error):
            return error.localizedDescription
        }
    }
}

extension SpeechRecognizerAuthorizationError: LocalizedError {
    public var errorDescription: String {
        switch self {
        case .denied:
            //TODO: provide localized error description
            return String(describing: self)
        case .restricted:
            //TODO: provide localized error description
            return String(describing: self)
        }
    }
}
