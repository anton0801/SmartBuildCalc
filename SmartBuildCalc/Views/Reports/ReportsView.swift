import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode

    var materialTypeSummary: [(type: Material.MaterialType, cost: Double, count: Int)] {
        var dict: [Material.MaterialType: (cost: Double, count: Int)] = [:]
        for mat in projectsVM.materials {
            let existing = dict[mat.type] ?? (cost: 0, count: 0)
            dict[mat.type] = (cost: existing.cost + mat.totalCost, count: existing.count + 1)
        }
        return dict.map { (type: $0.key, cost: $0.value.cost, count: $0.value.count) }
            .sorted { $0.cost > $1.cost }
    }

    var totalCost: Double { projectsVM.materials.reduce(0) { $0 + $1.totalCost } }
    var totalRooms: Int { projectsVM.projects.reduce(0) { $0 + $1.roomCount } }
    var totalArea: Double { projectsVM.projects.reduce(0) { $0 + $1.totalArea } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Overview stats
                        VStack(spacing: 12) {
                            SBCSectionHeader(title: "Overview")

                            HStack(spacing: 12) {
                                ReportStatCard(
                                    value: "\(projectsVM.projects.count)",
                                    label: "Projects",
                                    icon: "folder.fill",
                                    color: .brandOrange
                                )
                                ReportStatCard(
                                    value: "\(totalRooms)",
                                    label: "Rooms",
                                    icon: "square.grid.2x2.fill",
                                    color: .brandGold
                                )
                            }
                            HStack(spacing: 12) {
                                ReportStatCard(
                                    value: settingsVM.formatArea(totalArea),
                                    label: "Total Area",
                                    icon: "ruler.fill",
                                    color: .brandGreen
                                )
                                ReportStatCard(
                                    value: settingsVM.formatCurrency(totalCost),
                                    label: "Materials Cost",
                                    icon: "dollarsign.circle.fill",
                                    color: Color(hex: "#9B59B6")
                                )
                            }
                        }

                        // Material usage by type
                        if !materialTypeSummary.isEmpty {
                            VStack(spacing: 12) {
                                SBCSectionHeader(title: "Cost by Material Type")

                                ForEach(materialTypeSummary, id: \.type) { item in
                                    MaterialTypeReportRow(
                                        item: item,
                                        totalCost: totalCost,
                                        currencySymbol: settingsVM.currencySymbol
                                    )
                                }
                            }
                        }

                        // Projects breakdown
                        if !projectsVM.projects.isEmpty {
                            VStack(spacing: 12) {
                                SBCSectionHeader(title: "Projects Breakdown")
                                ForEach(projectsVM.projects) { project in
                                    ProjectReportRow(project: project)
                                }
                            }
                        }

                        // Shopping summary
                        VStack(spacing: 12) {
                            SBCSectionHeader(title: "Shopping Summary")
                            HStack(spacing: 12) {
                                ReportStatCard(
                                    value: "\(projectsVM.shoppingItems.count)",
                                    label: "Total Items",
                                    icon: "cart.fill",
                                    color: .brandOrange
                                )
                                ReportStatCard(
                                    value: "\(projectsVM.purchasedCount)",
                                    label: "Purchased",
                                    icon: "checkmark.circle.fill",
                                    color: .brandGreen
                                )
                            }
                            if !projectsVM.shoppingItems.isEmpty {
                                HStack {
                                    Text("Total Shopping Budget")
                                        .font(SBCFont.body(14))
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(settingsVM.formatCurrency(projectsVM.totalShoppingCost))
                                        .font(SBCFont.headline(16))
                                        .foregroundColor(.brandGold)
                                }
                                .cardStyle()
                            }
                        }

                        // Tasks summary
                        VStack(spacing: 12) {
                            SBCSectionHeader(title: "Tasks")
                            HStack(spacing: 12) {
                                ReportStatCard(
                                    value: "\(projectsVM.completedTaskCount)",
                                    label: "Completed",
                                    icon: "checkmark.seal.fill",
                                    color: .brandGreen
                                )
                                ReportStatCard(
                                    value: "\(projectsVM.pendingTaskCount)",
                                    label: "Pending",
                                    icon: "clock.fill",
                                    color: .brandRed
                                )
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }
}

struct ReportStatCard: View {
    var value: String
    var label: String
    var icon: String
    var color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(SBCFont.mono(15))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(SBCFont.caption(12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct MaterialTypeReportRow: View {
    var item: (type: Material.MaterialType, cost: Double, count: Int)
    var totalCost: Double
    var currencySymbol: String

    var percentage: Double {
        totalCost > 0 ? (item.cost / totalCost) * 100 : 0
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(item.type.color.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: item.type.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(item.type.color)
                }
                Text(item.type.rawValue)
                    .font(SBCFont.headline(14))
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(currencySymbol)\(String(format: "%.2f", item.cost))")
                        .font(SBCFont.mono(14))
                        .foregroundColor(.primary)
                    Text("\(Int(percentage.rounded()))%")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.type.color.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.type.color)
                        .frame(width: geo.size.width * CGFloat(percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
        .cardStyle()
    }
}

struct ProjectReportRow: View {
    var project: Project
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var projectsVM: ProjectsViewModel

    var projectCost: Double {
        projectsVM.materials(for: project.id).reduce(0) { $0 + $1.totalCost }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 36, height: 36)
                Image(systemName: project.buildingType.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(SBCFont.headline(14))
                Text("\(project.roomCount) rooms · \(settingsVM.formatArea(project.totalArea))")
                    .font(SBCFont.body(12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Text(settingsVM.formatCurrency(projectCost))
                .font(SBCFont.mono(13))
                .foregroundColor(.brandGold)
        }
        .cardStyle()
    }
}
