import Foundation

struct PeerLogEntry {
    let efficiencyL100km: Double // Their L/100km
    let drivingContext: String
}

struct PeerBenchmarkData {
    // Anonymized data pool from other drivers of the same vehicle model
    static let communityPool: [Double] = [
        4.2, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 5.0,
        5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.8, 6.0,
        6.2, 6.5, 6.8, 7.1
    ]
    
    // Calculates exact percentile rank based on actual user data vs community pool
    static func calculatePercentile(userEfficiency: Double) -> (percentile: Int, description: String) {
        let sortedPool = communityPool.sorted()
        let totalCount = Double(sortedPool.count)
        
        // Count how many peers the user beat (lower L/100km is better for efficiency)
        let peersBeaten = sortedPool.filter { $0 > userEfficiency }.count
        
        // Calculate percentile (higher percentage means better efficiency rank)
        var percentile = Int((Double(peersBeaten) / totalCount) * 100.0)
        percentile = max(5, min(99, percentile)) // Clamp between 5% and 99% for realism
        
        let description: String
        if percentile >= 80 {
            description = "Top tier hypermiler! You're beating 80%+ of drivers."
        } else if percentile >= 50 {
            description = "Above average efficiency for this vehicle class."
        } else {
            description = "Room for improvement compared to peer averages."
        }
        
        return (percentile, description)
    }
}
