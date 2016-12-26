//
//  ReactiveConversationalAgent.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public protocol ConversationalAgentService {}

public final class ReactiveConversationalAgent<A, L, N, R, S, W>
    where
    A: InputAudioService,
    L: LocationService,
    N: NetworkService,
    R: SpeechRecognizerService,
    S: SpeechSynthesizerService,
    W: WeatherService
{
    //Typealiases to make type signatures uniform
    public typealias AudioService       = A.Type
    public typealias LocationService    = L.Type
    public typealias NetworkService     = N
    public typealias RecognizerService  = R.Type
    public typealias SynthesizerService = S.Type
    public typealias WeatherService     = W

    public let audioService: AudioService
    public let locationService: LocationService
    public let networkService:  NetworkService
    public let recognizerService: RecognizerService
    public let synthesizerService: SynthesizerService
    public let weatherService: WeatherService

    public let language: Language
    public let summarizer: Summarizer
    public let nlu: NaturalLanguageUnderstandingUnit

    public init(
        language: Language,
        audioService: AudioService,
        locationService: LocationService,
        networkService: NetworkService,
        recognizerService: RecognizerService,
        synthesizerService: SynthesizerService,
        weatherService: WeatherService,
        domainUnits: [DomainUnderstandingUnit]
    ) {
        self.audioService = audioService
        self.locationService = locationService
        self.networkService  = networkService
        self.recognizerService = recognizerService
        self.synthesizerService = synthesizerService
        self.weatherService = weatherService

        self.language = language
        self.summarizer = Summarizer(language: language)
        self.nlu = NaturalLanguageUnderstandingUnit(
            language: language,
            domainUnits: domainUnits
        )
    }
}

extension ReactiveConversationalAgent {
    public typealias QuestionListeningError = SpeechRecognizerError<InputAudioError>
    public typealias QuestionSignalProducer = SignalProducer<String, QuestionListeningError>

    public func question<T, E: Error>(listenUntil driver: Signal<T, E>) -> QuestionSignalProducer {
        return self.recognizerService.authorized(
            self.recognizerService.recognize(
                speech: self.audioService.authorized(
                    audioService.inputAudioSampleBuffer(drivenBy: driver)
                ),
                language: self.language
            )
        )
    }

    public typealias AnswerValue = (icon: String?, summary: Summarizer.Summary)
    public typealias AnswerError = AnyError //FIXME: Use more specific error enum
    public typealias AnswerSignalProducer = SignalProducer<AnswerValue, AnswerError>

    public func answer(from question: QuestionSignalProducer) -> AnswerSignalProducer {
        return question
            .take(last: 1)
            .map(self.nlu.identifyIntent)
            .flatMapError { questionError in
                return SignalProducer(error: AnswerError(questionError))
            }
            .flatMap(.latest, transform: self.answer)
    }

    internal func answer(from intent: NaturalLanguageUnderstandingUnit.Intent) -> AnswerSignalProducer {
        switch intent {
        case .currentForecast:
            return self.locationService.authorized(self.locationService.singleCoordinate)
                .flatMapError { error in
                    return SignalProducer(error: AnyError(error))
                }
                .map { coordinate in
                    self.weatherService.current(coordinate: coordinate, language: self.language)
                }
                .flatMap(.latest) { request -> SignalProducer<Forecast, AnyError> in
                    return self.networkService.load(request)
                }
                .map { forecast in
                    let icon = forecast.id
                    let summary = self.summarizer.forecast(forecast)
                    return AnswerValue(icon, summary)
                }
        case .unknown:
            return AnswerSignalProducer(value: AnswerValue(nil, self.summarizer.unknown))
        }
    }
}
