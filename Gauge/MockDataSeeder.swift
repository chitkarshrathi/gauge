import Foundation
import SwiftData

struct MockDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        // We now check for Households to determine if we need to seed
        let descriptor = FetchDescriptor<Household>()
        guard let existingHouseholds = try? modelContext.fetch(descriptor), existingHouseholds.isEmpty else { return }
        
        print("🌱 Seeding multi-user Rathi family garage...")
        
        // 1. Create the Household
        let household = Household(name: "Rathi Family", subscriptionTier: "family_pro", monthlyBudget: 500.0)
        modelContext.insert(household)
        
        // 2. Create Family Members
        let chitkarsh = FamilyMember(name: "Chitkarsh", email: "chitkarsh@example.com", role: "admin", avatarSymbol: "person.crop.circle.fill")
        let smriti = FamilyMember(name: "Smriti", email: "smriti@example.com", role: "member", avatarSymbol: "person.crop.square.fill")
        let uncle = FamilyMember(name: "Uncle", email: "uncle@example.com", role: "member", avatarSymbol: "person.crop.artframe")
        
        // Link members to the household
        chitkarsh.household = household
        smriti.household = household
        uncle.household = household
        
        modelContext.insert(chitkarsh)
        modelContext.insert(smriti)
        modelContext.insert(uncle)
        
        let calendar = Calendar.current
        let now = Date()
        
        // 3. Create Vehicles & Link to Household
        let hybridCar = Vehicle(
            makeModel: "2023 Honda Civic Hybrid",
            vehicleClass: "sedan",
            year: 2023,
            licensePlate: "RATHI-1",
            isAWD: false
        )
        let truck = Vehicle(
            makeModel: "2021 Ford F-150",
            vehicleClass: "truck",
            year: 2021,
            licensePlate: "RATHI-2",
            isAWD: true
        )
        
        hybridCar.household = household
        truck.household = household
        
        modelContext.insert(hybridCar)
        modelContext.insert(truck)
        
        // 4. Honda Civic Logs (Paid mostly by Chitkarsh)
        var civicOdo = 15000.0
        let civicFills = [
            (days: 90, vol: 40.0, price: 60.0), (days: 75, vol: 42.0, price: 64.0),
            (days: 60, vol: 39.0, price: 58.0), (days: 45, vol: 44.0, price: 66.0),
            (days: 30, vol: 41.0, price: 62.0), (days: 15, vol: 43.0, price: 65.0),
            (days: 2, vol: 40.0, price: 60.0)
        ]
        
        for fill in civicFills {
            civicOdo += Double.random(in: 500...600)
            let log = FuelLog(
                odometer: civicOdo, fuelVolume: fill.vol, price: fill.price,
                localCurrency: "CAD", localPrice: fill.price, exchangeRate: 1.0,
                fuelType: "Regular", date: calendar.date(byAdding: .day, value: -fill.days, to: now) ?? now,
                isFullTank: true, drivingContext: "city"
            )
            log.vehicle = hybridCar
            log.payer = chitkarsh // Cross-linking the payer
            modelContext.insert(log)
        }
        
        // 5. Ford F-150 Logs (Paid mostly by Smriti)
        var truckOdo = 45000.0
        let truckFills = [
            (days: 80, vol: 90.0, price: 135.0), (days: 50, vol: 95.0, price: 142.0),
            (days: 20, vol: 92.0, price: 138.0), (days: 5, vol: 88.0, price: 132.0)
        ]
        
        for fill in truckFills {
            truckOdo += Double.random(in: 600...750)
            let log = FuelLog(
                odometer: truckOdo, fuelVolume: fill.vol, price: fill.price,
                localCurrency: "CAD", localPrice: fill.price, exchangeRate: 1.0,
                fuelType: "Regular", date: calendar.date(byAdding: .day, value: -fill.days, to: now) ?? now,
                isFullTank: true, drivingContext: "towing"
            )
            log.vehicle = truck
            log.payer = smriti // Cross-linking the payer
            modelContext.insert(log)
        }
        
        try? modelContext.save()
    }
}
