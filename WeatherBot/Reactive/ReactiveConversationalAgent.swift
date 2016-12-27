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

public protocol ConversationalAgentService {
    typealias QuestionListeningError = SpeechRecognizerError<InputAudioError>
    typealias QuestionSignal = Signal<String, QuestionListeningError>
    typealias QuestionSignalProducer = SignalProducer<String, QuestionListeningError>

    typealias AnswerValue = (icon: String?, summary: Summarizer.Summary)
    typealias AnswerError = AnyError //FIXME: Use more specific error enum
    typealias AnswerSignalProducer = SignalProducer<AnswerValue, AnswerError>

    typealias SpokenAnswerValue = (answer: AnswerValue, spokenRange: NSRange)
    typealias SpokenAnswerSignal = Signal<SpokenAnswerValue, AnswerError>
    typealias SpokenAnswerSignalProducer = SignalProducer<SpokenAnswerValue, AnswerError>

    func question<T, E: Error>(listenUntil driver: Signal<T, E>) -> QuestionSignalProducer
    func answer(from question: QuestionSignal) -> AnswerSignalProducer
    func answer(from question: QuestionSignalProducer) -> AnswerSignalProducer
    func spokenAnswer(from question: QuestionSignal) -> SpokenAnswerSignalProducer
    func spokenAnswer(from question: QuestionSignalProducer) -> SpokenAnswerSignalProducer
}

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
    public typealias QuestionListeningError = ConversationalAgentService.QuestionListeningError
    public typealias QuestionSignal         = ConversationalAgentService.QuestionSignal
    public typealias QuestionSignalProducer = ConversationalAgentService.QuestionSignalProducer

    public typealias AnswerValue          = ConversationalAgentService.AnswerValue
    public typealias AnswerError          = ConversationalAgentService.AnswerError
    public typealias AnswerSignalProducer = ConversationalAgentService.AnswerSignalProducer

    public typealias SpokenAnswerValue          = ConversationalAgentService.SpokenAnswerValue
    public typealias SpokenAnswerSignal         = ConversationalAgentService.SpokenAnswerSignal
    public typealias SpokenAnswerSignalProducer = ConversationalAgentService.SpokenAnswerSignalProducer

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

    public func answer(from question: QuestionSignalProducer) -> AnswerSignalProducer {
        return question
            .take(last: 1)
            .map(self.nlu.identifyIntent)
            .flatMapError { questionError in
                return SignalProducer(error: AnswerError(questionError))
            }
            .flatMap(.latest, transform: self.answer)
    }

    public func spokenAnswer(from question: QuestionSignalProducer) -> SpokenAnswerSignalProducer {
        return self.answer(from: question)
            .flatMap(.latest) { answer -> SpokenAnswerSignalProducer in
                let answerSignal = AnswerSignalProducer(value: answer)

                let speechSignal = self.synthesizerService.speak(text: answer.summary.spokenText, language: self.language)
                    .promoteErrors(AnswerError.self)

                return answerSignal.combineLatest(with: speechSignal)
                    .map { $0 as SpokenAnswerValue }
            }
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
