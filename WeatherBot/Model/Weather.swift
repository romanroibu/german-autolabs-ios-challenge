//
//  Weather.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

public protocol WeatherService {
    func current(coordinate: Coordinate, language: WeatherBot.Language?) -> Request<Forecast>
}
