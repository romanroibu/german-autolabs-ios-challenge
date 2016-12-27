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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Q & A
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case self.questionIndexPath.section:
            return self.viewModel.question != nil ? 1 : 0
        case self.answerIndexPath.section:
            return self.viewModel.spokenAnswer != nil ? 1 : 0
        default:
            return 0
        }
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

extension ViewController {
    fileprivate var questionIndexPath:  IndexPath { return IndexPath(row: 0, section: 0) }

    fileprivate var answerIndexPath:    IndexPath { return IndexPath(row: 0, section: 1) }

    fileprivate func dialogUpdate(event: Event<[DialogUpdate], NoError>) {
        switch event {
        case .value(let batch):
            guard !batch.isEmpty else { return }
            self.tableView.beginUpdates()
            for update in batch {
                let indexPath = self.indexPath(update: update)
                let animation = self.animation(update: update)
                switch update.action {
                case .insert:
                    self.tableView.insertRows(at: [indexPath], with: animation)
                case .update:
                    self.tableView.reloadRows(at: [indexPath], with: animation)
                    break
                case .delete:
                    self.tableView.deleteRows(at: [indexPath], with: animation)
                }
            }
            self.tableView.endUpdates()
        case .failed(_):
            if self.listenButton.isSelected {
                self.listenAction(self)
            }
        case .interrupted:
            if self.listenButton.isSelected {
                self.listenAction(self)
            }
        case .completed:
            if self.listenButton.isSelected {
                self.listenAction(self)
            }
        }
    }

    private func indexPath(update: DialogUpdate) -> IndexPath {
        switch update.part {
        case .question:
            return self.questionIndexPath
        case .answer:
            return self.answerIndexPath
        }
    }

    private func animation(update: DialogUpdate) -> UITableViewRowAnimation {
        switch (update.action, update.part) {
        case (.insert, .question):
            return .right
        case (.insert, .answer):
            return .left
        case (.update, .question):
            return .none
        case (.update, .answer):
            return .none
        case (.delete, .question):
            return .left
        case (.delete, .answer):
            return .right
        }
    }
}

extension ViewController {
    fileprivate func failure(event: Event<Error, NoError>) {
        switch event {
        case .value(let error):
            if self.listenButton.isSelected {
                self.listenAction(self)
            }
            guard self.presentedViewController == nil else { return }
            let alert = self.alert(error: error)
            self.present(alert, animated: true) {}
        case .failed(_):
            break
        case .interrupted:
            break
        case .completed:
            break
        }
    }

    private func alert(error: Error) -> UIAlertController {
        //TODO: Localize alert title and OK button
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        return alert
    }
}

extension ViewController {
    fileprivate func agentActivity(event: Event<Bool, NoError>) {
        switch event {
        case .value(let isActive):
            UIApplication.shared.isNetworkActivityIndicatorVisible = isActive
        case .failed(_):
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        case .interrupted:
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        case .completed:
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
