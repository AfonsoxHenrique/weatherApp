
import Foundation

import UIKit

class SettingsManager {
    
    private static let tempUnitKey = "tempUnit"
    private static let appearanceKey = "appearance"
    
    // MARK: - Temperature Unit
    
    private static let unitKey = "isCelsius"
        
        static var isCelsius: Bool {
            get { UserDefaults.standard.bool(forKey: unitKey) }
            set { UserDefaults.standard.set(newValue, forKey: unitKey) }
        }
        
        static func formatTemperature(_ tempCelsius: Double) -> String {
            if isCelsius {
                return "\(Int(tempCelsius))°C"
            } else {
                let fahrenheit = tempCelsius * 9/5 + 32
                return "\(Int(fahrenheit))°F"
            }
        }
    
    // MARK: - Appearance
    
    static var appearance: Int {
        get { UserDefaults.standard.integer(forKey: appearanceKey) }
        set { UserDefaults.standard.set(newValue, forKey: appearanceKey) }
    }
}
