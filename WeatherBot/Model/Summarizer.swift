//
//  Summarizer.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

public struct Summarizer {
    public struct Summary {
        public let title: String
        public let message: String

        public var spokenText: String {
            return [
                self.title,
                self.message,
            ].joined(separator: Summary.sentenceSeparator)
        }

        fileprivate static let sentenceSeparator = ".\n"
    }

    public let language: Language

    //TODO: Return localized summary, based on self.language
    public var unknown: Summary {
        return Summary(title: "Sorry, I don't know what you mean", message: "")
    }

    //TODO: Return localized summary, based on self.language
    public func forecast(_ forecast: Forecast) -> Summary {
        let title = forecast.summary
        var message: [String] = []

        let formatter = MeasurementFormatter()

        if let temp = forecast.temperature {
            message.append("The temperature is \(formatter.string(from: temp.rounded()))")
        }
        if let temp = forecast.feelsLike {
            message.append("It feels like \(formatter.string(from: temp.rounded()))")
        }
        if let precip = forecast.precipitation, precip.probability > 0.3 {
            let percent = (Int(precip.probability * 100) / 5) * 5
            message.append("There's a \(percent)% chance of \(precip.kind.rawValue) right now")
        }
        if let pressure = forecast.pressure {
            message.append("The pressure is \(formatter.string(from: pressure))")
        }

        return Summary(title: title, message: message.joined(separator: Summary.sentenceSeparator))
    }
}
