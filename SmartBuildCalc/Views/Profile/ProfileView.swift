import SwiftUI
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var editingName = false
    @State private var newName = ""
    @State private var showLogoutConfirm = false
    @State private var showDeleteStep1 = false
    @State private var showDeleteStep2 = false
    @State private var deleteConfirmText = ""
    @State private var isDeletingAccount = false

    private let deleteKeyword = "DELETE"

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
                                        if !trimmed.isEmpty { appState.userName = trimmed }
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

                        // Account actions
                        VStack(spacing: 10) {
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

                            // Delete account
                            Button(action: { showDeleteStep1 = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.minus")
                                    Text("Delete Account")
                                }
                                .font(SBCFont.body(15))
                                .foregroundColor(Color(hex: "#8B0000"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: "#8B0000").opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(hex: "#8B0000").opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 16)
                }

                // Deletion loading overlay
                if isDeletingAccount {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(.white)
                        Text("Deleting account…")
                            .font(SBCFont.body(15))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.brandSlate))
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
            // Log out alert
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
            // Delete — step 1: warning
            .alert("Delete Account", isPresented: $showDeleteStep1) {
                Button("Continue", role: .destructive) {
                    deleteConfirmText = ""
                    showDeleteStep2 = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and erase ALL data — projects, materials, tasks, and shopping lists. This action cannot be undone.")
            }
            // Delete — step 2: type-to-confirm sheet
            .sheet(isPresented: $showDeleteStep2) {
                DeleteAccountConfirmSheet(
                    confirmText: $deleteConfirmText,
                    keyword: deleteKeyword,
                    onConfirm: performAccountDeletion,
                    onCancel: { showDeleteStep2 = false }
                )
            }
        }
    }

    // MARK: - Account Deletion
    private func performAccountDeletion() {
        showDeleteStep2 = false
        isDeletingAccount = true

        // Cancel all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        // Wipe all user data from UserDefaults
        let domain = Bundle.main.bundleIdentifier ?? "com.smartbuildcalc"
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()

        // Clear in-memory state
        projectsVM.projects = []
        projectsVM.materials = []
        projectsVM.shoppingItems = []
        projectsVM.measurements = []
        projectsVM.tasks = []

        // Small delay to show the deletion animation, then sign out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isDeletingAccount = false
            appState.isLoggedIn = false
            appState.hasCompletedOnboarding = false
            appState.userName = ""
            appState.userEmail = ""
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Type-to-confirm delete sheet
struct DeleteAccountConfirmSheet: View {
    @Binding var confirmText: String
    var keyword: String
    var onConfirm: () -> Void
    var onCancel: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var isMatch: Bool { confirmText == keyword }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Warning icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#8B0000").opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(hex: "#8B0000"))
                        }
                        .padding(.top, 12)

                        VStack(spacing: 10) {
                            Text("This Cannot Be Undone")
                                .font(SBCFont.display(22))
                                .foregroundColor(Color(hex: "#8B0000"))
                                .multilineTextAlignment(.center)

                            Text("All of your data will be permanently erased:")
                                .font(SBCFont.body(15))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // What will be deleted
                        VStack(alignment: .leading, spacing: 10) {
                            DeletionItem(icon: "folder.fill", label: "All projects and rooms")
                            DeletionItem(icon: "tray.2.fill", label: "All materials and cost data")
                            DeletionItem(icon: "cart.fill", label: "Shopping lists")
                            DeletionItem(icon: "checkmark.circle.fill", label: "Tasks and reminders")
                            DeletionItem(icon: "ruler.fill", label: "Saved measurements")
                            DeletionItem(icon: "bell.fill", label: "All scheduled notifications")
                            DeletionItem(icon: "person.fill", label: "Account credentials")
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "#8B0000").opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: "#8B0000").opacity(0.15), lineWidth: 1)
                                )
                        )

                        // Type-to-confirm field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type \"\(keyword)\" to confirm")
                                .font(SBCFont.caption(13))
                                .foregroundColor(.textSecondary)
                                .textCase(.none)

                            TextField("Type \(keyword) here", text: $confirmText)
                                .font(SBCFont.mono(16))
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.brandSlateMid.opacity(0.5) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    isMatch ? Color(hex: "#8B0000") : Color.textMuted.opacity(0.4),
                                                    lineWidth: isMatch ? 2 : 1
                                                )
                                        )
                                )
                        }

                        // Confirm button — only active when text matches
                        Button(action: onConfirm) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Delete My Account")
                            }
                            .font(SBCFont.headline(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isMatch ? Color(hex: "#8B0000") : Color.textMuted.opacity(0.3))
                            )
                        }
                        .disabled(!isMatch)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMatch)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }
}

struct DeletionItem: View {
    var icon: String
    var label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#8B0000"))
                .frame(width: 20)
            Text(label)
                .font(SBCFont.body(14))
                .foregroundColor(.primary)
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
