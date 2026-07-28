import SwiftUI
import SwiftData

// MARK: - Quick Action Item Model
struct QuickActionItem: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

struct GarageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.makeModel) private var vehicles: [Vehicle]
    
    @State private var showAddVehicle = false
    @State private var selectedVehicleForDetail: Vehicle?
    
    // Quick Action Sheets
    @State private var activeQuickAction: QuickActionItem?
    @State private var showCustomizeActions = false
    
    // Customizable Quick Action Bar state
    @State private var quickActions: [QuickActionItem] = [
        QuickActionItem(id: "oil", name: "Oil Change", icon: "drop.fill", color: .orange),
        QuickActionItem(id: "parking", name: "Parking", icon: "parkingsign.circle.fill", color: .blue),
        QuickActionItem(id: "toll", name: "Tolls", icon: "tag.fill", color: .purple),
        QuickActionItem(id: "wash", name: "Car Wash", icon: "sparkles", color: .teal)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - 1. Top Header & Add Vehicle Button
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("My Garage")
                                    .font(.system(size: 32, weight: .bold))
                                Text("\(vehicles.count) \(vehicles.count == 1 ? "Vehicle" : "Vehicles") Tracked")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Button(action: { showAddVehicle = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // MARK: - 2. Fleet Health Master Rings Header
                        if !vehicles.isEmpty {
                            fleetHealthHeader
                        }
                        
                        // MARK: - 3. Quick Action Row
                        quickActionsRow
                        
                        // MARK: - 4. Vehicle Cards List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fleet")
                                .font(.title3.weight(.bold))
                                .padding(.horizontal)
                            
                            if vehicles.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(vehicles) { vehicle in
                                    Button(action: { selectedVehicleForDetail = vehicle }) {
                                        vehicleCard(for: vehicle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 130)
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
            .sheet(item: $activeQuickAction) { action in
                QuickLogSheet(action: action, vehicles: vehicles)
            }
            .sheet(isPresented: $showCustomizeActions) {
                CustomizeQuickActionsSheet(currentActions: $quickActions)
            }
            .sheet(item: $selectedVehicleForDetail) { vehicle in
                VehicleDetailPlaceholderView(vehicle: vehicle)
            }
        }
    }
    
    // MARK: - Fleet Health Master Rings Header
    private var fleetHealthHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Concentric Activity Rings
                ZStack {
                    // Outer Ring: Documents Compliance (Green)
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0.0, to: 0.90) // 90% compliant
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    // Middle Ring: Budget Health (Blue)
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 10)
                        .frame(width: 66, height: 66)
                    Circle()
                        .trim(from: 0.0, to: 0.75) // 75% budget remaining
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))
                    
                    // Inner Ring: Maintenance (Amber)
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 10)
                        .frame(width: 42, height: 42)
                    Circle()
                        .trim(from: 0.0, to: 0.60) // Service due soon
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(-90))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fleet Health Status")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("Documents: ") + Text("Valid").bold()
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color.blue).frame(width: 8, height: 8)
                            Text("Fuel Budget: ") + Text("On Track").bold()
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color.orange).frame(width: 8, height: 8)
                            Text("Maintenance: ") + Text("1 Due Soon").bold()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Quick Action Island
    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quickActions) { action in
                    Button(action: { activeQuickAction = action }) {
                        HStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(action.color)
                            Text(action.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Customize Button
                Button(action: { showCustomizeActions = true }) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Vehicle Card Component
    private func vehicleCard(for vehicle: Vehicle) -> some View {
        let latestOdometer = vehicle.logs.map { $0.odometer }.max() ?? 0
        let displayOdo = latestOdometer > 0 ? "\(Int(latestOdometer)) km" : "No logs yet"
        
        return HStack(spacing: 16) {
            // LEFT SIDE: Vehicle Identity & Status
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(vehicle.makeModel)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }
                
                Text("\(vehicle.year) • \(vehicle.licensePlate) • \(displayOdo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Dynamic Health Status Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption2)
                    Text("Road Ready")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // RIGHT SIDE: Micro Health Rings + Chevron
            HStack(spacing: 12) {
                ZStack {
                    // Documents Ring (Green)
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 4)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: 1.0)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    
                    // Maintenance Ring (Amber/Blue)
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 4)
                        .frame(width: 26, height: 26)
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 26, height: 26)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 44))
                .foregroundColor(.gray.opacity(0.4))
            Text("No vehicles in your garage")
                .font(.headline)
            Text("Tap '+' to add your vehicle and start tracking maintenance, documents, and expenses.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Quick Log Sheet
struct QuickLogSheet: View {
    let action: QuickActionItem
    let vehicles: [Vehicle]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedVehicle: Vehicle?
    @State private var costText: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle")) {
                    Picker("Select Vehicle", selection: $selectedVehicle) {
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.makeModel).tag(vehicle as Vehicle?)
                        }
                    }
                }
                
                Section(header: Text("Details")) {
                    HStack {
                        Text("Amount Spent")
                        Spacer()
                        TextField("0.00", text: $costText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes (Optional)", text: $notes)
                }
            }
            .navigationTitle("Log \(action.name)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if selectedVehicle == nil { selectedVehicle = vehicles.first } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .disabled(costText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Customize Quick Actions Sheet
struct CustomizeQuickActionsSheet: View {
    @Binding var currentActions: [QuickActionItem]
    @Environment(\.dismiss) private var dismiss
    
    let availableActions = [
        QuickActionItem(id: "oil", name: "Oil Change", icon: "drop.fill", color: .orange),
        QuickActionItem(id: "parking", name: "Parking", icon: "parkingsign.circle.fill", color: .blue),
        QuickActionItem(id: "toll", name: "Tolls", icon: "tag.fill", color: .purple),
        QuickActionItem(id: "wash", name: "Car Wash", icon: "sparkles", color: .teal),
        QuickActionItem(id: "ticket", name: "Ticket/Fine", icon: "exclamationmark.triangle.fill", color: .red),
        QuickActionItem(id: "service", name: "Service", icon: "wrench.and.screwdriver.fill", color: .gray)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Active Quick Actions")) {
                    ForEach(availableActions, id: \.id) { action in
                        let isActive = currentActions.contains(where: { $0.id == action.id })
                        HStack {
                            Image(systemName: action.icon)
                                .foregroundColor(action.color)
                                .frame(width: 24)
                            Text(action.name)
                            Spacer()
                            if isActive {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isActive {
                                currentActions.removeAll(where: { $0.id == action.id })
                            } else {
                                currentActions.append(action)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customize Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Vehicle Detail Placeholder View
struct VehicleDetailPlaceholderView: View {
    let vehicle: Vehicle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Glovebox Documents")) {
                    Label("Insurance Policy", systemImage: "doc.text.fill")
                    Label("Vehicle Registration", systemImage: "shield.fill")
                }
                Section(header: Text("Service Timeline")) {
                    Text("No upcoming service due.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(vehicle.makeModel)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Inline view to create a new vehicle matching the scalable schema
struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var makeModel: String = ""
    @State private var vehicleClass: String = "sedan"
    @State private var year: Int = 2024
    @State private var licensePlate: String = ""
    @State private var isAWD: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle Details")) {
                    TextField("Make & Model (e.g. Honda Civic)", text: $makeModel)
                    
                    Picker("Vehicle Class", selection: $vehicleClass) {
                        Text("Sedan").tag("sedan")
                        Text("SUV").tag("suv")
                        Text("Truck").tag("truck")
                        Text("Hybrid/EV").tag("hybrid")
                    }
                    
                    Picker("Model Year", selection: $year) {
                        ForEach((2000...2026).reversed(), id: \.self) { yr in
                            Text(String(yr)).tag(yr)
                        }
                    }
                    
                    TextField("License Plate", text: $licensePlate)
                    Toggle("All-Wheel Drive (AWD)", isOn: $isAWD)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveVehicle() }
                        .disabled(makeModel.isEmpty || licensePlate.isEmpty)
                }
            }
        }
    }
    
    private func saveVehicle() {
        let newVehicle = Vehicle(
            makeModel: makeModel,
            vehicleClass: vehicleClass,
            year: year,
            licensePlate: licensePlate,
            isAWD: isAWD
        )
        modelContext.insert(newVehicle)
        dismiss()
    }
}
