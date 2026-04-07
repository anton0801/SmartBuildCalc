import SwiftUI

struct MeasurementsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddMeasurement = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                if projectsVM.measurements.isEmpty {
                    EmptyStateView(
                        icon: "ruler",
                        title: "No Measurements",
                        message: "Save room dimensions for quick access later",
                        buttonTitle: "Add Measurement"
                    ) { showAddMeasurement = true }
                } else {
                    List {
                        ForEach(projectsVM.measurements) { m in
                            MeasurementRow(measurement: m)
                        }
                        .onDelete { offsets in
                            offsets.map { projectsVM.measurements[$0] }.forEach {
                                projectsVM.deleteMeasurement($0)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Measurements")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.brandOrange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMeasurement = true }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.brandOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddMeasurement) { AddMeasurementView() }
    }
}

struct MeasurementRow: View {
    var measurement: Measurement
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(measurement.name)
                .font(SBCFont.headline(15))
            HStack(spacing: 16) {
                Label("\(String(format: "%.2f", measurement.length))×\(String(format: "%.2f", measurement.width)) \(settingsVM.lengthUnit)", systemImage: "ruler")
                    .font(SBCFont.body(13))
                    .foregroundColor(.textSecondary)
                Label(settingsVM.formatArea(measurement.area), systemImage: "square")
                    .font(SBCFont.body(13))
                    .foregroundColor(.brandOrange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddMeasurementView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var length = ""
    @State private var width = ""
    @State private var height = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            SBCInputField(title: "Name", placeholder: "e.g. Living Room Wall", text: $name)
                            HStack(spacing: 12) {
                                SBCInputField(title: "Length (m)", placeholder: "5.0", text: $length, keyboardType: .decimalPad)
                                SBCInputField(title: "Width (m)", placeholder: "4.0", text: $width, keyboardType: .decimalPad)
                            }
                            SBCInputField(title: "Height (m)", placeholder: "2.5", text: $height, keyboardType: .decimalPad)
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        if showError { Text("Please fill all required fields").font(SBCFont.caption(13)).foregroundColor(.brandRed) }

                        // Preview
                        if let l = Double(length), let w = Double(width) {
                            HStack {
                                VStack(spacing: 4) {
                                    Text("Area")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                    Text("\(String(format: "%.2f", l * w)) m²")
                                        .font(SBCFont.mono(16))
                                        .foregroundColor(.brandOrange)
                                }
                                Spacer()
                                VStack(spacing: 4) {
                                    Text("Perimeter")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                    Text("\(String(format: "%.2f", 2 * (l + w))) m")
                                        .font(SBCFont.mono(16))
                                        .foregroundColor(.brandGold)
                                }
                                if let h = Double(height) {
                                    Spacer()
                                    VStack(spacing: 4) {
                                        Text("Volume")
                                            .font(SBCFont.caption(12))
                                            .foregroundColor(.textSecondary)
                                        Text("\(String(format: "%.2f", l * w * h)) m³")
                                            .font(SBCFont.mono(16))
                                            .foregroundColor(.brandGreen)
                                    }
                                }
                            }
                            .cardStyle()
                        }

                        Button("Save Measurement") {
                            guard !name.isEmpty,
                                  let l = Double(length), let w = Double(width),
                                  l > 0, w > 0 else { showError = true; return }
                            let m = Measurement(
                                name: name,
                                length: l, width: w,
                                height: Double(height) ?? 0,
                                createdAt: Date()
                            )
                            projectsVM.addMeasurement(m)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.brandOrange)
                }
            }
        }
    }
}


struct SmartBuildWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "sbc_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}
