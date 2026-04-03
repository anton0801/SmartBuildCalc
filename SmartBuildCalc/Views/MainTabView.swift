import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)

            ProjectsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "folder.fill" : "folder")
                    Text("Projects")
                }
                .tag(1)

            CalculatorsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "function" : "plus.forwardslash.minus")
                    Text("Calculate")
                }
                .tag(2)

            ShoppingListView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "cart.fill" : "cart")
                    Text("Shopping")
                }
                .tag(3)

            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis.circle")
                    Text("More")
                }
                .tag(4)
        }
        .accentColor(.brandOrange)
    }
}

// MARK: - More View (hub for remaining sections)
struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @State private var showMaterials = false
    @State private var showMeasurements = false
    @State private var showReports = false
    @State private var showTasks = false
    @State private var showProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                List {
                    Section {
                        MoreRow(icon: "tray.2.fill", color: Color(hex: "#3498DB"), title: "Materials", subtitle: "Manage material inventory") {
                            showMaterials = true
                        }
                        MoreRow(icon: "ruler.fill", color: Color(hex: "#9B59B6"), title: "Measurements", subtitle: "Saved dimensions") {
                            showMeasurements = true
                        }
                        MoreRow(icon: "checkmark.circle.fill", color: Color(hex: "#27AE60"), title: "Tasks", subtitle: "Construction task list") {
                            showTasks = true
                        }
                        MoreRow(icon: "chart.bar.fill", color: Color(hex: "#F5A623"), title: "Reports", subtitle: "Material usage analytics") {
                            showReports = true
                        }
                    } header: { Text("Tools") }

                    Section {
                        MoreRow(icon: "person.fill", color: Color(hex: "#F4621F"), title: "Profile", subtitle: appState.userName) {
                            showProfile = true
                        }
                        MoreRow(icon: "gear", color: Color(hex: "#6B7C93"), title: "Settings", subtitle: "Preferences & units") {
                            showSettings = true
                        }
                    } header: { Text("Account") }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showMaterials) { MaterialsView() }
        .sheet(isPresented: $showMeasurements) { MeasurementsView() }
        .sheet(isPresented: $showReports) { ReportsView() }
        .sheet(isPresented: $showTasks) { TasksView() }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }
}

struct MoreRow: View {
    var icon: String
    var color: Color
    var title: String
    var subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SBCFont.headline(15))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(SBCFont.body(13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }
}
