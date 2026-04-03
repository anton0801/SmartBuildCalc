import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header card
                        DashboardHeaderCard()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        // Quick stats
                        HStack(spacing: 12) {
                            QuickStatCard(
                                value: "\(projectsVM.projects.count)",
                                label: "Projects",
                                icon: "folder.fill",
                                color: .brandOrange
                            )
                            QuickStatCard(
                                value: settingsVM.formatCurrency(projectsVM.totalMaterialCost),
                                label: "Materials Cost",
                                icon: "dollarsign.circle.fill",
                                color: .brandGold
                            )
                            QuickStatCard(
                                value: "\(projectsVM.pendingTaskCount)",
                                label: "Tasks Due",
                                icon: "checkmark.circle.fill",
                                color: .brandGreen
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                        // Quick calculators
//                        VStack(spacing: 12) {
//                            SBCSectionHeader(title: "Quick Calculators")
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 12) {
//                                    ForEach(quickCalcs, id: \.title) { calc in
//                                        QuickCalcChip(calc: calc)
//                                    }
//                                }
//                                .padding(.horizontal, 2)
//                            }
//                        }
//                        .opacity(appeared ? 1 : 0)

                        // Recent projects
                        if !projectsVM.projects.isEmpty {
                            VStack(spacing: 12) {
                                SBCSectionHeader(title: "Recent Projects")
                                ForEach(Array(projectsVM.projects.prefix(3))) { project in
                                    DashboardProjectCard(project: project)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                        } else {
                            EmptyDashboardCard()
                                .opacity(appeared ? 1 : 0)
                        }

                        // Shopping summary
                        if !projectsVM.shoppingItems.isEmpty {
                            ShoppingSummaryCard()
                                .opacity(appeared ? 1 : 0)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.brandOrange)
                            if projectsVM.pendingTaskCount > 0 {
                                Circle()
                                    .fill(Color.brandRed)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }

    var quickCalcs: [(title: String, icon: String, color: Color, tag: Int)] = [
        ("Brick", "square.3.layers.3d.down.right", Color(hex: "#E74C3C"), 0),
        ("Concrete", "cube.fill", Color(hex: "#95A5A6"), 1),
        ("Tile", "square.grid.2x2.fill", Color(hex: "#3498DB"), 2),
        ("Paint", "paintbrush.fill", Color(hex: "#9B59B6"), 3),
        ("Drywall", "rectangle.split.2x1.fill", Color(hex: "#F39C12"), 4),
        ("Insulation", "thermometer.snowflake", Color(hex: "#1ABC9C"), 5),
    ]
}

struct DashboardHeaderCard: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting + ",")
                    .font(SBCFont.body(15))
                    .foregroundColor(.textSecondary)
                Text(appState.userName.isEmpty ? "Builder" : appState.userName)
                    .font(SBCFont.display(22))
                    .foregroundColor(.primary)
                Text("Ready to build something great?")
                    .font(SBCFont.body(13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 52, height: 52)
                Text(String(appState.userName.prefix(1)).uppercased())
                    .font(SBCFont.display(22))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.brandSlate, Color.brandSlateMid],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
    }
}

struct QuickStatCard: View {
    var value: String
    var label: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(SBCFont.mono(16))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(SBCFont.caption(11))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle(padding: 0)
    }
}

struct QuickCalcChip: View {
    var calc: (title: String, icon: String, color: Color, tag: Int)
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(calc.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: calc.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(calc.color)
            }
            Text(calc.title)
                .font(SBCFont.caption(12))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
    }
}

struct DashboardProjectCard: View {
    var project: Project
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 44, height: 44)
                Image(systemName: project.buildingType.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(SBCFont.headline(15))
                HStack(spacing: 8) {
                    Label("\(project.roomCount) rooms", systemImage: "square.grid.2x2")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                    Text("•")
                        .foregroundColor(.textMuted)
                    Text(settingsVM.formatArea(project.totalArea))
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .cardStyle()
    }
}

struct EmptyDashboardCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(.brandOrange.opacity(0.5))
            VStack(spacing: 6) {
                Text("No Projects Yet")
                    .font(SBCFont.headline(17))
                Text("Create your first project to start calculating materials")
                    .font(SBCFont.body(14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .cardStyle(padding: 0)
    }
}

struct ShoppingSummaryCard: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(spacing: 12) {
            SBCSectionHeader(title: "Shopping Progress")
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(projectsVM.purchasedCount) / \(projectsVM.shoppingItems.count)")
                        .font(SBCFont.display(24))
                        .foregroundColor(.brandOrange)
                    Text("items purchased")
                        .font(SBCFont.body(13))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(settingsVM.formatCurrency(projectsVM.remainingShoppingCost))
                        .font(SBCFont.headline(18))
                        .foregroundColor(.brandGold)
                    Text("remaining")
                        .font(SBCFont.body(13))
                        .foregroundColor(.textSecondary)
                }
            }
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brandOrange.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.brandGradient)
                        .frame(width: projectsVM.shoppingItems.isEmpty ? 0 : geo.size.width * CGFloat(projectsVM.purchasedCount) / CGFloat(projectsVM.shoppingItems.count), height: 8)
                }
            }
            .frame(height: 8)
        }
        .cardStyle()
    }
}
