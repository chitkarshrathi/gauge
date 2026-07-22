import Foundation
import SwiftUI
import Observation

@Observable
class SettingsManager {
    // Pro Automotive Units
    var distanceUnit: String { didSet { UserDefaults.standard.set(distanceUnit, forKey: "distanceUnit") } }
    var volumeUnit: String { didSet { UserDefaults.standard.set(volumeUnit, forKey: "volumeUnit") } }
    var efficiencyFormat: String { didSet { UserDefaults.standard.set(efficiencyFormat, forKey: "efficiencyFormat") } }
    
    // Core Preferences
    var baseCurrency: String { didSet { UserDefaults.standard.set(baseCurrency, forKey: "baseCurrency") } }
    var themePreference: String { didSet { UserDefaults.standard.set(themePreference, forKey: "themePreference") } }
    
    init() {
        self.distanceUnit = UserDefaults.standard.string(forKey: "distanceUnit") ?? "km"
        self.volumeUnit = UserDefaults.standard.string(forKey: "volumeUnit") ?? "L"
        self.efficiencyFormat = UserDefaults.standard.string(forKey: "efficiencyFormat") ?? "L/100km"
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
