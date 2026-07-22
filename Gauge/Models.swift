import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID
    var makeModel: String
    var colorHex: String
    var imageUri: String?
    var vehicleType: String
    
    @Relationship(deleteRule: .cascade, inverse: \FuelLog.vehicle)
    var logs: [FuelLog] = []
    
    init(makeModel: String, colorHex: String, imageUri: String? = nil, vehicleType: String = "gas") {
        self.id = UUID()
        self.makeModel = makeModel
        self.colorHex = colorHex
        self.imageUri = imageUri
        self.vehicleType = vehicleType
    }
}

@Model
final class FuelLog {
    var id: UUID
    var odometer: Double
    var fuelVolume: Double
    
    // The Base Currency (e.g. CAD) used for all Dashboard charts
    var price: Double
    
    // Travel Context (e.g. The exact USD amount on the receipt)
    var localCurrency: String
    var localPrice: Double
    var exchangeRate: Double
    
    var fuelType: String
    var date: Date
    var isFullTank: Bool
    var drivingContext: String
    var vehicle: Vehicle?
    
    init(odometer: Double, fuelVolume: Double, price: Double, localCurrency: String, localPrice: Double, exchangeRate: Double, fuelType: String, date: Date = Date(), isFullTank: Bool = true, drivingContext: String = "mixed") {
        self.id = UUID()
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
    }
}
