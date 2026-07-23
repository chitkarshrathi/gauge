import Foundation
import SwiftUI
import Observation

@Observable
class SettingsManager {
    // Pro Automotive Units & Region
    var country: String { didSet { UserDefaults.standard.set(country, forKey: "country") } }
    var distanceUnit: String { didSet { UserDefaults.standard.set(distanceUnit, forKey: "distanceUnit") } }
    var volumeUnit: String { didSet { UserDefaults.standard.set(volumeUnit, forKey: "volumeUnit") } }
    var efficiencyFormat: String { didSet { UserDefaults.standard.set(efficiencyFormat, forKey: "efficiencyFormat") } }
    
    // Core Preferences
    var baseCurrency: String { didSet { UserDefaults.standard.set(baseCurrency, forKey: "baseCurrency") } }
    var themePreference: String { didSet { UserDefaults.standard.set(themePreference, forKey: "themePreference") } }
    
    init() {
        // 1. Determine region dynamically for first-time launch defaults
        let regionCode = Locale.current.region?.identifier ?? "US"
        let defaultCountry: String
        let defaultDistance: String
        let defaultVolume: String
        let defaultEfficiency: String
        
        switch regionCode {
        case "CA":
            defaultCountry = "Canada"
            defaultDistance = "km"
            defaultVolume = "Liters"
            defaultEfficiency = "L/100km"
        case "US":
            defaultCountry = "United States"
            defaultDistance = "mi"
            defaultVolume = "US Gallons"
            defaultEfficiency = "US MPG"
        case "GB":
            defaultCountry = "United Kingdom"
            defaultDistance = "mi"
            defaultVolume = "Liters" // UK sells in liters
            defaultEfficiency = "UK MPG"
        case "IN":
            defaultCountry = "India"
            defaultDistance = "km"
            defaultVolume = "Liters"
            defaultEfficiency = "km/L"
        default:
            defaultCountry = "ROW"
            defaultDistance = "km"
            defaultVolume = "Liters"
            defaultEfficiency = "L/100km"
        }
        
        // 2. Load from UserDefaults, or fallback to the smart defaults
        self.country = UserDefaults.standard.string(forKey: "country") ?? defaultCountry
        self.distanceUnit = UserDefaults.standard.string(forKey: "distanceUnit") ?? defaultDistance
        self.volumeUnit = UserDefaults.standard.string(forKey: "volumeUnit") ?? defaultVolume
        self.efficiencyFormat = UserDefaults.standard.string(forKey: "efficiencyFormat") ?? defaultEfficiency
        self.baseCurrency = UserDefaults.standard.string(forKey: "baseCurrency") ?? "CAD"
        self.themePreference = UserDefaults.standard.string(forKey: "themePreference") ?? "System"
    }
    
    var colorScheme: ColorScheme? {
        switch themePreference {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
}
