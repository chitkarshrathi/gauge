import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // View Router
            Group {
                switch selectedTab {
                case 0:
                    ContentView() // Your Dashboard
                case 1:
                    HistoryView() // The history screen we just made
                case 2:
                    GarageView()
                case 3:
                    SettingsView()
                default:
                    ContentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // The Floating Liquid Glass Bar
            HStack(spacing: 0) {
                tabButton(icon: "gauge.with.dots.needle.bottom.50percent", title: "Dashboard", index: 0)
                tabButton(icon: "clock.fill", title: "History", index: 1)
                tabButton(icon: "car.2.fill", title: "Garage", index: 2)
                tabButton(icon: "gearshape.fill", title: "Settings", index: 3)
            }
            .padding(.horizontal, 10)
            .frame(height: 70)
            .background(.ultraThinMaterial) // True Apple liquid glass blur
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Prevents the bar from jumping over the keyboard
    }
    
    // Tab Button Generator
    private func tabButton(icon: String, title: String, index: Int) -> some View {
        let isActive = selectedTab == index
        return Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isActive ? .bold : .regular))
                Text(title)
                    .font(.system(size: 10, weight: isActive ? .bold : .medium))
            }
            .foregroundColor(isActive ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
        .environment(SettingsManager())
}
