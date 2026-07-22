import Foundation
import SwiftData

struct MockDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Vehicle>()
        guard let existingVehicles = try? modelContext.fetch(descriptor), existingVehicles.isEmpty else { return }
        
        print("🌱 Seeding multi-vehicle benchmarking garage...")
        
        // 1. Create two vehicles
        let hybridCar = Vehicle(makeModel: "2023 Honda Civic Hybrid", colorHex: "#007AFF", vehicleType: "hybrid")
        let truck = Vehicle(makeModel: "2021 Ford F-150", colorHex: "#FF3B30", vehicleType: "gas")
        
        modelContext.insert(hybridCar)
        modelContext.insert(truck)
        
        let calendar = Calendar.current
        let now = Date()
        
        // 2. Honda Civic Logs (Intentionally slightly bad efficiency to trigger coaching)
        var civicOdo = 15000.0
        let civicFills = [
            (days: 90, vol: 40.0, price: 60.0), (days: 75, vol: 42.0, price: 64.0),
            (days: 60, vol: 39.0, price: 58.0), (days: 45, vol: 44.0, price: 66.0),
            (days: 30, vol: 41.0, price: 62.0), (days: 15, vol: 43.0, price: 65.0),
            (days: 2, vol: 40.0, price: 60.0)
        ]
        
        for fill in civicFills {
            civicOdo += Double.random(in: 500...600) // Lower distance per tank = worse L/100km
            let log = FuelLog(odometer: civicOdo, fuelVolume: fill.vol, price: fill.price, localCurrency: "CAD", localPrice: fill.price, exchangeRate: 1.0, fuelType: "Regular", date: calendar.date(byAdding: .day, value: -fill.days, to: now) ?? now, isFullTank: true, drivingContext: "city")
            log.vehicle = hybridCar
            modelContext.insert(log)
        }
        
        // 3. Ford F-150 Logs
        var truckOdo = 45000.0
        let truckFills = [
            (days: 80, vol: 90.0, price: 135.0), (days: 50, vol: 95.0, price: 142.0),
            (days: 20, vol: 92.0, price: 138.0), (days: 5, vol: 88.0, price: 132.0)
        ]
        
        for fill in truckFills {
            truckOdo += Double.random(in: 600...750)
            let log = FuelLog(odometer: truckOdo, fuelVolume: fill.vol, price: fill.price, localCurrency: "CAD", localPrice: fill.price, exchangeRate: 1.0, fuelType: "Regular", date: calendar.date(byAdding: .day, value: -fill.days, to: now) ?? now, isFullTank: true, drivingContext: "towing")
            log.vehicle = truck
            modelContext.insert(log)
        }
        
        try? modelContext.save()
    }
}
