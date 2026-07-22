import SwiftUI
import SwiftData

struct CommunityInsightsView: View {
    @Environment(SettingsManager.self) private var settings
    var allLogs: [FuelLog]
    @Query var vehicles: [Vehicle]
    
    @State private var localSelectedVehicleId: String = "all"
    
    var filteredLogs: [FuelLog] {
        if localSelectedVehicleId == "all" { return allLogs }
        return allLogs.filter { $0.vehicle?.id.uuidString == localSelectedVehicleId }
    }
    
    var body: some View {
        let comparison = BenchmarkService.compareEfficiency(logs: filteredLogs, currentFormat: settings.efficiencyFormat)
        
        ScrollView {
            VStack(spacing: 24) {
                // MARK: Vehicle Switcher
                Picker("Vehicle", selection: $localSelectedVehicleId) {
                    Text("Entire Garage").tag("all")
                    ForEach(vehicles) { v in
                        Text(v.makeModel).tag(v.id.uuidString)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // MARK: Hero
                VStack(spacing: 8) {
                    Image(systemName: comparison.isBetter ? "trophy.fill" : "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 50))
                        .foregroundColor(comparison.isBetter ? .yellow : .blue)
                        .padding(.bottom, 10)
                    
                    Text("You are in the")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("\(comparison.topPercentageText) of Drivers")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    
                    Text(localSelectedVehicleId == "all" ? "Based on your composite household footprint" : "Based on fleet telemetry for this model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: Normalized Cost
                VStack(alignment: .leading, spacing: 16) {
                    Text("Normalized Spending")
                        .font(.title3.weight(.bold))
                    
                    HStack(spacing: 20) {
                        costCard(title: "Your Cost", amount: comparison.userCostPer100, isHighlight: true)
                        costCard(title: "Fleet Avg", amount: comparison.peerCostPer100, isHighlight: false)
                    }
                    
                    let savings = comparison.peerCostPer100 - comparison.userCostPer100
                    if savings > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill").foregroundColor(.green)
                            Text("You save **$\(savings, specifier: "%.2f")** per 100 distance units.")
                                .font(.subheadline)
                        }
                    } else if savings < 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.down.forward.circle.fill").foregroundColor(.orange)
                            Text("You are spending **$\(abs(savings), specifier: "%.2f")** more per 100 units than the fleet.")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // MARK: Eco-Coach (Actionable Tips)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Eco-Coach")
                        .font(.title3.weight(.bold))
                    
                    let tips = BenchmarkService.getTips(isBetter: comparison.isBetter, logs: filteredLogs)
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: comparison.isBetter ? "star.fill" : "lightbulb.fill")
                                .foregroundColor(comparison.isBetter ? .yellow : .orange)
                            Text(tip)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // MARK: Gamification Trophies
                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(.title3.weight(.bold))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(BenchmarkService.getTrophies(logs: filteredLogs)) { trophy in
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(trophy.isEarned ? trophy.color.opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: trophy.icon)
                                                .font(.title2)
                                                .foregroundColor(trophy.isEarned ? trophy.color : .gray.opacity(0.3))
                                        )
                                    Text(trophy.title)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(trophy.isEarned ? .primary : .secondary)
                                }
                                .frame(width: 90)
                                .opacity(trophy.isEarned ? 1.0 : 0.5)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func costCard(title: String, amount: Double, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundColor(isHighlight ? .primary : .secondary)
            Text("$\(amount, specifier: "%.2f")").font(.title2.weight(.bold)).foregroundColor(isHighlight ? .blue : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isHighlight ? Color.blue.opacity(0.1) : Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
