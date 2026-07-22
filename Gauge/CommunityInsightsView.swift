//
//  CommunityInsightsView.swift
//  Gauge
//
//  Created by Chitkarsh Rathi on 7/22/26.
//


import SwiftUI
import SwiftData
import Charts

struct CommunityInsightsView: View {
    @Environment(SettingsManager.self) private var settings
    var logs: [FuelLog]
    
    var body: some View {
        let comparison = BenchmarkService.compareEfficiency(logs: logs, currentFormat: settings.efficiencyFormat)
        let isLowerBetter = UnitConverter.isLowerBetter(for: settings.efficiencyFormat)
        
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: Hero Graphic
                VStack(spacing: 8) {
                    Image(systemName: comparison.isBetter ? "trophy.fill" : "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 50))
                        .foregroundColor(comparison.isBetter ? .yellow : .blue)
                        .padding(.bottom, 10)
                    
                    Text("You are in the")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("\(comparison.topPercentageText) of Drivers")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Based on local telemetry for Honda Civic Hybrids")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // MARK: Fair Cost Comparison (Apple-like insight)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Normalized Spending")
                        .font(.title3.weight(.bold))
                    
                    Text("Total monthly fuel costs depend on how far you drive. To make a fair comparison, we look at what it costs you to drive 100 \(settings.distanceUnit)s compared to the community.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        costCard(title: "Your Cost", amount: comparison.userCostPer100, isHighlight: true)
                        costCard(title: "Fleet Avg", amount: comparison.peerCostPer100, isHighlight: false)
                    }
                    
                    let savings = comparison.peerCostPer100 - comparison.userCostPer100
                    if savings > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill").foregroundColor(.green)
                            Text("You save **$\(savings, specifier: "%.2f")** per 100 \(settings.distanceUnit)s compared to average.")
                                .font(.subheadline)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // MARK: Contextual Insight (Differentiator)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why are you scoring here?")
                        .font(.title3.weight(.bold))
                    
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        Text("Your hybrid engine excels in **stop-and-go city driving** due to regenerative braking. Our data shows 60% of your logs are tagged as 'City' or 'Commute', keeping your consumption significantly below the highway-heavy fleet average.")
                            .font(.subheadline)
                            .lineSpacing(4)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
            }
            .padding(.horizontal)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Community Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func costCard(title: String, amount: Double, isHighlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isHighlight ? .primary : .secondary)
            Text("$\(amount, specifier: "%.2f")")
                .font(.title2.weight(.bold))
                .foregroundColor(isHighlight ? .blue : .primary)
            Text("per 100 \(settings.distanceUnit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isHighlight ? Color.blue.opacity(0.1) : Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}