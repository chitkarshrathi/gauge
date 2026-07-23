import SwiftUI

struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile & Founders Badge
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.accentColor.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Chitkarsh Rathi")
                                .font(.title2.weight(.bold))
                            
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("Founders Club • User #0")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Account & Memberships
                Section {
                    NavigationLink(destination: Text("Gauge Pro Settings")) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 28)
                            Text("Gauge Pro")
                            Spacer()
                            Text("Active")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: Text("Family Sharing Setup")) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text("Family Garage")
                        }
                    }
                    
                    NavigationLink(destination: Text("Trip Pods Management")) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            Text("Road Trip Pods")
                            Spacer()
                            Text("Local-First")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }
                } header: {
                    Text("Account & Subscriptions")
                }
                
                // MARK: - Achievements & Benchmarks
                Section {
                    NavigationLink(destination: Text("Regional Leaderboards")) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Medals & Benchmarks")
                                Text("City, State, & Country Rankings")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("3 Unlocked")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Gamification")
                }
                
                // MARK: - Region & Units
                Section {
                    @Bindable var bindableSettings = settings
                    
                    Picker("Country / Region", selection: $bindableSettings.country) {
                        Text("Canada").tag("Canada")
                        Text("United States").tag("United States")
                        Text("United Kingdom").tag("United Kingdom")
                        Text("India").tag("India")
                        Text("Rest of World").tag("ROW")
                    }
                    
                    Picker("Distance", selection: $bindableSettings.distanceUnit) {
                        Text("Kilometers (km)").tag("km")
                        Text("Miles (mi)").tag("mi")
                    }
                    
                    Picker("Volume", selection: $bindableSettings.volumeUnit) {
                        Text("Liters (L)").tag("Liters")
                        Text("US Gallons (gal)").tag("US Gallons")
                        Text("UK Gallons (gal)").tag("UK Gallons")
                    }
                    
                    Picker("Efficiency", selection: $bindableSettings.efficiencyFormat) {
                        Text("L/100km").tag("L/100km")
                        Text("km/L").tag("km/L")
                        Text("US MPG").tag("US MPG")
                        Text("UK MPG").tag("UK MPG")
                    }
                } header: {
                    Text("Region & Units")
                } footer: {
                    Text("Your country selection helps localize your benchmark leaderboards.")
                }
                
                // MARK: - Data Control
                Section {
                    Button(action: { /* Trigger CSV Import */ }) {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            Text("Import Legacy Data (CSV)")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Migration")
                }
                
                // MARK: - Footer
                Section {
                    EmptyView()
                } footer: {
                    VStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("ASCII Automations")
                            .font(.footnote.weight(.semibold))
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
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
