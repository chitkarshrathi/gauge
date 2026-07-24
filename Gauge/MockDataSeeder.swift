import Foundation
import SwiftData

struct MockDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Household>()
        guard let existingHouseholds = try? modelContext.fetch(descriptor), existingHouseholds.isEmpty else { return }
        
        print("🌱 Seeding Chitkarsh & Smriti's Garage with 2 years of history...")
        
        // 1. Create the Household
        let household = Household(name: "The Rathi Garage", subscriptionTier: "family_pro", monthlyBudget: 500.0)
        modelContext.insert(household)
        
        // 2. Create Family Members
        let chitkarsh = FamilyMember(name: "Chitkarsh", email: "chitkarsh@example.com", role: "admin", avatarSymbol: "person.crop.circle.fill")
        let smriti = FamilyMember(name: "Smriti", email: "smriti@example.com", role: "member", avatarSymbol: "person.crop.square.fill")
        
        chitkarsh.household = household
        smriti.household = household
        modelContext.insert(chitkarsh)
        modelContext.insert(smriti)
        
        // 3. Create Vehicles
        let civic = Vehicle(makeModel: "Chitkarsh's Civic", vehicleClass: "sedan", year: 2023, licensePlate: "RATHI-1")
        let f150 = Vehicle(makeModel: "Chitkarsh's F-150", vehicleClass: "truck", year: 2021, licensePlate: "RATHI-2")
        let explorer = Vehicle(makeModel: "Smriti's Explorer", vehicleClass: "suv", year: 2022, licensePlate: "SMRITI-1")
        
        civic.household = household
        f150.household = household
        explorer.household = household
        
        modelContext.insert(civic)
        modelContext.insert(f150)
        modelContext.insert(explorer)
        
        // 4. Programmatic Data Generation (May 2024 to Present)
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: 2024, month: 5, day: 1)) else { return }
        let endDate = Date()
        
        // Generators
        generateLogs(for: civic, payer: chitkarsh, startOdo: 15000.0, startDate: startDate, endDate: endDate, intervalDays: 14, volRange: 38...42, priceRange: 55...65, modelContext: modelContext)
        generateLogs(for: f150, payer: chitkarsh, startOdo: 45000.0, startDate: startDate, endDate: endDate, intervalDays: 18, volRange: 85...95, priceRange: 130...145, modelContext: modelContext)
        generateLogs(for: explorer, payer: smriti, startOdo: 22000.0, startDate: startDate, endDate: endDate, intervalDays: 16, volRange: 60...65, priceRange: 90...100, modelContext: modelContext)
        
        try? modelContext.save()
    }
    
    // Helper to generate a realistic timeline of logs
    private static func generateLogs(for vehicle: Vehicle, payer: FamilyMember, startOdo: Double, startDate: Date, endDate: Date, intervalDays: Int, volRange: ClosedRange<Double>, priceRange: ClosedRange<Double>, modelContext: ModelContext) {
        var currentDate = startDate
        var currentOdo = startOdo
        
        while currentDate < endDate {
            let vol = Double.random(in: volRange)
            let price = Double.random(in: priceRange)
            currentOdo += Double.random(in: 400...600)
            
            let log = FuelLog(odometer: currentOdo, fuelVolume: vol, price: price, localCurrency: "CAD", localPrice: price, fuelType: "Regular", date: currentDate, isFullTank: true, drivingContext: "mixed")
            log.vehicle = vehicle
            log.payer = payer
            modelContext.insert(log)
            
            // Step forward by interval + random variance of +/- 3 days
            let daysToAdvance = intervalDays + Int.random(in: -3...3)
            currentDate = Calendar.current.date(byAdding: .day, value: daysToAdvance, to: currentDate) ?? endDate
        }
    }
}
