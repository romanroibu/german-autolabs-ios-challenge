//
//  ReactiveSpeechRecognizer.swift
//  WeatherBot
//
//  Created by Roman Roibu on 25/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Speech
import ReactiveSwift
import Result

public enum SpeechRecognizerError<SpeechError: Error>: Error {
    case localeNotSupported
    case recognizerNotAvailable
    case speech(SpeechError)
    case authorization(SpeechRecognizerAuthorizationError)
}

public enum SpeechRecognizerAuthorizationLevel {
    case authorized
}

public enum SpeechRecognizerAuthorizationError: Error {
    case denied
    case restricted
}

public protocol SpeechRecognizerService {
    static func recognize<E: Error>(speech: Signal<CMSampleBuffer, E>, locale: Locale) -> SignalProducer<String, SpeechRecognizerError<E>>
    static var requestAuthorization: SignalProducer<SpeechRecognizerAuthorizationLevel, SpeechRecognizerAuthorizationError> { get }
}

public final class ReactiveSpeechRecognizer: SpeechRecognizerService {
    public static var requestAuthorization: SignalProducer<SpeechRecognizerAuthorizationLevel, SpeechRecognizerAuthorizationError> {
        let authorizationChanges = SignalProducer<SFSpeechRecognizerAuthorizationStatus, NoError> { observer, disposable in
                SFSpeechRecognizer.requestAuthorization { status in
                    observer.send(value: status)
                }
            }
            .promoteErrors(SpeechRecognizerAuthorizationError.self)
            .flatMap(.latest) { status -> SignalProducer<SpeechRecognizerAuthorizationLevel, SpeechRecognizerAuthorizationError> in
                return self.authorizationLevel(from: status)
            }

        return SignalProducer<SFSpeechRecognizerAuthorizationStatus, SpeechRecognizerAuthorizationError> { observer, disposable in
                observer.send(value: SFSpeechRecognizer.authorizationStatus())
                observer.sendCompleted()
            }
            .flatMap(.latest) { status -> SignalProducer<SpeechRecognizerAuthorizationLevel, SpeechRecognizerAuthorizationError> in
                if case .notDetermined = status {
                    return authorizationChanges
                } else {
                    return self.authorizationLevel(from: status)
                }
            }
    }

    internal static func authorizationLevel(from status: SFSpeechRecognizerAuthorizationStatus) -> SignalProducer<SpeechRecognizerAuthorizationLevel, SpeechRecognizerAuthorizationError> {
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
