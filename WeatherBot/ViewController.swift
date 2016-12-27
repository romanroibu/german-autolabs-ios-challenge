//
//  ViewController.swift
//  WeatherBot
//
//  Created by Roman Roibu on 24/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

