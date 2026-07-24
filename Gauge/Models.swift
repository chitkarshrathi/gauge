import Foundation
import SwiftData

// MARK: - 1. Household & Family Schema
@Model
final class Household {
    @Attribute(.unique) var id: UUID
    var name: String
    var subscriptionTier: String // "free", "individual_pro", "family_pro"
    var monthlyBudget: Double
    
    @Relationship(deleteRule: .cascade, inverse: \FamilyMember.household)
    var members: [FamilyMember] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Vehicle.household)
    var vehicles: [Vehicle] = []
    
    @Relationship(deleteRule: .cascade, inverse: \TripPod.household)
    var tripPods: [TripPod] = []

    init(id: UUID = UUID(), name: String, subscriptionTier: String = "family_pro", monthlyBudget: Double = 400.0) {
        self.id = id
        self.name = name
        self.subscriptionTier = subscriptionTier
        self.monthlyBudget = monthlyBudget
    }
}

@Model
final class FamilyMember {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var role: String // "admin", "member"
    var avatarSymbol: String
    
    var household: Household?
    
    @Relationship(inverse: \FuelLog.payer)
    var paidLogs: [FuelLog] = []

    init(id: UUID = UUID(), name: String, email: String, role: String = "member", avatarSymbol: String = "person.fill") {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.avatarSymbol = avatarSymbol
    }
}

// MARK: - 2. Core Vehicle Schema
@Model
final class Vehicle {
    @Attribute(.unique) var id: UUID
    var makeModel: String
    var vehicleClass: String // "sedan", "suv", "truck"
    var year: Int
    var licensePlate: String
    var isAWD: Bool
    
    var household: Household?
    
    @Relationship(deleteRule: .cascade, inverse: \FuelLog.vehicle)
    var logs: [FuelLog] = []
    
    @Relationship(inverse: \TripPod.vehicle)
    var activeTrips: [TripPod] = []

    init(id: UUID = UUID(), makeModel: String, vehicleClass: String, year: Int, licensePlate: String, isAWD: Bool = false) {
        self.id = id
        self.makeModel = makeModel
        self.vehicleClass = vehicleClass
        self.year = year
        self.licensePlate = licensePlate
        self.isAWD = isAWD
    }
}

// MARK: - 3. Fuel Log Schema (Algorithm & Cross-Fill Ready)
@Model
final class FuelLog {
    @Attribute(.unique) var id: UUID
    var odometer: Double
    var fuelVolume: Double
    var price: Double         // Converted base currency price
    var localCurrency: String
    var localPrice: Double
    var exchangeRate: Double
    var fuelType: String
    var date: Date
    var isFullTank: Bool
    var drivingContext: String
    var ambientTempCelsius: Double
    
    // Scalable Relationships
    var vehicle: Vehicle?
    var payer: FamilyMember?   // Solves the "who paid when borrowing a car" dilemma
    var tripPod: TripPod?

    init(
        id: UUID = UUID(),
        odometer: Double,
        fuelVolume: Double,
        price: Double,
        localCurrency: String,
        localPrice: Double,
        exchangeRate: Double = 1.0,
        fuelType: String = "Regular",
        date: Date = Date(),
        isFullTank: Bool = true,
        drivingContext: String = "mixed",
        ambientTempCelsius: Double = 20.0
    ) {
        self.id = id
        self.odometer = odometer
        self.fuelVolume = fuelVolume
        self.price = price
        self.localCurrency = localCurrency
        self.localPrice = localPrice
        self.exchangeRate = exchangeRate
        self.fuelType = fuelType
        self.date = date
        self.isFullTank = isFullTank
        self.drivingContext = drivingContext
        self.ambientTempCelsius = ambientTempCelsius
    }
}

// MARK: - 4. Trip Pod Schema
@Model
final class TripPod {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    
    var household: Household?
    var vehicle: Vehicle?
    
    @Relationship(deleteRule: .cascade, inverse: \FuelLog.tripPod)
    var tripLogs: [FuelLog] = []

    init(id: UUID = UUID(), name: String, startDate: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.isActive = isActive
    }
}
