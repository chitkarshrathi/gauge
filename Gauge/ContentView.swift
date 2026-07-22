import SwiftUI
import SwiftData
import Charts

enum ViewMode: String, CaseIterable {
    case week = "Week", month = "Month", year = "Year", all = "All"
}

enum ChartType {
    case efficiency, price
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsManager.self) private var settings
    
    @Query(sort: \Vehicle.makeModel) private var vehicles: [Vehicle]
    @Query(sort: \FuelLog.date, order: .reverse) private var logs: [FuelLog]
    
    @State private var viewMode: ViewMode = .all
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
        if viewMode != .all {
            result = result.filter { log in
                switch viewMode {
                case .year: return calendar.isDate(log.date, equalTo: refDate, toGranularity: .year)
                case .month: return calendar.isDate(log.date, equalTo: refDate, toGranularity: .month)
                case .week: return calendar.isDate(log.date, equalTo: refDate, toGranularity: .weekOfYear)
                case .all: return true
                }
            }
        }
        return result
    }
    
    var recentLogs: [FuelLog] { Array(filteredLogs.prefix(5)) }
    
    var displaySpent: Double { filteredLogs.reduce(0) { $0 + $1.price } }
    var totalVolume: Double { filteredLogs.reduce(0) { $0 + $1.fuelVolume } }
    var avgPricePerUnit: Double { totalVolume > 0 ? displaySpent / totalVolume : 0 }
    
    var displayEfficiency: Double {
        var totalDistance: Double = 0
        let grouped = Dictionary(grouping: filteredLogs, by: { $0.vehicle?.id })
        for (_, vLogs) in grouped {
            let sorted = vLogs.sorted { $0.odometer < $1.odometer }
            if sorted.count > 1, let first = sorted.first, let last = sorted.last {
                totalDistance += (last.odometer - first.odometer)
            }
        }
        return totalVolume > 0 && totalDistance > 0 ? totalDistance / totalVolume : 0
    }
    
    var efficiencyLabel: String { settings.efficiencyFormat }
    var unitLabel: String { settings.volumeUnit }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
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
                    .padding(.bottom, 110) // Clearance for the global tab bar
                }
            }
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
            // Garage Selector Menu
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
            
            // PLUS BUTTON MOVED TO TOP RIGHT WITH LIQUID GLASS STYLE
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
                    .foregroundColor(viewMode == .all ? .clear : .blue)
            }
            .disabled(viewMode == .all)
            
            Spacer()
            Text(periodLabel)
                .font(.headline)
            Spacer()
            
            Button(action: { changePeriod(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.bold))
                    .foregroundColor((viewMode == .all || !canGoForward) ? .clear : .blue)
            }
            .disabled(viewMode == .all || !canGoForward)
        }
        .padding(.horizontal, 24)
    }
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Spent: $\(displaySpent, specifier: "%.2f")")
            Text("Avg Price: $\(avgPricePerUnit, specifier: "%.2f")/\(unitLabel)")
            Text("Avg Efficiency: \(displayEfficiency, specifier: "%.2f") \(efficiencyLabel)")
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
                let sortedLogs = filteredLogs.sorted { $0.date < $1.date }
                
                ForEach(Array(sortedLogs.enumerated()), id: \.element.id) { index, log in
                    let yValue: Double = {
                        if chartType == .price {
                            return log.fuelVolume > 0 ? (log.price / log.fuelVolume) : 0
                        } else {
                            if index > 0 {
                                let prevLog = sortedLogs[index - 1]
                                let distanceDelta = log.odometer - prevLog.odometer
                                return (log.fuelVolume > 0 && distanceDelta > 0) ? (distanceDelta / log.fuelVolume) : 0
                            }
                            return 0
                        }
                    }()
                    
                    if yValue > 0 {
                        LineMark(x: .value("Date", log.date), y: .value("Value", yValue))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(.blue)
                        
                        PointMark(x: .value("Date", log.date), y: .value("Value", yValue))
                            .foregroundStyle(.blue)
                    }
                }
                
                // NEW: Subtle Community Baseline
                if chartType == .efficiency {
                    let peerAvgRaw = BenchmarkService.communityAvgL100km
                    let peerAvgConverted = UnitConverter.convertEfficiency(lPer100km: peerAvgRaw, to: settings.efficiencyFormat)
                    
                    RuleMark(y: .value("Peer Average", peerAvgConverted))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(.gray.opacity(0.6))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Fleet Avg")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.gray)
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
        
        return NavigationLink(destination: CommunityInsightsView(logs: filteredLogs)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Community Benchmarks")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Civic Hybrid Fleet")
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
        .buttonStyle(PlainButtonStyle()) // Prevents the whole card from highlighting weirdly
    }
    
    private func logRow(for log: FuelLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Odo: \(log.odometer, specifier: "%.0f") | Cost: $\(log.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            HStack(spacing: 10) {
                // EXPLICIT EDIT BUTTON
                Button(action: { logToEdit = log }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // ICON DELETE BUTTON
                Button(role: .destructive, action: { modelContext.delete(log) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
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
        case .week: refDate = calendar.date(byAdding: .weekOfYear, value: value, to: refDate) ?? refDate
        case .month: refDate = calendar.date(byAdding: .month, value: value, to: refDate) ?? refDate
        case .year: refDate = calendar.date(byAdding: .year, value: value, to: refDate) ?? refDate
        case .all: break
        }
    }
    
    private var periodLabel: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .all: return "Lifetime Stats"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: refDate)
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: refDate)
        case .week:
            let calendar = Calendar.current
            let start = calendar.dateInterval(of: .weekOfYear, for: refDate)?.start ?? refDate
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? refDate
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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
