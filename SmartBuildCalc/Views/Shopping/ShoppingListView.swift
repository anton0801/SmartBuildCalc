import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showAddItem = false

    var pendingItems: [ShoppingItem] { projectsVM.shoppingItems.filter { !$0.isPurchased } }
    var purchasedItems: [ShoppingItem] { projectsVM.shoppingItems.filter { $0.isPurchased } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                if projectsVM.shoppingItems.isEmpty {
                    EmptyStateView(
                        icon: "cart",
                        title: "Empty Cart",
                        message: "Add items from the calculator or manually",
                        buttonTitle: "Add Item"
                    ) { showAddItem = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary card
                            HStack(spacing: 0) {
                                StatBadge(value: "\(pendingItems.count)", label: "To Buy", color: .brandOrange)
                                Divider().frame(height: 36)
                                StatBadge(value: "\(purchasedItems.count)", label: "Bought", color: .brandGreen)
                                Divider().frame(height: 36)
                                StatBadge(value: settingsVM.formatCurrency(projectsVM.remainingShoppingCost), label: "Remaining", color: .brandGold)
                            }
                            .cardStyle()

                            // Pending
                            if !pendingItems.isEmpty {
                                VStack(spacing: 8) {
                                    SBCSectionHeader(title: "To Purchase")
                                    ForEach(pendingItems) { item in
                                        ShoppingItemRow(item: item)
                                    }
                                }
                            }

                            // Purchased
                            if !purchasedItems.isEmpty {
                                VStack(spacing: 8) {
                                    SBCSectionHeader(title: "Purchased")
                                    ForEach(purchasedItems) { item in
                                        ShoppingItemRow(item: item)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.brandOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddItem) { AddShoppingItemView() }
    }
}

struct ShoppingItemRow: View {
    var item: ShoppingItem
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack(spacing: 14) {
            Button(action: { projectsVM.togglePurchased(item) }) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(item.isPurchased ? .brandGreen : .textMuted)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isPurchased)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.materialName)
                    .font(SBCFont.headline(15))
                    .strikethrough(item.isPurchased)
                    .foregroundColor(item.isPurchased ? .textSecondary : .primary)
                Text("\(String(format: "%.2f", item.quantity)) \(item.unit)")
                    .font(SBCFont.body(13))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(settingsVM.formatCurrency(item.estimatedCost))
                .font(SBCFont.mono(14))
                .foregroundColor(item.isPurchased ? .textSecondary : .brandGold)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.systemBackground).opacity(item.isPurchased ? 0.7 : 1.0))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                projectsVM.deleteShoppingItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddShoppingItemView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var materialName = ""
    @State private var quantity = ""
    @State private var unit = "pcs"
    @State private var cost = ""
    @State private var showError = false

    let units = ["pcs", "m²", "m³", "kg", "L", "m", "sheets", "bags"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            SBCInputField(title: "Material Name", placeholder: "e.g. Ceramic Tiles", text: $materialName)
                            HStack(spacing: 12) {
                                SBCInputField(title: "Quantity", placeholder: "100", text: $quantity, keyboardType: .decimalPad)
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
                            SBCInputField(title: "Estimated Cost (\(settingsVM.currencySymbol))", placeholder: "0.00", text: $cost, keyboardType: .decimalPad)
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        if showError {
                            Text("Please fill all required fields")
                                .font(SBCFont.caption(13))
                                .foregroundColor(.brandRed)
                        }

                        Button("Add to List") {
                            guard !materialName.isEmpty,
                                  let q = Double(quantity), q > 0 else { showError = true; return }
                            let item = ShoppingItem(
                                materialName: materialName,
                                quantity: q,
                                unit: unit,
                                estimatedCost: Double(cost) ?? 0
                            )
                            projectsVM.addShoppingItem(item)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }
}
