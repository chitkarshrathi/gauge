import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        NavigationStack {
            @Bindable var bindableSettings = settings
            
            Form {
                Section(header: Text("Units & Formatting")) {
                    Picker("Distance", selection: $bindableSettings.distanceUnit) {
                        Text("Kilometers (km)").tag("km")
                        Text("Miles (mi)").tag("mi")
                    }
                    
                    Picker("Volume", selection: $bindableSettings.volumeUnit) {
                        Text("Liters (L)").tag("L")
                        Text("US Gallons (gal)").tag("US gal")
                        Text("UK Gallons (gal)").tag("UK gal")
                    }
                    
                    Picker("Efficiency", selection: $bindableSettings.efficiencyFormat) {
                        Text("L/100km").tag("L/100km")
                        Text("km/L").tag("km/L")
                        Text("US MPG").tag("US MPG")
                        Text("UK MPG").tag("UK MPG")
                    }
                }
                
                Section(header: Text("Localization")) {
                    Picker("Base Currency", selection: $bindableSettings.baseCurrency) {
                        Text("Canadian Dollar (CAD)").tag("CAD")
                        Text("US Dollar (USD)").tag("USD")
                    }
                    Text("When traveling, Gauge will automatically suggest local currencies and convert them to your Base Currency using live mid-market rates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Display")) {
                    Picker("Appearance", selection: $bindableSettings.themePreference) {
                        Text("System Match").tag("System")
                        Text("Light Mode").tag("Light")
                        Text("Dark Mode").tag("Dark")
                    }
                }
                
                Section(header: Text("About"), footer: Text("Built proudly in Alberta, Canada by ASCII Automations. ")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0 (Travel Edition)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .padding(.bottom, 100)
        }
    }
}
