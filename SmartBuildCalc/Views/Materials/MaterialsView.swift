import SwiftUI

struct MaterialsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddMaterial = false
    @State private var searchText = ""

    var filtered: [Material] {
        searchText.isEmpty ? projectsVM.materials :
        projectsVM.materials.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                if projectsVM.materials.isEmpty {
                    EmptyStateView(
                        icon: "tray.2",
                        title: "No Materials",
                        message: "Add materials from the calculator results or manually",
                        buttonTitle: "Add Material"
                    ) { showAddMaterial = true }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            // Cost summary
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Material Cost")
                                        .font(SBCFont.body(13))
                                        .foregroundColor(.textSecondary)
                                    Text(settingsVM.formatCurrency(projectsVM.totalMaterialCost))
                                        .font(SBCFont.display(24))
                                        .foregroundColor(.brandOrange)
                                }
                                Spacer()
                                Text("\(filtered.count) items")
                                    .font(SBCFont.caption(13))
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color.brandOrange.opacity(0.1)))
                                    .foregroundColor(.brandOrange)
                            }
                            .cardStyle()

                            ForEach(filtered) { material in
                                MaterialRow(material: material)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            projectsVM.deleteMaterial(material)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Materials")
            .searchable(text: $searchText, prompt: "Search materials...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMaterial = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brandOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddMaterial) { AddMaterialView() }
    }
}

struct MaterialRow: View {
    var material: Material
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(material.type.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: material.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(material.type.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(material.name)
                    .font(SBCFont.headline(15))
                HStack(spacing: 6) {
                    Text("\(String(format: "%.2f", material.requiredAmount)) \(material.unit)")
                        .font(SBCFont.body(13))
                        .foregroundColor(.textSecondary)
                    Text("•")
                        .foregroundColor(.textMuted)
                    Text("\(settingsVM.currencySymbol)\(String(format: "%.2f", material.pricePerUnit))/\(material.unit)")
                        .font(SBCFont.body(13))
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
            Text(settingsVM.formatCurrency(material.totalCost))
                .font(SBCFont.mono(14))
                .foregroundColor(.brandGold)
        }
        .cardStyle()
    }
}

struct AddMaterialView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var type = Material.MaterialType.brick
    @State private var amount = ""
    @State private var unit = "pcs"
    @State private var price = ""
    @State private var notes = ""
    @State private var showError = false

    let units = ["pcs", "m²", "m³", "kg", "L", "m", "sheets", "bags"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            SBCInputField(title: "Material Name", placeholder: "e.g. Red Brick", text: $name)

                            VStack(alignment: .leading, spacing: 6) {
                                if #available(iOS 16.0, *) {
                                    Text("Material Type")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                } else {
                                    Text("Material Type")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                }
                                Picker("Type", selection: $type) {
                                    ForEach(Material.MaterialType.allCases, id: \.self) { t in
                                        Label(t.rawValue, systemImage: t.icon).tag(t)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 120)
                            }

                            HStack(spacing: 12) {
                                SBCInputField(title: "Required Amount", placeholder: "500", text: $amount, keyboardType: .decimalPad)
                                VStack(alignment: .leading, spacing: 6) {
                                    if #available(iOS 16.0, *) {
                                        Text("Unit")
                                            .font(SBCFont.caption(12))
                                            .foregroundColor(.textSecondary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)
                                    } else {
                                        Text("Unit")
                                            .font(SBCFont.caption(12))
                                            .foregroundColor(.textSecondary)
                                            .textCase(.uppercase)
                                    }
                                    Picker("Unit", selection: $unit) {
                                        ForEach(units, id: \.self) { u in Text(u).tag(u) }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.surfaceLight))
                                }
                            }

                            SBCInputField(title: "Price per Unit (\(settingsVM.currencySymbol))", placeholder: "0.50", text: $price, keyboardType: .decimalPad)
                            SBCInputField(title: "Notes (optional)", placeholder: "Brand, supplier...", text: $notes)
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        if showError { Text("Please fill all required fields").font(SBCFont.caption(13)).foregroundColor(.brandRed) }

                        Button("Add Material") {
                            guard !name.isEmpty, let a = Double(amount), a > 0 else { showError = true; return }
                            let material = Material(
                                name: name, type: type,
                                requiredAmount: a, unit: unit,
                                pricePerUnit: Double(price) ?? 0,
                                notes: notes
                            )
                            projectsVM.addMaterial(material)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.brandOrange)
                }
            }
        }
    }
}
