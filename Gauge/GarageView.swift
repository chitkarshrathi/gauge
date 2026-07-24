import SwiftUI
import SwiftData

struct GarageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.makeModel) private var vehicles: [Vehicle]
    
    @State private var showAddVehicle = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("My Garage")
                            .font(.system(size: 32, weight: .bold))
                        Spacer()
                        Button(action: { showAddVehicle = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    if vehicles.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "car.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No vehicles in your garage.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(vehicles) { vehicle in
                            vehicleCard(for: vehicle)
                        }
                    }
                }
                .padding(.bottom, 130)
            }
        }
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleView()
        }
    }
    
    private func vehicleCard(for vehicle: Vehicle) -> some View {
        HStack(spacing: 16) {
            // Vehicle Icon Container
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: vehicle.vehicleClass == "truck" ? "truck.pickup.side.fill" : "car.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.makeModel)
                    .font(.headline)
                Text("\(vehicle.vehicleClass.capitalized) • \(vehicle.year) • \(vehicle.licensePlate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive, action: { modelContext.delete(vehicle) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
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
                    Button("Save") {
                        saveVehicle()
                    }
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
