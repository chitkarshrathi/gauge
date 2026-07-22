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
            // Simulated car color chip
            Circle()
                .fill(Color(hex: vehicle.colorHex) ?? .blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: vehicle.vehicleType == "electric" ? "bolt.car.fill" : "car.fill")
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.makeModel)
                    .font(.headline)
                Text("\(vehicle.vehicleType.capitalized) Engine")
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

// Inline view to create a new vehicle
struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var makeModel: String = ""
    @State private var vehicleType: String = "gas"
    @State private var selectedColor: Color = .blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle Details")) {
                    TextField("Make & Model (e.g. Honda Civic)", text: $makeModel)
                    
                    Picker("Engine Type", selection: $vehicleType) {
                        Text("Gasoline").tag("gas")
                        Text("Diesel").tag("diesel")
                        Text("Electric").tag("electric")
                    }
                    
                    ColorPicker("Vehicle Color", selection: $selectedColor)
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
                    .disabled(makeModel.isEmpty)
                }
            }
        }
    }
    
    private func saveVehicle() {
        // Convert SwiftUI Color to a Hex String to store in SwiftData
        let uiColor = UIColor(selectedColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hexString = String(format: "#%02lX%02lX%02lX",
                               lroundf(Float(red * 255)),
                               lroundf(Float(green * 255)),
                               lroundf(Float(blue * 255)))
        
        let newVehicle = Vehicle(makeModel: makeModel, colorHex: hexString, vehicleType: vehicleType)
        modelContext.insert(newVehicle)
        dismiss()
    }
}

// Helper extension to convert hex strings back to SwiftUI Colors
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        self.init(red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                  green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: Double(rgb & 0x0000FF) / 255.0)
    }
}
