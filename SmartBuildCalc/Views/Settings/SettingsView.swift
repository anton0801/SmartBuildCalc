import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSavedBanner = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Appearance
                        SettingsSection(title: "Appearance", icon: "paintpalette.fill", color: Color(hex: "#9B59B6")) {
                            VStack(spacing: 0) {
                                SettingsRowLabel(title: "Theme", subtitle: "App color scheme")
                                Picker("Theme", selection: $settingsVM.themeMode) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 14)
                                .onChange(of: settingsVM.themeMode) { _ in flashSaved() }
                            }
                        }

                        // Units & Currency
                        SettingsSection(title: "Units & Currency", icon: "ruler.fill", color: Color(hex: "#3498DB")) {
                            VStack(spacing: 0) {
                                Divider().padding(.horizontal, 16)
                                HStack {
                                    Text("Unit System")
                                        .font(SBCFont.body(15))
                                    Spacer()
                                    Picker("Units", selection: $settingsVM.unitSystem) {
                                        Text("Metric").tag("metric")
                                        Text("Imperial").tag("imperial")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 170)
                                    .onChange(of: settingsVM.unitSystem) { _ in flashSaved() }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider().padding(.horizontal, 16)

                                HStack {
                                    Text("Currency")
                                        .font(SBCFont.body(15))
                                    Spacer()
                                    Picker("Currency", selection: $settingsVM.currency) {
                                        ForEach(settingsVM.currencies, id: \.self) { c in
                                            Text(c).tag(c)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .accentColor(.brandOrange)
                                    .onChange(of: settingsVM.currency) { _ in flashSaved() }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Calculation Defaults
                        SettingsSection(title: "Calculation Defaults", icon: "function", color: .brandOrange) {
                            VStack(spacing: 0) {
                                Divider().padding(.horizontal, 16)

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Wastage Percentage")
                                            .font(SBCFont.body(15))
                                        Spacer()
                                        Text("\(Int(settingsVM.wastagePercentage))%")
                                            .font(SBCFont.mono(14))
                                            .foregroundColor(.brandOrange)
                                    }
                                    Slider(value: $settingsVM.wastagePercentage, in: 0...30, step: 1)
                                        .accentColor(.brandOrange)
                                        .onChange(of: settingsVM.wastagePercentage) { _ in flashSaved() }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider().padding(.horizontal, 16)

                                Group {
                                    PriceInputRow(label: "Price/Brick (\(settingsVM.currencySymbol))", value: $settingsVM.defaultPricePerBrick)
                                    Divider().padding(.horizontal, 16)
                                    PriceInputRow(label: "Concrete /m³ (\(settingsVM.currencySymbol))", value: $settingsVM.defaultPricePerM3Concrete)
                                    Divider().padding(.horizontal, 16)
                                    PriceInputRow(label: "Tile /m² (\(settingsVM.currencySymbol))", value: $settingsVM.defaultPricePerM2Tile)
                                    Divider().padding(.horizontal, 16)
                                    PriceInputRow(label: "Paint /L (\(settingsVM.currencySymbol))", value: $settingsVM.defaultPricePaintPerL)
                                    Divider().padding(.horizontal, 16)
                                    PriceInputRow(label: "Drywall /sheet (\(settingsVM.currencySymbol))", value: $settingsVM.defaultPriceDrywallPerSheet)
                                    Divider().padding(.horizontal, 16)
                                    PriceInputRow(label: "Insulation /m² (\(settingsVM.currencySymbol))", value: $settingsVM.defaultPriceInsulationPerM2)
                                }
                            }
                        }

                        // Notifications
                        SettingsSection(title: "Notifications", icon: "bell.fill", color: Color(hex: "#F5A623")) {
                            VStack(spacing: 0) {
                                Divider().padding(.horizontal, 16)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Task Reminders")
                                            .font(SBCFont.body(15))
                                        Text("Get notified when tasks are due")
                                            .font(SBCFont.caption(12))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $settingsVM.notificationsEnabled)
                                        .tint(.brandOrange)
                                        .onChange(of: settingsVM.notificationsEnabled) { _ in flashSaved() }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }

                        // About
                        SettingsSection(title: "About", icon: "info.circle.fill", color: Color(hex: "#6B7C93")) {
                            VStack(spacing: 0) {
                                Divider().padding(.horizontal, 16)
                                AboutRow(label: "Version", value: "1.0.0")
                                Divider().padding(.horizontal, 16)
                                AboutRow(label: "Build", value: "2025.1")
                                Divider().padding(.horizontal, 16)
                                AboutRow(label: "Platform", value: "iOS 14+")
                            }
                        }

                        // Saved confirmation banner
                        if showSavedBanner {
                            Label("Settings saved", systemImage: "checkmark.circle.fill")
                                .font(SBCFont.caption(14))
                                .foregroundColor(.brandGreen)
                                .padding(.vertical, 8)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }

    func flashSaved() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSavedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSavedBanner = false
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(SBCFont.headline(15))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            content
                .padding(.bottom, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.cardDark : Color.cardLight)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }
}

struct SettingsRowLabel: View {
    var title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(SBCFont.body(15))
            if let sub = subtitle {
                Text(sub).font(SBCFont.caption(12)).foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct PriceInputRow: View {
    var label: String
    @Binding var value: Double
    @State private var text: String = ""
    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(label)
                .font(SBCFont.body(14))
                .foregroundColor(.primary)
            Spacer()
            TextField("0.00", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(SBCFont.mono(14))
                .foregroundColor(.brandOrange)
                .frame(width: 80)
                .onAppear { text = String(format: "%.2f", value) }
                .onChange(of: text) { newVal in
                    if let parsed = Double(newVal) { value = parsed }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

struct AboutRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label).font(SBCFont.body(15))
            Spacer()
            Text(value).font(SBCFont.body(15)).foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
