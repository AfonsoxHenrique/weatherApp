//
//  weatherModel.swift
//  weatherApp
//
//  Created by Afonso Henrique Freitas de Paula on 5/3/2026.
//

import Foundation

struct WeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let coord: Coord
}

struct Coord: Codable {
    let lon: Double
    let lat: Double
}

struct Main: Codable {
    let temp: Double
    let humidity: Int
}

struct Weather: Codable {
    let description: String
    let icon: String
}

struct City {
    
    var id: String
    var name: String
    var lat: Double
    var lon: Double
    
}
