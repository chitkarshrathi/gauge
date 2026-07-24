import SwiftUI
import SwiftData

@main
struct GaugeApp: App {
    @State private var settings = SettingsManager()
    @State private var familyManager = FamilyManager() // 1. Instantiate the new manager
    
    var sharedModelContainer: ModelContainer = {
        // 2. Add the new multi-user models to the schema
        let schema = Schema([
            Household.self,
            FamilyMember.self,
            Vehicle.self,
            FuelLog.self,
            TripPod.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(settings)
                .environment(familyManager) // 3. Inject it into the view hierarchy
                .preferredColorScheme(settings.colorScheme)
                .onAppear {
                    // Seed mock benchmarking data on first launch
                    MockDataSeeder.seedIfNeeded(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
