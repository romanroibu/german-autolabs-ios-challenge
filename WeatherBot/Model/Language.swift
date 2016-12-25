//
//  Language.swift
//  WeatherBot
//
//  Created by Roman Roibu on 25/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

public enum Language {
    case english
}

extension Language {
    internal var locale: Locale {
        switch self {
        case .english:  return Locale(identifier: "en")
        }
    }

    internal var bcp47LanguageTag: String {
        switch self {
        case .english:  return "en-US"
        }
    }
}
