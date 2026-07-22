//
//  MockDataSeeder.swift
//  Gauge
//
//  Created by Chitkarsh Rathi on 7/22/26.
//


import Foundation
import SwiftData

struct MockDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        // Check if we already seeded data so we don't duplicate on every relaunch
        let descriptor = FetchDescriptor<Vehicle>()
        guard let existingVehicles = try? modelContext.fetch(descriptor), existingVehicles.isEmpty else {
            return
        }
        
        print("🌱 Seeding mock benchmarking data for Gauge...")
        
        // 1. Create a primary test vehicle
        let myCar = Vehicle(
            makeModel: "2023 Honda Civic Hybrid",
            colorHex: "#007AFF",
            vehicleType: "hybrid"
        )
        modelContext.insert(myCar)
        
        // 2. Generate a realistic timeline of logs over the last 6 months
        let calendar = Calendar.current
        let now = Date()
        
        // Starting odometer
        var currentOdometer = 15000.0
        
        // A series of realistic fill-ups
        struct SeedEntry {
            let daysAgo: Int
            let gallons: Double
            let pricePaid: Double
            let isUSD: Bool
            let context: String
            let fuelType: String
        }
        
        let mockEntries = [
            SeedEntry(daysAgo: 180, gallons: 11.2, pricePaid: 58.00, isUSD: false, context: "city", fuelType: "Regular"),
            SeedEntry(daysAgo: 165, gallons: 10.5, pricePaid: 54.20, isUSD: false, context: "commute", fuelType: "Regular"),
            SeedEntry(daysAgo: 150, gallons: 12.0, pricePaid: 63.50, isUSD: false, context: "highway", fuelType: "Regular"),
            SeedEntry(daysAgo: 135, gallons: 11.8, pricePaid: 61.00, isUSD: false, context: "city", fuelType: "Regular"),
            SeedEntry(daysAgo: 120, gallons: 10.1, pricePaid: 52.00, isUSD: false, context: "commute", fuelType: "Regular"),
            // US Road Trip to Montana! (Testing the currency & travel feature)
            SeedEntry(daysAgo: 105, gallons: 13.5, pricePaid: 48.50, isUSD: true, context: "mountain", fuelType: "Regular"),
            SeedEntry(daysAgo: 104, gallons: 11.0, pricePaid: 41.00, isUSD: true, context: "highway", fuelType: "Regular"),
            // Back home in Canada
            SeedEntry(daysAgo: 90, gallons: 11.5, pricePaid: 59.80, isUSD: false, context: "commute", fuelType: "Regular"),
            SeedEntry(daysAgo: 75, gallons: 12.2, pricePaid: 63.00, isUSD: false, context: "city", fuelType: "Regular"),
            SeedEntry(daysAgo: 60, gallons: 10.8, pricePaid: 55.60, isUSD: false, context: "highway", fuelType: "Regular"),
            SeedEntry(daysAgo: 45, gallons: 11.4, pricePaid: 58.90, isUSD: false, context: "commute", fuelType: "Regular"),
            SeedEntry(daysAgo: 30, gallons: 12.1, pricePaid: 62.40, isUSD: false, context: "mountain", fuelType: "Regular"),
            SeedEntry(daysAgo: 15, gallons: 10.9, pricePaid: 56.10, isUSD: false, context: "city", fuelType: "Regular"),
            SeedEntry(daysAgo: 2, gallons: 11.3, pricePaid: 58.20, isUSD: false, context: "commute", fuelType: "Regular")
        ]
        
        for entry in mockEntries {
            guard let logDate = calendar.date(byAdding: .day, value: -entry.daysAgo, to: now) else { continue }
            
            // Add between 450 to 650 km equivalent per fill-up
            currentOdometer += Double.random(in: 450...650)
            
            let basePrice: Double
            let localCurr: String
            let exchangeRate: Double
            
            if entry.isUSD {
                exchangeRate = 1.37 // Mock exchange rate CAD/USD
                basePrice = entry.pricePaid * exchangeRate
                localCurr = "USD"
            } else {
                exchangeRate = 1.0
                basePrice = entry.pricePaid
                localCurr = "CAD"
            }
            
            let log = FuelLog(
                odometer: currentOdometer,
                fuelVolume: entry.gallons,
                price: basePrice,
                localCurrency: localCurr,
                localPrice: entry.pricePaid,
                exchangeRate: exchangeRate,
                fuelType: entry.fuelType,
                date: logDate,
                isFullTank: true,
                drivingContext: entry.context
            )
            
            log.vehicle = myCar
            modelContext.insert(log)
        }
        
        try? modelContext.save()
        print("✅ Mock data successfully seeded!")
    }
}
