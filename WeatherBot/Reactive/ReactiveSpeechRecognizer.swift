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
    static func recognize<E: Error>(speech: Signal<CMSampleBuffer, E>, language: Language) -> SignalProducer<String, SpeechRecognizerError<E>>
    static var requestAuthorization: SignalProducer<SpeechRecognizerAuthorizationLevel, SpeechRecognizerAuthorizationError> { get }
}

extension SpeechRecognizerService {
    public static func authorized<T, E>(_ signal: SignalProducer<T, SpeechRecognizerError<E>>) -> SignalProducer<T, SpeechRecognizerError<E>> {
        return self.requestAuthorization
            .take(last: 1)
            .flatMapError { error in
                return SignalProducer(error: SpeechRecognizerError<E>.authorization(error))
            }
            .flatMap(.latest) { value -> SignalProducer<T, SpeechRecognizerError<E>> in
                return signal
            }
    }
}

public final class ReactiveSpeechRecognizer: SpeechRecognizerService {
    public static func recognize<E: Error>(speech: Signal<CMSampleBuffer, E>, language: Language) -> SignalProducer<String, SpeechRecognizerError<E>>{
        return self.recognize(speech: speech, locale: language.locale)
    }

    public static func recognize<E : Error>(speech: Signal<CMSampleBuffer, E>, locale: Locale) -> SignalProducer<String, SpeechRecognizerError<E>> {
        //Construct recognizer if locale is supported
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            return SignalProducer(error: .localeNotSupported)
        }

        //Make sure the recognizer is available
        guard recognizer.isAvailable else {
            return SignalProducer(error: .recognizerNotAvailable)
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        let delegate = ReactiveSpeechRecognizerDelegate<E>()

        //Start a new recognition task
        recognizer.recognitionTask(with: request, delegate: delegate)

        let disposableSpeech = speech.observe { event in
            switch event {
            case .value(let sample):
                request.appendAudioSampleBuffer(sample)
            case .completed:
                request.endAudio()
            case .failed(let error):
                delegate.forward(error: error)
                request.endAudio()
            case .interrupted:
                request.endAudio()
            }
        }

        return SignalProducer<String, E>(delegate.didRecognize)
            .flatMapError { error -> SignalProducer<String, SpeechRecognizerError<E>> in
                return SignalProducer(error: .speech(error))
            }
            .on(terminated: {
                disposableSpeech?.dispose()
                //Capture strong reference to avoid deallocation
                _ = request
                _ = delegate
                _ = recognizer
            })
    }

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

internal final class ReactiveSpeechRecognizerDelegate<E: Error>: NSObject, SFSpeechRecognitionTaskDelegate {

    private let didRecognizePipe = Signal<String, E>.pipe()

    var didRecognize: Signal<String, E> {
        return self.didRecognizePipe.output
    }

    func forward(error: E) {
        self.didRecognizePipe.input.send(error: error)
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        self.didRecognizePipe.input.sendCompleted()
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        self.didRecognizePipe.input.send(value: transcription.formattedString)
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        self.didRecognizePipe.input.send(value: recognitionResult.bestTranscription.formattedString)
    }
}
