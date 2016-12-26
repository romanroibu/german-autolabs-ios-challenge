//
//  Extensions.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

extension String {
    public func validate(allowedCharacters set: CharacterSet) -> Bool {
        return self.validate(disallowedCharacters: set.inverted)
    }

    public func validate(disallowedCharacters set: CharacterSet) -> Bool {
        guard !self.isEmpty else { return true }
        return self.rangeOfCharacter(from: set) == nil
    }
}

extension Measurement {
    public func rounded(_ rule: FloatingPointRoundingRule) -> Measurement<UnitType> {
        return Measurement<UnitType>(value: self.value.rounded(rule), unit: self.unit)
    }

    public func rounded() -> Measurement<UnitType> {
        return Measurement<UnitType>(value: self.value.rounded(), unit: self.unit)
    }
}

extension UnitSpeed {
    public static var inchesPerHour: UnitSpeed {
        let converter = UnitConverterLinear(coefficient: 141732.28337529)
        return UnitSpeed(symbol: "in/h", converter: converter)
    }

    public static var millimetersPerHour: UnitSpeed {
        let converter = UnitConverterLinear(coefficient: 1000)
        return UnitSpeed(symbol: "mm/h", converter: converter)
    }
}
