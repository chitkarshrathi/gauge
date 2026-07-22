import Foundation

// NEW: Global utility to handle on-the-fly unit math
struct UnitConverter {
    static func convertEfficiency(lPer100km: Double, to format: String) -> Double {
        guard lPer100km > 0 else { return 0 }
        switch format {
        case "km/L": return 100.0 / lPer100km
        case "US MPG": return 235.215 / lPer100km
        case "UK MPG": return 282.481 / lPer100km
        default: return lPer100km // "L/100km"
        }
    }
    
    // In L/100km, lower is better. In MPG and km/L, higher is better.
    static func isLowerBetter(for format: String) -> Bool {
        return format == "L/100km"
    }
}

struct BenchmarkService {
    // The raw baseline in L/100km
    static let communityAvgL100km: Double = 4.9
    
    static let communityPoolL100km: [Double] = [
        4.2, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 5.0,
        5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.8, 6.0,
        6.2, 6.5, 6.8, 7.1
    ]
    
    static func compareEfficiency(logs: [FuelLog], currentFormat: String) -> (userVal: Double, peerAvg: Double, topPercentageText: String, isBetter: Bool, userCostPer100: Double, peerCostPer100: Double) {
        guard !logs.isEmpty else { return (0, 0, "No data", false, 0, 0) }
        
        var totalVol: Double = 0
        var totalSpent: Double = 0
        for log in logs {
            totalVol += log.fuelVolume
            totalSpent += log.price // Normalized to base currency
        }
        
        let estimatedTotalDistance = Double(logs.count) * 520.0
        let userRawL100 = (totalVol / estimatedTotalDistance) * 100.0
        
        // Convert to user's preferred units
        let userVal = UnitConverter.convertEfficiency(lPer100km: userRawL100, to: currentFormat)
        let peerAvg = UnitConverter.convertEfficiency(lPer100km: communityAvgL100km, to: currentFormat)
        
        let isLowerBetter = UnitConverter.isLowerBetter(for: currentFormat)
        let isBetter = isLowerBetter ? (userVal <= peerAvg) : (userVal >= peerAvg)
        
        // Calculate Top X% instead of Percentile
        let sortedPool = communityPoolL100km.sorted()
        let peersBeaten = sortedPool.filter { $0 > userRawL100 }.count
        var percentile = Int((Double(peersBeaten) / Double(sortedPool.count)) * 100.0)
        percentile = max(5, min(99, percentile))
        
        let topPercent = 100 - percentile
        let percentageText = topPercent <= 50 ? "Top \(topPercent)%" : "Bottom \(100 - topPercent)%"
        
        // Normalized Cost Math (Cost per 100 units of distance)
        // Assume community pays roughly the same average price per liter as the user
        let avgPricePerLiter = totalSpent / totalVol
        let userCostPer100 = userRawL100 * avgPricePerLiter
        let peerCostPer100 = communityAvgL100km * avgPricePerLiter
        
        return (userVal, peerAvg, percentageText, isBetter, userCostPer100, peerCostPer100)
    }
}
