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
    case authorized
}

public enum InputAudioAuthorizationError: Error {
    case denied
    case restricted
}

public enum InputAudioError: Error {
    case noAudioDevice //very unlikely :)
    case audioInputFailure(Error)
    case authorization(InputAudioAuthorizationError)
}

public protocol ReactiveInputAudioService {
    static var inputAudioSampleBuffer: SignalProducer<CMSampleBuffer, InputAudioError> { get }
    static var requestAuthorization: SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> { get }
}

public final class ReactiveInputAudioCaptureSession: ReactiveInputAudioService {
    private static let mediaType = AVMediaTypeAudio

    public static var inputAudioSampleBuffer: SignalProducer<CMSampleBuffer, InputAudioError> {
        let captureSession = AVCaptureSession()
        let delegate = ReactiveCaptureAudioDataOutputDelegate()

        do { //Setup audio input
            guard let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: self.mediaType) else {
                return SignalProducer<CMSampleBuffer, InputAudioError>(error: .noAudioDevice)
            }
            let audioInput  = try AVCaptureDeviceInput(device: audioDevice)
            captureSession.addInput(audioInput)
        } catch {
            return SignalProducer<CMSampleBuffer, InputAudioError>(error: .audioInputFailure(error))
        }

        do { //Setup audio output
            let audioOutput = AVCaptureAudioDataOutput()
            let queue = DispatchQueue(label: "\(audioOutput)")
            audioOutput.setSampleBufferDelegate(delegate, queue: queue)
            captureSession.addOutput(audioOutput)
        }

        return SignalProducer<CMSampleBuffer, InputAudioError>(delegate.didOutputSampleBuffer.promoteErrors(InputAudioError.self))
            .on(started: {
                    captureSession.startRunning()
                },
                terminated: {
                    //Capture strong reference to avoid deallocation
                    _ = delegate
                    captureSession.stopRunning()
                })
    }

    public static var requestAuthorization: SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> {
        let authorizationChanges = SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> { observer, disposable in
            AVCaptureDevice.requestAccess(forMediaType: self.mediaType) { granted in
                if granted {
                    observer.send(value: .authorized)
                } else {
                    observer.send(error: .denied)
                }
                observer.sendCompleted()
            }
        }

        return SignalProducer<AVAuthorizationStatus, InputAudioAuthorizationError> { observer, disposable in
                observer.send(value: AVCaptureDevice.authorizationStatus(forMediaType: self.mediaType))
                observer.sendCompleted()
            }
            .flatMap(.latest) { status -> SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> in
                if case .notDetermined = status {
                    return authorizationChanges
                } else {
                    return self.authorizationLevel(from: status)
                }
        }
    }

    internal static func authorizationLevel(from status: AVAuthorizationStatus) -> SignalProducer<InputAudioAuthorizationLevel, InputAudioAuthorizationError> {
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

internal final class ReactiveCaptureAudioDataOutputDelegate: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {

    private let sampleBufferPipe = Signal<CMSampleBuffer, NoError>.pipe()

    var didOutputSampleBuffer: Signal<CMSampleBuffer, NoError> {
        return self.sampleBufferPipe.output
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let sample = sampleBuffer else { return }
        self.sampleBufferPipe.input.send(value: sample)
    }
}
