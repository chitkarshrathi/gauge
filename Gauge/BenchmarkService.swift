import Foundation
import SwiftUI // Needed for Color in Trophies

struct UnitConverter {
    static func convertEfficiency(lPer100km: Double, to format: String) -> Double {
        guard lPer100km > 0 else { return 0 }
        switch format {
        case "km/L": return 100.0 / lPer100km
        case "US MPG": return 235.215 / lPer100km
        case "UK MPG": return 282.481 / lPer100km
        default: return lPer100km
        }
    }
    static func isLowerBetter(for format: String) -> Bool { return format == "L/100km" }
}

struct Trophy: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isEarned: Bool
}

struct BenchmarkService {
    // Peer DB
    static func getPeerAvgL100km(for model: String) -> Double {
            let normalized = model.lowercased()
            if normalized.contains("f-150") || normalized.contains("f150") || normalized.contains("truck") {
                return 11.5 // Average L/100km for a full-size truck
            }
            return 4.9 // Default Hybrid baseline
        }
    
    // Core Engine
    static func compareEfficiency(logs: [FuelLog], currentFormat: String) -> (userVal: Double, peerAvg: Double, topPercentageText: String, isBetter: Bool, userCostPer100: Double, peerCostPer100: Double) {
        guard !logs.isEmpty else { return (0, 0, "No data", false, 0, 0) }
        
        var totalVol: Double = 0
        var totalSpent: Double = 0
        var compositeBaselineWeighted: Double = 0
        var validDistance: Double = 0
        
        let grouped = Dictionary(grouping: logs, by: { $0.vehicle?.id })
        
        for (_, vLogs) in grouped {
            let sorted = vLogs.sorted { $0.odometer < $1.odometer }
            if sorted.count > 1, let first = sorted.first, let last = sorted.last, let vehicle = first.vehicle {
                let dist = last.odometer - first.odometer
                let vVol = sorted.reduce(0) { $0 + $1.fuelVolume }
                
                validDistance += dist
                totalVol += vVol
                totalSpent += sorted.reduce(0) { $0 + $1.price }
                
                // Weight the baseline by this vehicle's share of the volume
                let vBaseline = getPeerAvgL100km(for: vehicle.makeModel)
                compositeBaselineWeighted += (vBaseline * vVol)
            }
        }
        
        guard validDistance > 0, totalVol > 0 else { return (0, 0, "No data", false, 0, 0) }
        
        let userRawL100 = (totalVol / validDistance) * 100.0
        let compositePeerL100 = compositeBaselineWeighted / totalVol
        
        let userVal = UnitConverter.convertEfficiency(lPer100km: userRawL100, to: currentFormat)
        let peerAvg = UnitConverter.convertEfficiency(lPer100km: compositePeerL100, to: currentFormat)
        
        let isLowerBetter = UnitConverter.isLowerBetter(for: currentFormat)
        let isBetter = isLowerBetter ? (userVal <= peerAvg) : (userVal >= peerAvg)
        
        // Mock percentile logic based on gap
        let differencePercent = abs(userRawL100 - compositePeerL100) / compositePeerL100
        var percentile = isBetter ? 50 + Int(differencePercent * 150) : 50 - Int(differencePercent * 150)
        percentile = max(5, min(95, percentile))
        
        let topPercent = 100 - percentile
        let percentageText = topPercent <= 50 ? "Top \(topPercent)%" : "Bottom \(100 - topPercent)%"
        
        let avgPricePerLiter = totalSpent / totalVol
        let userCostPer100 = userRawL100 * avgPricePerLiter
        let peerCostPer100 = compositePeerL100 * avgPricePerLiter
        
        return (userVal, peerAvg, percentageText, isBetter, userCostPer100, peerCostPer100)
    }
    
    // Gamification
    static func getTrophies(logs: [FuelLog]) -> [Trophy] {
        let stats = compareEfficiency(logs: logs, currentFormat: "L/100km") // Format doesn't matter for raw bool
        return [
            Trophy(title: "Data Pioneer", description: "Log your first 5 fill-ups.", icon: "flag.checkered.2.crossed", color: .purple, isEarned: logs.count >= 5),
            Trophy(title: "Hypermiler", description: "Beat the community average.", icon: "leaf.fill", color: .green, isEarned: stats.isBetter),
            Trophy(title: "Smooth Operator", description: "Maintain top 20% efficiency.", icon: "wind", color: .blue, isEarned: stats.topPercentageText.contains("Top 20") || stats.topPercentageText.contains("Top 10"))
        ]
    }
    
    // Eco-Coach
    static func getTips(isBetter: Bool, logs: [FuelLog]) -> [String] {
        if isBetter {
            return ["You're outperforming the fleet! Keep your tire pressure checked to maintain this hypermiler status."]
        } else {
            return [
                "Your consumption is tracking higher than average. If you're doing short city trips, try coasting to red lights—hybrids recapture up to 30% of energy this way.",
                "Ensure your tires are inflated to the factory spec. A 10% drop in pressure reduces fuel economy by 2%."
            ]
        }
    }
}
