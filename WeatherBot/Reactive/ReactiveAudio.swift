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
    case granted
}

public enum InputAudioAuthorizationError: Error {
    case denied
}

public enum InputAudioError: Error {
}

public protocol ReactiveInputAudioService {
    static var inputAudioSampleBuffer: SignalProducer<CMSampleBuffer, InputAudioError> { get }
    static var requestAuthorization: SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> { get }
}
