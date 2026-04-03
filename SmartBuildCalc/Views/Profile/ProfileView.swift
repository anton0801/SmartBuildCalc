import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var editingName = false
    @State private var newName = ""
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Avatar + name
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.brandGradient)
                                    .frame(width: 90, height: 90)
                                    .shadow(color: Color.brandOrange.opacity(0.4), radius: 16, x: 0, y: 8)
                                Text(String(appState.userName.prefix(1)).uppercased())
                                    .font(SBCFont.display(38))
                                    .foregroundColor(.white)
                            }

                            if editingName {
                                HStack(spacing: 8) {
                                    TextField("Your name", text: $newName)
                                        .font(SBCFont.headline(20))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.brandOrange, lineWidth: 1.5)
                                        )
                                        .frame(width: 200)

                                    Button("Save") {
                                        let trimmed = newName.trimmingCharacters(in: .whitespaces)
                                        if !trimmed.isEmpty {
                                            appState.userName = trimmed
                                        }
                                        editingName = false
                                    }
                                    .foregroundColor(.brandOrange)
                                    .font(SBCFont.headline(15))
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text(appState.userName.isEmpty ? "Builder" : appState.userName)
                                        .font(SBCFont.display(24))
                                    Button(action: {
                                        newName = appState.userName
                                        editingName = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.brandOrange.opacity(0.7))
                                    }
                                }
                            }

                            Text(appState.userEmail)
                                .font(SBCFont.body(14))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        // Stats grid
                        VStack(spacing: 12) {
                            SBCSectionHeader(title: "Your Statistics")
                            HStack(spacing: 12) {
                                ProfileStatCard(value: "\(projectsVM.projects.count)", label: "Projects", icon: "folder.fill", color: .brandOrange)
                                ProfileStatCard(value: "\(projectsVM.materials.count)", label: "Materials", icon: "tray.2.fill", color: .brandGold)
                            }
                            HStack(spacing: 12) {
                                ProfileStatCard(value: "\(projectsVM.shoppingItems.count)", label: "Shopping Items", icon: "cart.fill", color: .brandGreen)
                                ProfileStatCard(value: "\(projectsVM.tasks.count)", label: "Tasks", icon: "checkmark.circle.fill", color: Color(hex: "#9B59B6"))
                            }
                        }

                        // Total cost summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Project Investment")
                                    .font(SBCFont.body(13))
                                    .foregroundColor(.textSecondary)
                                Text(settingsVM.formatCurrency(projectsVM.totalMaterialCost))
                                    .font(SBCFont.display(26))
                                    .foregroundColor(.brandOrange)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.brandOrange.opacity(0.3))
                        }
                        .cardStyle()

                        // Log out
                        Button(action: { showLogoutConfirm = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                            }
                            .font(SBCFont.headline(16))
                            .foregroundColor(.brandRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.brandRed.opacity(0.08))
                            )
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
            .alert("Log Out", isPresented: $showLogoutConfirm) {
                Button("Log Out", role: .destructive) {
                    appState.isLoggedIn = false
                    appState.userName = ""
                    appState.userEmail = ""
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out? Your data will be saved.")
            }
        }
    }
}

struct ProfileStatCard: View {
    var value: String
    var label: String
    var icon: String
    var color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(SBCFont.mono(16))
                    .foregroundColor(.primary)
                Text(label)
                    .font(SBCFont.caption(11))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}
