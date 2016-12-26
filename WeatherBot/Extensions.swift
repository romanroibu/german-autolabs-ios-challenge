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
