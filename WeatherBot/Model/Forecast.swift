//
//  Forecast.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

public typealias Temperature = Measurement<UnitTemperature>
public typealias Direction   = Measurement<UnitAngle>
public typealias Distance    = Measurement<UnitLength>
public typealias Speed       = Measurement<UnitSpeed>
public typealias Pressure    = Measurement<UnitPressure>

public typealias Wind = (speed: Speed, direction: Direction)
public typealias DayTemperature = (low: Temperature, high: Temperature)

public struct Precipitation {
    public typealias Probability  = Double
    public typealias Intensity    = Measurement<UnitSpeed>
    public typealias Accumulation = Measurement<UnitLength>

    public enum Kind: String {
        case rain, snow, sleet
    }

    let kind: Kind
    let intensity: Intensity
    let accumulation: Accumulation
    let probability: Probability
}

public struct Forecast {
    public let id: String
    public let summary: String

    public let wind: Wind?
    public let pressure: Pressure?
    public let visibility: Distance?
    public let feelsLike: Temperature?
    public let temperature: Temperature?
    public let precipitation: Precipitation?
    public let maxPrecipitation: Precipitation?
    public let dayTemperature: DayTemperature?
}

