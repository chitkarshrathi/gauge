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
                        
                        // MARK: - 1. Top Header & Add Vehicle
                        headerRow
                        
                        if !vehicles.isEmpty {
                            // MARK: - 2. Fleet Health Master Rings
                            fleetHealthHeader
                            
                            // MARK: - 3. Health Highlight Tiles
                            healthHighlightsRow
                        }
                        
                        // MARK: - 4. Quick Action Island
                        quickActionsRow
                        
                        // MARK: - 5. Vehicle Cards List
                        vehicleListSection
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
    
    // MARK: - UI Components
    
    private var headerRow: some View {
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
    }
    
    private var fleetHealthHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Concentric Activity Rings
                ZStack {
                    // Outer Ring: Documents Runway (Green)
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0.0, to: 0.90) // Next expiry > 30 days
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    // Middle Ring: Fleet Efficiency/Eco Score (Teal)
                    Circle()
                        .stroke(Color.teal.opacity(0.2), lineWidth: 10)
                        .frame(width: 66, height: 66)
                    Circle()
                        .trim(from: 0.0, to: 0.85) // Running 85% to baseline efficiency
                        .stroke(Color.teal, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))
                    
                    // Inner Ring: Maintenance Runway (Orange)
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 10)
                        .frame(width: 42, height: 42)
                    Circle()
                        .trim(from: 0.0, to: 0.60) // Shortest service runway
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
                            Circle().fill(Color.teal).frame(width: 8, height: 8)
                            Text("Efficiency: ") + Text("Optimal").bold()
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
    
    private var healthHighlightsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                HighlightTileView(
                    icon: "chart.line.uptrend.xyaxis", iconColor: .blue,
                    title: "Avg. Cost / km", value: "$0.14"
                )
                HighlightTileView(
                    icon: "dollarsign.circle.fill", iconColor: .green,
                    title: "30-Day Fleet Spend", value: "$412.50"
                )
                HighlightTileView(
                    icon: "exclamationmark.triangle.fill", iconColor: .orange,
                    title: "Active Alerts", value: "1 Alert"
                )
            }
            .padding(.horizontal)
        }
    }
    
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
    
    private var vehicleListSection: some View {
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
    
    // MARK: - Vehicle Card Component
    private func vehicleCard(for vehicle: Vehicle) -> some View {
        let latestOdometer = vehicle.logs.map { $0.odometer }.max() ?? 0
        let displayOdo = latestOdometer > 0 ? "\(Int(latestOdometer)) km" : "No logs yet"
        
        return HStack(spacing: 16) {
            // LEFT SIDE: Vehicle Identity & Stats
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(vehicle.makeModel)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                }
                
                Text("\(vehicle.year) • \(vehicle.licensePlate) • \(displayOdo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // The "iPhone Storage" style multi-color expense bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.blue).frame(width: geo.size.width * 0.5) // Fuel (50%)
                        RoundedRectangle(cornerRadius: 2).fill(Color.orange).frame(width: geo.size.width * 0.3) // Maint (30%)
                        RoundedRectangle(cornerRadius: 2).fill(Color.purple).frame(width: geo.size.width * 0.2) // Docs/Fixed (20%)
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)
                .padding(.bottom, 2)
                
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
                    
                    // Maintenance Ring (Orange)
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
                    .foregroundStyle(.tertiary) // Fixed from earlier errors
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
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

// MARK: - Highlight Tile Sub-Component
struct HighlightTileView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 140, alignment: .leading)
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
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
                Section {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundColor(.blue)
                            Text("Financial Report")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption.bold())
                        }
                    }
                }
                
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

// MARK: - Add Vehicle View
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
