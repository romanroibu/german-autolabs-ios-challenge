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

