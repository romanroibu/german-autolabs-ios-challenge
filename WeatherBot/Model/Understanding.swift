//
//  Understanding.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

public protocol DomainUnderstandingUnit {
    typealias Language = NaturalLanguageUnderstandingUnit.Language
    typealias Speech = NaturalLanguageUnderstandingUnit.ParsedSpeech
    typealias IntentGuess = (intent: NaturalLanguageUnderstandingUnit.Intent, probability: NaturalLanguageUnderstandingUnit.Probability)

    func identifyIntent(in speech: Speech, using language: Language) -> IntentGuess?
}

public struct NaturalLanguageUnderstandingUnit {
    public typealias Language = WeatherBot.Language
    public typealias Probability = Double
    public typealias InputSpeech = String
    //TODO: For now, parsing does nothing, so the output of parsing is the input string
    public typealias ParsedSpeech = InputSpeech

    public enum Intent {
        case unknown
        case currentForecast
    }

    public let language: Language
    public let domainUnits: [DomainUnderstandingUnit]

    public func identifyIntent(in speech: InputSpeech) -> Intent {
        let parsedSpeech = self.parse(speech: speech)

        let bestGuess = self.domainUnits
            .lazy
            .flatMap { unit in
                unit.identifyIntent(in: parsedSpeech, using: self.language)
            }
            .sorted { x, y in
                //Sort highest probability first
                x.probability > y.probability
            }
            .first

        return bestGuess?.intent ?? .unknown
    }

    internal func parse(speech: InputSpeech) -> ParsedSpeech {
        //TODO: For now, parsing does nothing, so the output of parsing is the input string
        return speech
    }
}
