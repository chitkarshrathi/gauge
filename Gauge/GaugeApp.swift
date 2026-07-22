import SwiftUI
import SwiftData

@main
struct GaugeApp: App {
    @State private var settings = SettingsManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Vehicle.self, FuelLog.self])
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
                .preferredColorScheme(settings.colorScheme)
                .onAppear {
                    // Seed mock benchmarking data on first launch
                    MockDataSeeder.seedIfNeeded(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
