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
