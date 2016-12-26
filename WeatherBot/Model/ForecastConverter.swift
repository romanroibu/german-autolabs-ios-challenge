//
//  ForecastConverter.swift
//  WeatherBot
//
//  Created by Roman Roibu on 26/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation

public struct ForecastConverter {
    public typealias Convert<T: Dimension> = (T) -> T

    public let temperature:                 Convert<Temperature>
    public let pressure:                    Convert<Pressure>
    public let visibility:                  Convert<Distance>
    public let windSpeed:                   Convert<Speed>
    public let windDirection:               Convert<Direction>
    public let precipitationIntensity:      Convert<Precipitation.Intensity>
    public let precipitationAccumulation:   Convert<Precipitation.Accumulation>

    public init(
        temperature: Temperature.Unit? = nil,
        pressure: Pressure.Unit? = nil,
        visibility: Distance.Unit? = nil,
        windSpeed: Speed.Unit? = nil,
        windDirection: Direction.Unit? = nil,
        precipitationIntensity: Precipitation.Intensity.Unit? = nil,
        precipitationAccumulation: Precipitation.Accumulation.Unit? = nil
    ) {
        self.temperature =                  { temperature.flatMap($0.converted) ?? $0 }
        self.pressure =                     { pressure.flatMap($0.converted) ?? $0 }
        self.visibility =                   { visibility.flatMap($0.converted) ?? $0 }
        self.windSpeed =                    { windSpeed.flatMap($0.converted) ?? $0 }
        self.windDirection =                { windDirection.flatMap($0.converted) ?? $0 }
        self.precipitationIntensity =       { precipitationIntensity.flatMap($0.converted) ?? $0 }
        self.precipitationAccumulation =    { precipitationAccumulation.flatMap($0.converted) ?? $0 }
    }

    public func precipitation(_ precipitation: Precipitation) -> Precipitation {
        return Precipitation(
            kind: precipitation.kind,
            intensity: self.precipitationIntensity(precipitation.intensity),
            accumulation: self.precipitationAccumulation(precipitation.accumulation),
            probability: precipitation.probability
        )
    }

    public func wind(_ wind: Wind) -> Wind {
        return (self.windSpeed(wind.speed), self.windDirection(wind.direction))
    }

    public func dayTemperature(_ dayTemperature: DayTemperature) -> DayTemperature {
        return (self.temperature(dayTemperature.low), self.temperature(dayTemperature.high))
    }

    public func forecast(_ forecast: Forecast) -> Forecast {
        return Forecast(
            id:                 forecast.id,
            summary:            forecast.summary,
            wind:               forecast.wind.flatMap(self.wind),
            pressure:           forecast.pressure.flatMap(self.pressure),
            visibility:         forecast.visibility.flatMap(self.visibility),
            feelsLike:          forecast.feelsLike.flatMap(self.temperature),
            temperature:        forecast.temperature.flatMap(self.temperature),
            precipitation:      forecast.precipitation.flatMap(self.precipitation),
            maxPrecipitation:   forecast.maxPrecipitation.flatMap(self.precipitation),
            dayTemperature:     forecast.dayTemperature.flatMap(self.dayTemperature)
        )
    }
}
