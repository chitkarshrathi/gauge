import Foundation
import SwiftUI
import Observation

@Observable
class SettingsManager {
    // MARK: - Profile State
    var country: String { didSet { handleRegionChange(country) } }
    var zipCode: String { didSet { UserDefaults.standard.set(zipCode, forKey: "zipCode") } }
    var dateOfBirth: Date? { didSet { saveDOB(dateOfBirth) } }
    
    // MARK: - App Preferences
    var distanceUnit: String { didSet { UserDefaults.standard.set(distanceUnit, forKey: "distanceUnit") } }
    var volumeUnit: String { didSet { UserDefaults.standard.set(volumeUnit, forKey: "volumeUnit") } }
    var efficiencyFormat: String { didSet { UserDefaults.standard.set(efficiencyFormat, forKey: "efficiencyFormat") } }
    var themePreference: String { didSet { UserDefaults.standard.set(themePreference, forKey: "themePreference") } }
    var baseCurrency: String { didSet { UserDefaults.standard.set(baseCurrency, forKey: "baseCurrency") } } // RESTORED
    
    init() {
        // 1. Determine region dynamically for first-time launch defaults
        let regionCode = Locale.current.region?.identifier ?? "CA"
        let defaultCountry: String
        
        switch regionCode {
        case "CA": defaultCountry = "Canada"
        case "US": defaultCountry = "United States"
        case "GB": defaultCountry = "United Kingdom"
        case "IN": defaultCountry = "India"
        default:   defaultCountry = "ROW"
        }
        
        // 2. Pre-initialize properties with temporary fallbacks
        self.distanceUnit = "km"
        self.volumeUnit = "Liters"
        self.efficiencyFormat = "L/100km"
        self.baseCurrency = "CAD"
        
        // 3. Load stored profile values
        self.zipCode = UserDefaults.standard.string(forKey: "zipCode") ?? ""
        
        if let timeInterval = UserDefaults.standard.object(forKey: "dateOfBirth") as? TimeInterval {
            self.dateOfBirth = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.dateOfBirth = Calendar.current.date(from: DateComponents(year: 2003, month: 11, day: 7))
        }
        
        self.themePreference = UserDefaults.standard.string(forKey: "themePreference") ?? "System"
        
        // 4. Set the country
        let savedCountry = UserDefaults.standard.string(forKey: "country") ?? defaultCountry
        self.country = savedCountry
        
        // 5. Restore saved custom units
        if let savedDistance = UserDefaults.standard.string(forKey: "distanceUnit") {
            self.distanceUnit = savedDistance
        }
        if let savedVolume = UserDefaults.standard.string(forKey: "volumeUnit") {
            self.volumeUnit = savedVolume
        }
        if let savedEfficiency = UserDefaults.standard.string(forKey: "efficiencyFormat") {
            self.efficiencyFormat = savedEfficiency
        }
        if let savedCurrency = UserDefaults.standard.string(forKey: "baseCurrency") {
            self.baseCurrency = savedCurrency
        } else {
            // Default currency based on region
            switch defaultCountry {
            case "Canada": self.baseCurrency = "CAD"
            case "United States": self.baseCurrency = "USD"
            case "United Kingdom": self.baseCurrency = "GBP"
            case "India": self.baseCurrency = "INR"
            default: self.baseCurrency = "USD"
            }
        }
    }
    
    // MARK: - Core Logic
    
    private func handleRegionChange(_ newCountry: String) {
        UserDefaults.standard.set(newCountry, forKey: "country")
        
        // Automatically cascade regional units and currency on country change
        switch newCountry {
        case "Canada":
            distanceUnit = "km"
            volumeUnit = "Liters"
            efficiencyFormat = "L/100km"
            baseCurrency = "CAD"
        case "United States":
            distanceUnit = "mi"
            volumeUnit = "US Gallons"
            efficiencyFormat = "US MPG"
            baseCurrency = "USD"
        case "United Kingdom":
            distanceUnit = "mi"
            volumeUnit = "Liters"
            efficiencyFormat = "UK MPG"
            baseCurrency = "GBP"
        case "India":
            distanceUnit = "km"
            volumeUnit = "Liters"
            efficiencyFormat = "km/L"
            baseCurrency = "INR"
        default:
            distanceUnit = "km"
            volumeUnit = "Liters"
            efficiencyFormat = "L/100km"
            baseCurrency = "USD"
        }
    }
    
    private func saveDOB(_ dob: Date?) {
        if let dob = dob {
            UserDefaults.standard.set(dob.timeIntervalSince1970, forKey: "dateOfBirth")
        } else {
            UserDefaults.standard.removeObject(forKey: "dateOfBirth")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch themePreference {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
}
