import SwiftUI
import SwiftData
import Charts

enum ViewMode: String, CaseIterable {
    case recent = "Last 4", month = "Month", year = "Year", all = "All"
}

enum ChartType {
    case efficiency, price
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsManager.self) private var settings
    
    @Query(sort: \Vehicle.makeModel) private var vehicles: [Vehicle]
    @Query(sort: \FuelLog.date, order: .reverse) private var logs: [FuelLog]
    
    @State private var viewMode: ViewMode = .recent // Defaulting to the new Last 4 view
    @State private var refDate: Date = Date()
    @State private var chartType: ChartType = .efficiency
    @State private var selectedVehicleId: String = "all"
    @State private var logToEdit: FuelLog?
    
    @State private var showAddLog = false
    
    var activeVehicle: Vehicle? {
        vehicles.first { $0.id.uuidString == selectedVehicleId }
    }
    
    var filteredLogs: [FuelLog] {
        var result = logs
        if selectedVehicleId != "all" {
            result = result.filter { $0.vehicle?.id.uuidString == selectedVehicleId }
        }
        
        let calendar = Calendar.current
        if viewMode == .recent {
            // Simply take the last 4 logs for the selected vehicle(s)
            result = Array(result.prefix(4))
        } else if viewMode != .all {
            result = result.filter { log in
                switch viewMode {
                case .year: return calendar.isDate(log.date, equalTo: refDate, toGranularity: .year)
                case .month: return calendar.isDate(log.date, equalTo: refDate, toGranularity: .month)
                default: return true
                }
            }
        }
        return result
    }
    
    var recentLogs: [FuelLog] { Array(filteredLogs.prefix(4)) }
    
    var displaySpent: Double { filteredLogs.reduce(0) { $0 + $1.price } }
    var totalVolume: Double { filteredLogs.reduce(0) { $0 + $1.fuelVolume } }
    var avgPricePerUnit: Double {
            let convertedTotal = convertedVolume(totalVolume)
            return convertedTotal > 0 ? displaySpent / convertedTotal : 0
        }
    
    var displayEfficiency: Double {
        var totalDistance: Double = 0
        let grouped = Dictionary(grouping: filteredLogs, by: { $0.vehicle?.id })
        for (_, vLogs) in grouped {
            let sorted = vLogs.sorted { $0.odometer < $1.odometer }
            if sorted.count > 1, let first = sorted.first, let last = sorted.last {
                totalDistance += (last.odometer - first.odometer)
            }
        }
        
        guard totalDistance > 0, totalVolume > 0 else { return 0 }
        
        let rawL100 = (totalVolume / totalDistance) * 100.0
        return UnitConverter.convertEfficiency(lPer100km: rawL100, to: settings.efficiencyFormat)
    }
    
    var efficiencyLabel: String { settings.efficiencyFormat }
    var unitLabel: String { settings.volumeUnit }
    
    private func convertedDistance(_ distanceKm: Double) -> Double {
        let isMiles = settings.distanceUnit.lowercased().starts(with: "mi")
        return isMiles ? distanceKm * 0.621371 : distanceKm
    }
    
    private func convertedVolume(_ volumeLiters: Double) -> Double {
            let unit = settings.volumeUnit.lowercased()
            if unit.contains("gal") {
                if unit.contains("uk") || unit.contains("imperial") {
                    return volumeLiters * 0.219969 // UK Imperial Gallons
                }
                return volumeLiters * 0.264172 // US Gallons
            }
            return volumeLiters // Default Liters
        }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerRow
                    filterTabs
                    paginator
                    
                    if filteredLogs.isEmpty {
                        emptyStateView
                    } else {
                        statsCard
                        chartCard
                        benchmarkCard
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Fill-ups")
                                .font(.title3.weight(.bold))
                                .padding(.horizontal)
                            
                            ForEach(recentLogs) { log in
                                logRow(for: log)
                            }
                        }
                    }
                }
                .padding(.bottom, 110)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showAddLog) {
                AddLogView()
            }
            .onAppear {
                if selectedVehicleId == "all" && vehicles.count == 1 {
                    selectedVehicleId = vehicles[0].id.uuidString
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var headerRow: some View {
        HStack {
            Menu {
                Button(action: { selectedVehicleId = "all" }) {
                    Label("All Vehicles", systemImage: selectedVehicleId == "all" ? "checkmark" : "")
                }
                Divider()
                ForEach(vehicles) { vehicle in
                    Button(action: { selectedVehicleId = vehicle.id.uuidString }) {
                        Label(vehicle.makeModel, systemImage: selectedVehicleId == vehicle.id.uuidString ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedVehicleId == "all" ? "car.2.fill" : "car.fill")
                    Text(selectedVehicleId == "all" ? "All Vehicles" : (activeVehicle?.makeModel ?? "My Vehicle"))
                        .font(.headline)
                    if vehicles.count > 1 {
                        Image(systemName: "chevron.down").font(.caption.weight(.bold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            Spacer()
            
            Button(action: { showAddLog = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var filterTabs: some View {
        HStack {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    viewMode = mode
                    refDate = Date()
                }) {
                    Text(mode.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewMode == mode ? Color.blue : Color.clear)
                        .foregroundColor(viewMode == mode ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .clipShape(Capsule())
        .padding(.horizontal)
    }
    
    private var paginator: some View {
        HStack {
            Button(action: { changePeriod(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.bold))
                    .foregroundColor((viewMode == .all || viewMode == .recent) ? .clear : .blue)
            }
            .disabled(viewMode == .all || viewMode == .recent)
            
            Spacer()
            Text(periodLabel)
                .font(.headline)
            Spacer()
            
            Button(action: { changePeriod(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.bold))
                    .foregroundColor((viewMode == .all || viewMode == .recent || !canGoForward) ? .clear : .blue)
            }
            .disabled(viewMode == .all || viewMode == .recent || !canGoForward)
        }
        .padding(.horizontal, 24)
    }
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Spent: $\(displaySpent, specifier: "%.2f")")
            Text("Avg Price: $\(avgPricePerUnit, specifier: "%.2f")/\(unitLabel)")
            Text("Avg Efficiency: \(displayEfficiency, specifier: "%.1f") \(efficiencyLabel)")
            Text("Fill-ups: \(filteredLogs.count)")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var chartCard: some View {
        VStack {
            Picker("Chart Type", selection: $chartType) {
                Text("Efficiency").tag(ChartType.efficiency)
                Text("Price per \(unitLabel)").tag(ChartType.price)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            
            Chart {
                let validLogs = filteredLogs.filter { distance(for: $0) > 0 }
                
                ForEach(validLogs) { log in
                    let yValue: Double = {
                        if chartType == .price {
                            let displayVol = convertedVolume(log.fuelVolume)
                            return log.fuelVolume > 0 ? (log.price / log.fuelVolume) : 0
                        } else {
                            let dist = distance(for: log)
                            let rawL100 = (log.fuelVolume / dist) * 100.0
                            return UnitConverter.convertEfficiency(lPer100km: rawL100, to: settings.efficiencyFormat)
                        }
                    }()
                    
                    if yValue > 0 {
                        if selectedVehicleId == "all" {
                            let vName = log.vehicle?.makeModel ?? "Unknown"
                            LineMark(x: .value("Date", log.date), y: .value("Value", yValue))
                                .interpolationMethod(.monotone)
                                .foregroundStyle(by: .value("Vehicle", vName))
                            
                            PointMark(x: .value("Date", log.date), y: .value("Value", yValue))
                                .foregroundStyle(by: .value("Vehicle", vName))
                        } else {
                            LineMark(x: .value("Date", log.date), y: .value("Value", yValue))
                                .interpolationMethod(.monotone)
                                .foregroundStyle(.blue)
                            
                            PointMark(x: .value("Date", log.date), y: .value("Value", yValue))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                if chartType == .efficiency, selectedVehicleId != "all" {
                    if let latestLog = validLogs.max(by: { $0.date < $1.date }) {
                        let dist = distance(for: latestLog)
                        let rawL100 = (latestLog.fuelVolume / dist) * 100.0
                        let latestEff = UnitConverter.convertEfficiency(lPer100km: rawL100, to: settings.efficiencyFormat)
                        
                        RuleMark(y: .value("Current", latestEff))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(.blue.opacity(0.5))
                            .annotation(position: .overlay, alignment: .trailing) {
                                Text(String(format: "%.1f", latestEff))
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.systemBackground).opacity(0.8))
                                    .cornerRadius(4)
                            }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var benchmarkCard: some View {
        let comparison = BenchmarkService.compareEfficiency(logs: filteredLogs, currentFormat: settings.efficiencyFormat)
        
        return NavigationLink(destination: CommunityInsightsView(allLogs: filteredLogs)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Community Benchmarks")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(selectedVehicleId == "all" ? "Entire Garage" : (activeVehicle?.makeModel ?? "Fleet"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Avg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", comparison.userVal))
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                    }
                    
                    Divider().frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Peer Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", comparison.peerAvg))
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(settings.efficiencyFormat)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    
                    Spacer()
                }
                
                HStack(spacing: 6) {
                    Image(systemName: comparison.isBetter ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    Text(comparison.topPercentageText)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Text("View Insights")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(comparison.isBetter ? .green : .orange)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background((comparison.isBetter ? Color.green : Color.orange).opacity(0.12))
                .cornerRadius(8)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func distance(for log: FuelLog) -> Double {
        let vLogs = logs.filter { $0.vehicle?.id == log.vehicle?.id }.sorted { $0.odometer < $1.odometer }
        if let idx = vLogs.firstIndex(of: log), idx > 0 {
            return log.odometer - vLogs[idx - 1].odometer
        }
        return 0
    }
    
    private func logRow(for log: FuelLog) -> some View {
        let rawDist = distance(for: log)
        let displayDist = convertedDistance(rawDist)
        let displayOdo = convertedDistance(log.odometer)
        let displayVol = convertedVolume(log.fuelVolume)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: log.vehicle?.vehicleType == "truck" ? "truck.pickup.side.fill" : "car.fill")
                    Text(log.vehicle?.makeModel ?? "Unknown")
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(8)
                
                Spacer()
                
                Text(log.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cost: ").foregroundColor(.primary) + Text("$\(log.price, specifier: "%.2f")").foregroundColor(.primary)
                Text("Fuel: ").foregroundColor(.primary) + Text("\(displayVol, specifier: "%.2f") \(unitLabel)").foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text("Odo: \(displayOdo, format: .number.precision(.fractionLength(0)))").foregroundColor(.primary)
                    
                    if displayDist > 0 {
                        Text("(+\(Int(displayDist)) \(settings.distanceUnit))")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.green)
                    } else {
                        Text("(Initial Tank)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { modelContext.delete(log) } label: { Label("Delete", systemImage: "trash") }
            Button { logToEdit = log } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text("No logs found for this period.")
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private func changePeriod(by value: Int) {
        let calendar = Calendar.current
        switch viewMode {
        case .month: refDate = calendar.date(byAdding: .month, value: value, to: refDate) ?? refDate
        case .year: refDate = calendar.date(byAdding: .year, value: value, to: refDate) ?? refDate
        case .all, .recent: break
        }
    }
    
    private var periodLabel: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .recent: return "Recent (Last 4)"
        case .all: return "Lifetime Stats"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: refDate)
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: refDate)
        }
    }
    
    private var canGoForward: Bool {
        let calendar = Calendar.current
        switch viewMode {
        case .year: return calendar.component(.year, from: refDate) < calendar.component(.year, from: Date())
        case .month:
            let current = calendar.dateComponents([.year, .month], from: Date())
            let ref = calendar.dateComponents([.year, .month], from: refDate)
            return (ref.year! < current.year!) || (ref.year! == current.year! && ref.month! < current.month!)
        default: return false
        }
    }
}
