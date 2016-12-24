//
//  ReactiveAudio.swift
//  WeatherBot
//
//  Created by Roman Roibu on 24/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import AVFoundation
import ReactiveSwift
import Result

public enum InputAudioAuthorizationLevel {
    case authorized
}

public enum InputAudioAuthorizationError: Error {
    case denied
    case restricted
}

public enum InputAudioError: Error {
    case noAudioDevice //very unlikely :)
    case audioInputFailure(Error)
    case authorization(InputAudioAuthorizationError)
}

public protocol ReactiveInputAudioService {
    static var inputAudioSampleBuffer: SignalProducer<CMSampleBuffer, InputAudioError> { get }
    static var requestAuthorization: SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> { get }
}

public final class ReactiveInputAudioCaptureSession: ReactiveInputAudioService {
    private static let mediaType = AVMediaTypeAudio

    public static var requestAuthorization: SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> {
        let authorizationChanges = SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> { observer, disposable in
            AVCaptureDevice.requestAccess(forMediaType: self.mediaType) { granted in
                if granted {
                    observer.send(value: .authorized)
                } else {
                    observer.send(error: .denied)
                }
                observer.sendCompleted()
            }
        }

        return SignalProducer<AVAuthorizationStatus, InputAudioAuthorizationError> { observer, disposable in
                observer.send(value: AVCaptureDevice.authorizationStatus(forMediaType: self.mediaType))
                observer.sendCompleted()
            }
            .flatMap(.latest) { status -> SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> in
                if case .notDetermined = status {
                    return authorizationChanges
                } else {
                    return self.authorizationLevel(from: status)
                }
        }
    }

    internal static func authorizationLevel(from status: AVAuthorizationStatus) -> SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> {
        switch status {
        case .authorized:
            return SignalProducer(value: .authorized)
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
}
