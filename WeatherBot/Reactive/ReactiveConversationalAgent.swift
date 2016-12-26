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
