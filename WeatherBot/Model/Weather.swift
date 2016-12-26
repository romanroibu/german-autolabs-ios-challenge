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

public struct DarkSky: WeatherService {
    public enum Units: String {
        case auto, ca, uk2, us, si
    }

    public enum Language: String {
        case ar, az, be, bs, ca, cs, de, el
        case en, es, et, fr, hr, hu, id, it
        case `is`, kw, nb, nl, pl, pt, ru, sk
        case sl, sr, sv, tet, tr, uk, zh, zh_tw
    }

    public struct Context {
        public let coordinate: Coordinate
        public let language: Language?
        public let units: Units?
    }

    fileprivate let base: URL

    public init(secretKey: String, language: WeatherBot.Language) {
        precondition(secretKey.validate(allowedCharacters: .alphanumerics), "Secret key contains invalid characters")
        self.base = URL(string: "https://api.darksky.net/forecast/\(secretKey)/")!
    }

    public func current(coordinate: Coordinate, language: WeatherBot.Language? = nil) -> Request<Forecast> {
        let context = DarkSky.Context(
            coordinate: coordinate,
            language: language.flatMap(self.language),
            units: language.flatMap(self.units)
        )

        return self.current(context)
    }

    private func language(from language: WeatherBot.Language) -> DarkSky.Language {
        switch language {
        case .english: return .en
        }
    }

    private func units(from language: WeatherBot.Language) -> DarkSky.Units {
        switch language {
        //TODO: Need better conversion logic
        case .english: return .si
        }
    }
}

extension DarkSky {
    /// Keys of the response JSON objects
    /// See: https://darksky.net/dev/docs/response
    private enum ResponseKey: String {
        case currently
        case daily
    }

    /// Keys of the data point JSON objects
    /// See: https://darksky.net/dev/docs/response#DataPointObject
    private enum DataPointKey: String {
        case icon
        case summary
        case pressure
        case visibility
        case temperature
        case temperatureMin
        case temperatureMax
        case apparentTemperature
        case precipType
        case precipIntensity
        case precipProbability
        case precipAccumulation
        case precipIntensityMax
        case windSpeed
        case windBearing
    }

    public func current(_ context: Context) -> Request<Forecast> {
        let exclude = ["minutely", "hourly", "alerts", "flags"]
        let latitude  = context.coordinate.latitude
        let longitude = context.coordinate.longitude

        var components = URLComponents(
            url: self.base.appendingPathComponent("\(latitude),\(longitude)"),
            resolvingAgainstBaseURL: false
        )!

        var queryItems: [URLQueryItem] = exclude.map {
            URLQueryItem(name: "exclude", value: $0)
        }

        if let units = context.units {
            queryItems.append(URLQueryItem(name: "units", value: units.rawValue))
        }

        if let language = context.language {
            queryItems.append(URLQueryItem(name: "lang", value: language.rawValue))
        }

        components.queryItems = queryItems

        return Request(
            components.url!,
            parseJSON: { json in
                let currently   = JSON<DataPointKey>(try JSON<ResponseKey>(json).value(forKey: .currently) as [String: Any])
                let daily       = JSON<DataPointKey>(try JSON<ResponseKey>(json).value(forKey: .daily)     as [String: Any])

                var pressure: Pressure? = nil
                var visibility: Distance? = nil
                var feelsLike: Temperature? = nil
                var temperature: Temperature? = nil
                var wind: (Speed, Direction)? = nil
                var precipitation: Precipitation? = nil
                var maxPrecipitation: Precipitation? = nil
                var dailyTemperature: (low: Temperature, high: Temperature)? = nil

                //Get pressure value
                if let value: Double = try currently.optional(forKey: .pressure) {
                    pressure = Pressure(value: value, unit: .millibars)
                }

                //Get visibility value
                if let value: Double = try currently.optional(forKey: .visibility) {
                    visibility = Distance(value: value, unit: .miles)
                }

                //Get temperature value
                if let value: Double = try currently.optional(forKey: .temperature) {
                    temperature = Temperature(value: value, unit: .fahrenheit)
                }

                //Get apparent (feels like) temperature value
                if let value: Double = try currently.optional(forKey: .apparentTemperature) {
                    feelsLike = Temperature(value: value, unit: .fahrenheit)
                }

                //Get precipitation value
                if  let precipType: String = try currently.optional(forKey: .precipType),
                    let precipKind = Precipitation.Kind(rawValue: precipType),
                    let precipIntensity: Double = try currently.optional(forKey: .precipIntensity) {
                    let precipProbability: Double = try currently.optional(forKey: .precipProbability) ?? 0
                    let precipAccumulation: Double = try daily.optional(forKey: .precipAccumulation) ?? 0
                    precipitation = Precipitation(
                        kind: precipKind,
                        intensity: Precipitation.Intensity(value: precipIntensity, unit: UnitSpeed.inchesPerHour),
                        accumulation: Precipitation.Accumulation(value: precipAccumulation, unit: .inches),
                        probability: precipProbability
                    )
                }

                //Get max (daily) precipitation value
                if  let precipType: String = try daily.optional(forKey: .precipType),
                    let precipKind = Precipitation.Kind(rawValue: precipType),
                    let precipIntensity: Double = try daily.optional(forKey: .precipIntensityMax) {
                    let precipProbability: Double = try daily.optional(forKey: .precipProbability) ?? 0
                    let precipAccumulation: Double = try daily.optional(forKey: .precipAccumulation) ?? 0
                    maxPrecipitation = Precipitation(
                        kind: precipKind,
                        intensity: Precipitation.Intensity(value: precipIntensity, unit: UnitSpeed.inchesPerHour),
                        accumulation: Precipitation.Accumulation(value: precipAccumulation, unit: .inches),
                        probability: precipProbability
                    )
                }

                //Get low/high (daily) temperature value
                if  let temperatureMin: Double = try daily.optional(forKey: .temperatureMin),
                    let temperatureMax: Double = try daily.optional(forKey: .temperatureMax) {
                    dailyTemperature = (
                        Temperature(value: temperatureMin, unit: .fahrenheit),
                        Temperature(value: temperatureMax, unit: .fahrenheit)
                    )
                }

                //Get wind speed/direction value
                if  let windSpeed: Double = try currently.optional(forKey: .windSpeed),
                    let windBearing: Double = try currently.optional(forKey: .windBearing) {
                    let speed = Speed(value: windSpeed, unit: .milesPerHour)
                    let direction = Direction(value: windBearing, unit: .degrees)
                    wind = (speed, direction)
                }

                let forecast = Forecast(
                    id: try currently.value(forKey: .icon),
                    summary: try currently.value(forKey: .summary),
                    wind: wind,
                    pressure: pressure,
                    visibility: visibility,
                    feelsLike: feelsLike,
                    temperature: temperature,
                    precipitation: precipitation,
                    maxPrecipitation: maxPrecipitation,
                    dayTemperature: dailyTemperature
                )

                //Convert forecast to the desired units
                //This ensures that the units in the summary match the rest of the forecast
                return context.units?.converter.forecast(forecast) ?? forecast
            }
        )
    }
}

extension DarkSky.Units {
    fileprivate var converter: ForecastConverter {
        switch self {
        case .auto:
            return ForecastConverter()
        case .ca:
            return ForecastConverter(
                temperature: .celsius,
                pressure: .hectopascals,
                visibility: .kilometers,
                windSpeed: .kilometersPerHour,
                precipitationIntensity: .millimetersPerHour,
                precipitationAccumulation: .centimeters
            )
        case .us:
            return ForecastConverter(
                temperature: .fahrenheit,
                pressure: .inchesOfMercury,
                visibility: .miles,
                windSpeed: .milesPerHour,
                precipitationIntensity: .inchesPerHour,
                precipitationAccumulation: .inches
            )
        case .uk2:
            return ForecastConverter(
                temperature: .celsius,
                pressure: .hectopascals,
                visibility: .miles,
                windSpeed: .milesPerHour,
                precipitationIntensity: .millimetersPerHour,
                precipitationAccumulation: .centimeters
            )
        case .si:
            return ForecastConverter(
                temperature: .celsius,
                pressure: .hectopascals,
                visibility: .kilometers,
                windSpeed: .metersPerSecond,
                precipitationIntensity: .millimetersPerHour,
                precipitationAccumulation: .centimeters
            )
        }
    }
}
