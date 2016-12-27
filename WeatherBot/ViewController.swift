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

    @IBAction func listenAction(_ sender: Any) {
        //Toggle button selection
        self.listenButton.isSelected = !self.listenButton.isSelected

        if self.listenButton.isSelected {
            self.viewModel.startListening()
        } else {
            self.viewModel.stopListening()
        }
    }

    lazy var listenButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        button.setImage(UIImage(named: "listen-start"), for: .normal)
        button.setImage(UIImage(named: "listen-stop"), for: .selected)
        button.addTarget(self, action: #selector(self.listenAction(_:)), for: .touchUpInside)
        return button
    }()

    lazy var tableFooter: UIView = {
        let footer = UIView(frame: self.listenButton.bounds)
        self.listenButton.translatesAutoresizingMaskIntoConstraints = false

        footer.addSubview(self.listenButton)

        let constraints: [NSLayoutConstraint] = [
            NSLayoutConstraint(
                item: self.listenButton,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: footer,
                attribute: .centerX,
                multiplier: 1,
                constant: 0
            ),
            NSLayoutConstraint(
                item: self.listenButton,
                attribute: .height,
                relatedBy: .equal,
                toItem: self.listenButton,
                attribute: .width,
                multiplier: 1,
                constant: 0
            ),
        ] + NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[button]|",
            options: [],
            metrics: nil,
            views: ["button": self.listenButton]
        )

        NSLayoutConstraint.activate(constraints)

        return footer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        //Set up table view footer with record button
        self.tableView.tableFooterView = self.tableFooter

        //Set up table view to use self-sizing cells
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case questionIndexPath:
            let cell: QuestionCell = self.dequeueCell(from: tableView, for: indexPath)
            let question = self.viewModel.question!
            cell.questionLabel.text = question
            return cell
        case answerIndexPath:
            let cell: AnswerCell = self.dequeueCell(from: tableView, for: indexPath)
            let answer = self.viewModel.spokenAnswer!.answer
            let defaultImage = UIImage(named: "cloudy")!
            cell.iconImageView.image = answer.icon.flatMap { UIImage(named: $0) } ?? defaultImage
            cell.titleLabel.text = answer.summary.title
            cell.messageLabel.text = answer.summary.message
            return cell
        default:
            fatalError("Can only deal with one question and one answer max, for now")
        }
    }

    private func dequeueCell<C: Cell>(from tableView: UITableView, for indexPath: IndexPath) -> C where C: UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: C.identifier, for: indexPath) as! C
    }
}

