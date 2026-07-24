import SwiftUI
import SwiftData
import UIKit

struct AddLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsManager.self) private var settings
    
    @Query private var vehicles: [Vehicle]
    
    @State private var odometerText: String = ""
    @State private var totalFuelText: String = ""
    @State private var priceText: String = ""
    @State private var logDate: Date = Date()
    @State private var isFullTank: Bool = true
    @State private var drivingContext: String = "mixed"
    @State private var fuelType: String = "Regular"
    @State private var selectedVehicle: Vehicle?
    
    // NEW: Travel Engine States
    @State private var locationManager = LocationManager()
    @State private var isTravelMode = false
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let contextOptions = ["city", "highway", "mountain", "mixed"]
    let fuelOptions = ["Regular", "Midgrade", "Premium", "Diesel"]
    
    // Smart computed property to figure out what country we crossed into
    var detectedForeignCurrency: String? {
        if settings.baseCurrency == "CAD" && locationManager.currentCountryCode == "US" { return "USD" }
        if settings.baseCurrency == "USD" && locationManager.currentCountryCode == "CA" { return "CAD" }
        return nil
    }
    
    // The active currency label for the UI
    var activeCurrencyLabel: String {
        isTravelMode ? (detectedForeignCurrency ?? settings.baseCurrency) : settings.baseCurrency
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // FIXED: Added uiColor parameter label
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("New Log")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.top, 10)
                    
                    // NEW: Smart Travel Banner
                    if let foreignCurrency = detectedForeignCurrency {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Travel Detected")
                                    .font(.subheadline.weight(.bold))
                                Text("Log this fill-up in \(foreignCurrency)?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $isTravelMode)
                                .labelsHidden()
                                .tint(.blue)
                        }
                        .padding(14)
                        .background(Color.blue.opacity(isTravelMode ? 0.15 : 0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(isTravelMode ? 0.3 : 0.1), lineWidth: 1))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if !vehicles.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Vehicle").font(.headline)
                            Picker("Select Vehicle", selection: $selectedVehicle) {
                                ForEach(vehicles) { vehicle in
                                    Text(vehicle.makeModel).tag(vehicle as Vehicle?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // FIXED
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    } else {
                        Text("Please add a vehicle in the Garage first.")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date & Time").font(.headline)
                        DatePicker("", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(10)
                            // FIXED
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Odometer (\(settings.distanceUnit))").font(.headline)
                        TextField("e.g. 45000", text: $odometerText)
                            .keyboardType(.decimalPad)
                            .padding()
                            // FIXED
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fuel Added (\(settings.volumeUnit))").font(.headline)
                        TextField("e.g. 40.5", text: $totalFuelText)
                            .keyboardType(.decimalPad)
                            .padding()
                            // FIXED
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Cost (\(activeCurrencyLabel))").font(.headline)
                        TextField("e.g. 55.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .padding()
                            // FIXED
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    
                    // ADDED: Missing UI for Fuel Type
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fuel Type").font(.headline)
                        Picker("Fuel Grade", selection: $fuelType) {
                            ForEach(fuelOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // ADDED: Missing UI for Driving Context
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Driving Context").font(.headline)
                        Picker("Context", selection: $drivingContext) {
                            ForEach(contextOptions, id: \.self) { option in
                                Text(option.capitalized).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Toggle(isOn: $isFullTank) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Filled to Full?").font(.headline)
                            Text("Turn off for partial fills to keep efficiency math accurate.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Button dynamically shows loading state
                    Button(action: saveLog) {
                        ZStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Log")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 4)
                    }
                    .disabled(isSaving)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            if selectedVehicle == nil { selectedVehicle = vehicles.first }
            // Boot up the GPS scanner silently in the background
            locationManager.requestPermissionAndStart()
        }
        // Auto-suggest Travel Mode if we detect a border crossing
        .onChange(of: detectedForeignCurrency) { _, newValue in
            if newValue != nil {
                withAnimation { isTravelMode = true }
            }
        }
        .alert("Invalid Data", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveLog() {
        guard let odo = Double(odometerText), let fuel = Double(totalFuelText),
              let localPriceInput = Double(priceText), let vehicle = selectedVehicle else {
            alertMessage = "Please fill in all fields with valid numbers."
            showAlert = true
            return
        }
        
        let vehicleLogs = vehicle.logs.sorted { $0.date > $1.date }
        if let latestLog = vehicleLogs.first, odo <= latestLog.odometer {
            alertMessage = "Odometer reading must be higher than your last fill-up."
            showAlert = true
            return
        }
        
        isSaving = true
        
        // Asynchronous Network Task
        Task { @MainActor in
            var finalExchangeRate = 1.0
            var finalBasePrice = localPriceInput
            
            // If they are logging in USD but their app base is CAD
            if isTravelMode, let target = detectedForeignCurrency {
                do {
                    // Instantly fetch the live conversion rate
                    finalExchangeRate = try await ExchangeRateService.fetchRate(from: target, to: settings.baseCurrency)
                    finalBasePrice = localPriceInput * finalExchangeRate
                } catch {
                    // Hackathon fallback if offline
                    finalExchangeRate = 1.0
                    finalBasePrice = localPriceInput
                }
            }
            
            // Note: Ensure your FuelLog model in Schema has been updated to accept these new parameters!
            let newLog = FuelLog(
                odometer: odo,
                fuelVolume: fuel,
                price: finalBasePrice, // The converted amount for charts
                localCurrency: activeCurrencyLabel, // The exact receipt currency
                localPrice: localPriceInput, // The exact receipt amount
                exchangeRate: finalExchangeRate,
                fuelType: fuelType,
                date: logDate,
                isFullTank: isFullTank,
                drivingContext: drivingContext
            )
            
            newLog.vehicle = vehicle
            modelContext.insert(newLog)
            dismiss()
        }
    }
}
