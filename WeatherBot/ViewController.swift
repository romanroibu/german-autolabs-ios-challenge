//
//  ViewController.swift
//  WeatherBot
//
//  Created by Roman Roibu on 24/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import UIKit
import CoreLocation
import ReactiveSwift
import Result

protocol Cell {
    static var identifier: String { get }
}

extension Cell where Self: UITableViewCell {
    static var identifier: String {
        return String(describing: self)
    }
}

class QuestionCell: UITableViewCell, Cell {
    @IBOutlet weak var questionLabel: UILabel!
}

class AnswerCell: UITableViewCell, Cell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
}

class ViewController: UITableViewController {
    let viewModel = ViewModel(
        agent: ReactiveConversationalAgent(
            language: .english,
            audioService: ReactiveInputAudioCaptureSession.self,
            locationService: CLLocationManager.self,
            networkService: ReactiveURLSession(session: .shared),
            recognizerService: ReactiveSpeechRecognizer.self,
            synthesizerService: ReactiveSpeechSynthesizer.self,
            weatherService: DarkSky(secretKey: "3d48fdfd9e159eac616fddb1ac870983"),
            domainUnits: [
                WeatherUnderstandingUnit(),
            ]
        )
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

