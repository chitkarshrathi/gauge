import SwiftUI
import SwiftData

struct EditLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsManager.self) private var settings
    @Query private var vehicles: [Vehicle]
    
    // @Bindable automatically saves changes to SwiftData in real-time
    @Bindable var log: FuelLog
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Assign to Vehicle")) {
                    Picker("Vehicle", selection: $log.vehicle) {
                        Text("Unknown / Orphaned").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.makeModel).tag(vehicle as Vehicle?)
                        }
                    }
                }
                
                Section(header: Text("Log Details")) {
                    DatePicker("Date & Time", selection: $log.date)
                    
                    HStack {
                        Text("Odometer")
                        Spacer()
                        TextField("Odometer", value: $log.odometer, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fuel (\(settings.volumeUnit))")
                        Spacer()
                        TextField("Fuel", value: $log.fuelVolume, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Cost ($)")
                        Spacer()
                        TextField("Cost", value: $log.price, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Toggle("Filled to Full", isOn: $log.isFullTank)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
