import SwiftUI
import SwiftData

struct AddLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsManager.self) private var settings
    
    @Query(sort: \Vehicle.makeModel) private var vehicles: [Vehicle]
    @Query private var members: [FamilyMember]
    
    @State private var odometerText: String = ""
    @State private var totalFuelText: String = ""
    @State private var priceText: String = ""
    @State private var logDate: Date = Date()
    @State private var isFullTank: Bool = true
    @State private var drivingContext: String = "mixed"
    @State private var fuelType: String = "Regular"
    @State private var selectedVehicle: Vehicle?
    @State private var selectedPayer: FamilyMember?
    
    // Always-Available Unit Overrides
    @State private var localDistanceUnit: String = "km"
    @State private var localVolumeUnit: String = "L"
    
    // Travel Engine (Now exclusively manages Currency)
    @State private var locationManager = LocationManager()
    @State private var isTravelMode = false
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let contextOptions = ["city", "highway", "mountain", "mixed"]
    let fuelOptions = ["Regular", "Midgrade", "Premium", "Diesel"]
    
    var detectedForeignCurrency: String? {
        if settings.baseCurrency == "CAD" && locationManager.currentCountryCode == "US" { return "USD" }
        if settings.baseCurrency == "USD" && locationManager.currentCountryCode == "CA" { return "CAD" }
        return nil
    }
    
    var activeCurrencyLabel: String {
        isTravelMode ? (detectedForeignCurrency ?? settings.baseCurrency) : settings.baseCurrency
    }
    
    var isCrossFill: Bool {
        guard let vehicle = selectedVehicle else { return false }
        return !vehicle.makeModel.contains("Chitkarsh")
    }
    
    // Raw Base Odometer from the database
    var previousBaseOdometer: Double? {
        guard let vehicle = selectedVehicle else { return nil }
        return vehicle.logs.filter { $0.date <= logDate }
                           .sorted { $0.date > $1.date }
                           .first?.odometer
    }
    
    // Dynamically converts the validation hint if the user toggles the inline unit switch
    var convertedPreviousOdometer: Double? {
        guard let prev = previousBaseOdometer else { return nil }
        let baseIsMi = settings.distanceUnit.lowercased().contains("mi")
        let localIsMi = localDistanceUnit == "mi"
        
        if baseIsMi && !localIsMi { return prev * 1.60934 } // Base is Mi, UI is Km
        if !baseIsMi && localIsMi { return prev * 0.621371 } // Base is Km, UI is Mi
        return prev
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Travel Mode is now strictly for Financials
                if let foreignCurrency = detectedForeignCurrency {
                    Section {
                        Toggle(isOn: $isTravelMode) {
                            VStack(alignment: .leading) {
                                Text("Travel Detected")
                                Text("Log transaction cost in \(foreignCurrency)?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Vehicle", selection: $selectedVehicle) {
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.makeModel).tag(vehicle as Vehicle?)
                        }
                    }
                }
                
                if isCrossFill {
                    Section(header: Text("Cross-Vehicle Fill-Up"), footer: Text("You are logging a fill-up for someone else's vehicle.")) {
                        Picker("Paid By", selection: $selectedPayer) {
                            Text("Select Payer").tag(FamilyMember?.none)
                            ForEach(members) { member in
                                Text(member.name).tag(FamilyMember?.some(member))
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Fill-Up Details")) {
                    DatePicker("Date & Time", selection: $logDate)
                    
                    // ODOMETER with inline unit switcher & dynamic validation
                    HStack(alignment: .top) {
                        Text("Odometer")
                            .padding(.top, 8)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 8) {
                                TextField("e.g. 45000", text: $odometerText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                
                                Menu {
                                    Button("km") { localDistanceUnit = "km" }
                                    Button("mi") { localDistanceUnit = "mi" }
                                } label: {
                                    HStack(spacing: 2) {
                                        Text(localDistanceUnit)
                                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 10))
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(6)
                                }
                            }
                            
                            if let prevOdoLocal = convertedPreviousOdometer {
                                let enteredOdo = Double(odometerText) ?? 0
                                let isInvalid = !odometerText.isEmpty && enteredOdo <= prevOdoLocal
                                Text("Last: \(Int(prevOdoLocal)) \(localDistanceUnit)")
                                    .font(.caption2)
                                    .foregroundColor(isInvalid ? .red : .secondary)
                                    .animation(.easeInOut, value: isInvalid)
                            }
                        }
                    }
                    
                    // FUEL ADDED with inline unit switcher
                    HStack {
                        Text("Fuel Added")
                        Spacer()
                        HStack(spacing: 8) {
                            TextField("e.g. 40.5", text: $totalFuelText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            
                            Menu {
                                Button("L") { localVolumeUnit = "L" }
                                Button("gal") { localVolumeUnit = "gal" }
                            } label: {
                                HStack(spacing: 2) {
                                    Text(localVolumeUnit)
                                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 10))
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(6)
                            }
                        }
                    }
                    
                    // TOTAL COST
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        HStack(spacing: 8) {
                            TextField("e.g. 55.00", text: $priceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            
                            Text(activeCurrencyLabel)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(6)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fuel Grade")
                        HStack(spacing: 8) {
                            ForEach(fuelOptions, id: \.self) { option in
                                Button(action: { fuelType = option }) {
                                    Text(option)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(fuelType == option ? Color.blue : Color(uiColor: .tertiarySystemFill))
                                        .foregroundColor(fuelType == option ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Picker("Driving Context", selection: $drivingContext) {
                        ForEach(contextOptions, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    Toggle("Filled to Full?", isOn: $isFullTank)
                } footer: {
                    Text("Turn off 'Filled to Full' for partial fills to keep efficiency math accurate.")
                }
            }
            .navigationTitle("New Log")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut, value: isCrossFill)
            .onAppear {
                if selectedVehicle == nil { selectedVehicle = vehicles.first }
                if selectedPayer == nil { selectedPayer = members.first(where: { $0.name == "Chitkarsh" }) }
                
                // Inherit default units from settings to start
                localDistanceUnit = settings.distanceUnit.lowercased().contains("mi") ? "mi" : "km"
                localVolumeUnit = settings.volumeUnit.lowercased().contains("gal") ? "gal" : "L"
                
                locationManager.requestPermissionAndStart()
            }
            .onChange(of: detectedForeignCurrency) { _, newValue in
                if newValue != nil { withAnimation { isTravelMode = true } }
            }
            .alert("Invalid Data", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveLog() }
                        .disabled(isSaving || odometerText.isEmpty || totalFuelText.isEmpty || priceText.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Smart Failsafe & Base Normalization
    private func saveLog() {
        guard let odoInput = Double(odometerText), let fuelInput = Double(totalFuelText),
              let localPriceInput = Double(priceText), let vehicle = selectedVehicle else {
            alertMessage = "Please fill in all fields with valid numbers."
            showAlert = true
            return
        }
        
        // Failsafe validation against the localized previous reading
        if let prevOdoLocal = convertedPreviousOdometer, odoInput <= prevOdoLocal {
            alertMessage = "Odometer reading (\(Int(odoInput))) must be higher than your previous fill-up (\(Int(prevOdoLocal)))."
            showAlert = true
            return
        }
        
        isSaving = true
        
        Task { @MainActor in
            // 1. Normalize Distance to Base Unit
            let baseIsMi = settings.distanceUnit.lowercased().contains("mi")
            let localIsMi = localDistanceUnit == "mi"
            var normalizedOdo = odoInput
            
            if baseIsMi && !localIsMi { normalizedOdo = odoInput * 0.621371 } // km to mi
            else if !baseIsMi && localIsMi { normalizedOdo = odoInput * 1.60934 } // mi to km
            
            // Validate future logs against the normalized database value
            let futureLogs = vehicle.logs.filter { $0.date > logDate }.sorted { $0.date < $1.date }
            if let nextLog = futureLogs.first, normalizedOdo >= nextLog.odometer {
                alertMessage = "Odometer reading cannot be higher than a future fill-up."
                isSaving = false
                showAlert = true
                return
            }
            
            // 2. Normalize Volume to Base Unit
            let baseIsGal = settings.volumeUnit.lowercased().contains("gal")
            let localIsGal = localVolumeUnit == "gal"
            var normalizedFuel = fuelInput
            
            if baseIsGal && !localIsGal { normalizedFuel = fuelInput * 0.264172 } // L to gal
            else if !baseIsGal && localIsGal { normalizedFuel = fuelInput * 3.78541 } // gal to L
            
            // 3. Normalize Currency to Base Unit
            var finalExchangeRate = 1.0
            var finalBasePrice = localPriceInput
            
            if isTravelMode, let target = detectedForeignCurrency {
                do {
                    finalExchangeRate = try await ExchangeRateService.fetchRate(from: target, to: settings.baseCurrency)
                    finalBasePrice = localPriceInput * finalExchangeRate
                } catch {
                    finalExchangeRate = 1.0
                    finalBasePrice = localPriceInput
                }
            }
            
            let newLog = FuelLog(
                odometer: normalizedOdo, fuelVolume: normalizedFuel, price: finalBasePrice,
                localCurrency: activeCurrencyLabel, localPrice: localPriceInput,
                exchangeRate: finalExchangeRate, fuelType: fuelType, date: logDate,
                isFullTank: isFullTank, drivingContext: drivingContext
            )
            
            newLog.vehicle = vehicle
            newLog.payer = isCrossFill ? selectedPayer : members.first(where: { $0.name == "Chitkarsh" })
            
            modelContext.insert(newLog)
            dismiss()
        }
    }
}
