import SwiftUI

struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Setup
                Section {
                    ProfileHeaderView()
                    
                    @Bindable var bindableSettings = settings
                    
                    Picker(selection: $bindableSettings.country) {
                        Text("Canada").tag("Canada")
                        Text("United States").tag("United States")
                        Text("United Kingdom").tag("United Kingdom")
                        Text("India").tag("India")
                        Text("Rest of World").tag("ROW")
                    } label: {
                        Label("Region", systemImage: "globe.americas.fill")
                    }
                    
                    HStack {
                        Label("Postal / ZIP Code", systemImage: "number.square.fill")
                        Spacer()
                        TextField("e.g. T6G 2R3", text: $bindableSettings.zipCode)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                            .submitLabel(.done)
                    }
                    
                    DatePicker(selection: Binding(
                        get: { settings.dateOfBirth ?? Date() },
                        set: { settings.dateOfBirth = $0 }
                    ), displayedComponents: [.date]) {
                        Label("Date of Birth", systemImage: "calendar")
                    }
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Your ZIP code and age bracket power localized community benchmarking. Data remains strictly on-device.")
                }
                
                // MARK: - Subscriptions
                Section {
                    NavigationLink(destination: Text("Gauge Pro Active")) {
                        Label("Gauge Pro", systemImage: "star.fill")
                            .symbolRenderingMode(.multicolor)
                            .badge("Active")
                    }
                    NavigationLink(destination: FamilySettingsView()) {
                        Label("Family Garage", systemImage: "person.2.fill")
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: Text("Trip Pods")) {
                        Label("Road Trip Pods", systemImage: "map.fill")
                            .foregroundColor(.green)
                    }
                    NavigationLink(destination: Text("Payment Methods")) {
                        Label("Payment Methods", systemImage: "creditcard.fill")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("Account & Subscriptions")
                }
                
                // MARK: - Community Gamification
                Section {
                    NavigationLink(destination: Text("Community Benchmarks")) {
                        Label("Benchmarks", systemImage: "chart.bar.xaxis")
                            .foregroundColor(.indigo)
                    }
                    NavigationLink(destination: Text("Medals Hub")) {
                        Label("Medals", systemImage: "trophy.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                } header: {
                    Text("Community Stats")
                }
                
                // MARK: - Preferences
                Section {
                    @Bindable var bindableSettings = settings
                    
                    Picker(selection: $bindableSettings.themePreference) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    
                    Picker(selection: $bindableSettings.distanceUnit) {
                        Text("Kilometers (km)").tag("km")
                        Text("Miles (mi)").tag("mi")
                    } label: {
                        Label("Distance", systemImage: "ruler.fill")
                    }
                    
                    Picker(selection: $bindableSettings.volumeUnit) {
                        Text("Liters (L)").tag("Liters")
                        Text("US Gallons").tag("US Gallons")
                        Text("UK Gallons").tag("UK Gallons")
                    } label: {
                        Label("Volume", systemImage: "drop.fill")
                    }
                    
                    Picker(selection: $bindableSettings.efficiencyFormat) {
                        Text("L/100km").tag("L/100km")
                        Text("km/L").tag("km/L")
                        Text("US MPG").tag("US MPG")
                        Text("UK MPG").tag("UK MPG")
                    } label: {
                        Label("Efficiency", systemImage: "leaf.fill")
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Changing your Region automatically updates global units, but you can override them here.")
                }
                
                // MARK: - Reports Hub
                Section {
                    NavigationLink(destination: ReportsHubView()) {
                        Label("Reports Hub", systemImage: "doc.text.fill")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Reporting")
                }
                
                // MARK: - Migration
                Section {
                    Button(action: { /* Trigger CSV Import */ }) {
                        Label("Import Legacy Data (CSV)", systemImage: "arrow.down.doc.fill")
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Migration")
                }
                
                // MARK: - Footer
                Section {
                    EmptyView()
                } footer: {
                    VStack(spacing: 4) {
                        Text("Built proudly in Alberta, Canada for the world.")
                            .font(.caption)
                        Text("Version 1.0 (Hackathon Build)")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Subcomponents

/// Extracts the complex profile header to keep the main List clean.
private struct ProfileHeaderView: View {
    var body: some View {
        NavigationLink(destination: Text("Edit Profile")) {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.accentColor.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chitkarsh Rathi")
                        .font(.title3.weight(.bold))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text("Founders Club • User #0")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(4)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// The dedicated hub for all data exports, preventing main-menu clutter.
private struct ReportsHubView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: Text("Seller's Report Engine")) {
                    ReportRowView(
                        title: "Seller’s Report",
                        description: "Verified maintenance and fueling history to prove vehicle care to buyers."
                    )
                }
                
                NavigationLink(destination: Text("Custom Report Engine")) {
                    ReportRowView(
                        title: "Custom Report",
                        description: "Build custom date ranges and export tailored vehicle spreadsheets."
                    )
                }
                
                NavigationLink(destination: Text("Total Cost of Ownership")) {
                    ReportRowView(
                        title: "Cost of Ownership",
                        description: "Comprehensive total lifecycle cost analysis including fuel, maintenance, and depreciation."
                    )
                }
                
                NavigationLink(destination: Text("Annual Tax Summary")) {
                    ReportRowView(
                        title: "Annual Summary",
                        description: "Tax and accounting breakdown for business mileage and vehicle expenses."
                    )
                }
            } header: {
                Text("Select Report Type")
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }
}

/// Reusable UI component for consistent report row layouts.
private struct ReportRowView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
