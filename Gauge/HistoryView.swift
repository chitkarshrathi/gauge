import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsManager.self) private var settings
    
    @Query(sort: \Vehicle.makeModel) private var vehicles: [Vehicle]
    @Query(sort: \FuelLog.date, order: .reverse) private var logs: [FuelLog]
    
    @State private var selectedVehicleId: String = "all"
    @State private var logToEdit: FuelLog?
    
    var filteredLogs: [FuelLog] {
        if selectedVehicleId == "all" {
            return logs
        } else {
            return logs.filter { $0.vehicle?.id.uuidString == selectedVehicleId }
        }
    }
    
    var unitLabel: String {
        settings.volumeUnit
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Log History")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .sheet(item: $logToEdit) { log in
                                EditLogView(log: log)
                            }
                
                // Vehicle Filter Pill-Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        filterButton(title: "All Vehicles", icon: "car.2.fill", id: "all")
                        
                        ForEach(vehicles) { vehicle in
                            filterButton(title: vehicle.makeModel, icon: "car.fill", id: vehicle.id.uuidString)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
                
                // Log Cards
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        if filteredLogs.isEmpty {
                            Text("No logs found for your selection.")
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredLogs) { log in
                                logCard(for: log)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 130) // Extra padding to clear the floating bottom bar
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private func filterButton(title: String, icon: String, id: String) -> some View {
        let isActive = selectedVehicleId == id
        return Button(action: { selectedVehicleId = id }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isActive ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
            .foregroundColor(isActive ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    private func logCard(for log: FuelLog) -> some View {
        let carName = log.vehicle?.makeModel ?? "Unknown Vehicle"
        
        return VStack(spacing: 0) {
            // Card Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 12))
                    Text(carName)
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(8)
                
                Spacer()
                
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 10)
            
            Divider()
            
            // Card Body
            HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cost: $\(log.price, specifier: "%.2f")")
                                    .font(.subheadline.weight(.medium))
                                Text("Fuel: \(log.fuelVolume, specifier: "%.2f") \(unitLabel)")
                                    .font(.subheadline.weight(.medium))
                                Text("Odo: \(log.odometer, specifier: "%.0f")")
                                    .font(.subheadline.weight(.medium))
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // EDIT BUTTON
                                Button(action: { logToEdit = log }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                // DELETE BUTTON
                                Button(action: { modelContext.delete(log) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                        .padding(10)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}
