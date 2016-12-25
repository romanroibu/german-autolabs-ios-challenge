//
//  ReactiveSpeechSynthesizer.swift
//  WeatherBot
//
//  Created by Roman Roibu on 25/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import AVFoundation
import ReactiveSwift
import Result


public protocol SpeechSynthesizerService {
    static func speak(text: String, language: Language) -> SignalProducer<NSRange, NoError>
}

internal final class ReactiveSpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {

    private let willSpeakRangeOfSpeechPipe = Signal<NSRange, NoError>.pipe()

    var willSpeakRangeOfSpeech: Signal<NSRange, NoError> {
        return self.willSpeakRangeOfSpeechPipe.output
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        self.willSpeakRangeOfSpeechPipe.input.sendInterrupted()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.willSpeakRangeOfSpeechPipe.input.sendCompleted()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        self.willSpeakRangeOfSpeechPipe.input.send(value: characterRange)
    }
}
