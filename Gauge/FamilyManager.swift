import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
class FamilyManager {
    // Controls the dual-dashboard state globally
    var isHouseholdModeActive: Bool = false
    
    // MARK: - Financial Aggregation
    
    /// Calculates the total amount spent by the household in the current calendar month
    func calculateMonthlyHouseholdSpend(for household: Household) -> Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let allLogs = household.vehicles.flatMap { $0.logs }
        
        let thisMonthLogs = allLogs.filter { log in
            let logMonth = Calendar.current.component(.month, from: log.date)
            let logYear = Calendar.current.component(.year, from: log.date)
            return logMonth == currentMonth && logYear == currentYear
        }
        
        return thisMonthLogs.reduce(0) { $0 + $1.price }
    }
    
    /// Returns a percentage (0.0 to 1.0) of how much of the budget is consumed
    func budgetProgress(for household: Household) -> Double {
        guard household.monthlyBudget > 0 else { return 0 }
        let spent = calculateMonthlyHouseholdSpend(for: household)
        return min(spent / household.monthlyBudget, 1.0)
    }
    
    // MARK: - Cross-Vehicle Utilities
    
    /// Generates a mock invite link for local testing
    func generateInviteLink(for household: Household) -> String {
        return "https://api.gaugeapp.com/invite/\(household.id.uuidString)"
    }
}
