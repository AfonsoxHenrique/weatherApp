//
//  ForecastModel.swift
//  weatherApp
//
//  Created by Afonso Henrique Freitas de Paula on 6/3/2026.
//

import Foundation

struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt_txt: String
    let main: Main
    let weather: [Weather]
}
