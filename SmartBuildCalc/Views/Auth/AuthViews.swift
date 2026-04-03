import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showSignUp = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandSlate, Color(hex: "#0D1520")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Background decorative elements
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.brandOrange.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .offset(x: 80, y: -80)
                }
                Spacer()
                HStack {
                    Circle()
                        .fill(Color.brandGold.opacity(0.06))
                        .frame(width: 200, height: 200)
                        .offset(x: -60, y: 60)
                    Spacer()
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(LinearGradient.brandGradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.brandOrange.opacity(0.4), radius: 20, x: 0, y: 10)

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appeared ? 1 : 0.5)

                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Text("SmartBuild")
                                .font(SBCFont.display(30))
                                .foregroundColor(.white)
                            Text(" Calc")
                                .font(SBCFont.display(30))
                                .foregroundColor(.brandOrange)
                        }
                        Text("Your construction material calculator")
                            .font(SBCFont.body(15))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()

                // Feature pills
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        FeaturePill(icon: "square.3.layers.3d.down.right", label: "Bricks & Concrete")
                        FeaturePill(icon: "square.grid.2x2.fill", label: "Tile & Paint")
                    }
                    HStack(spacing: 10) {
                        FeaturePill(icon: "folder.fill", label: "Save Projects")
                        FeaturePill(icon: "cart.fill", label: "Shopping List")
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                // Auth buttons
                VStack(spacing: 14) {
                    Button("Create Account") { showSignUp = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .opacity(appeared ? 1 : 0)

                    Button("Log In") { showLogin = true }
                        .buttonStyle(SecondaryButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .opacity(appeared ? 1 : 0)

                    Button("Continue as Guest") {
                        appState.userName = "Guest"
                        appState.userEmail = "guest@example.com"
                        appState.isLoggedIn = true
                    }
                    .buttonStyle(GhostButtonStyle())
                    .foregroundColor(.white.opacity(0.5))
                    .font(SBCFont.body(14))
                    .opacity(appeared ? 1 : 0)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showLogin) { LoginView() }
        .fullScreenCover(isPresented: $showSignUp) { SignUpView() }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct FeaturePill: View {
    var icon: String
    var label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.brandOrange)
            Text(label)
                .font(SBCFont.caption(12))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.brandGradient)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("Welcome Back")
                                .font(SBCFont.display(26))
                            Text("Sign in to your account")
                                .font(SBCFont.body(15))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 20)

                        // Form
                        VStack(spacing: 16) {
                            SBCInputField(title: "Email", placeholder: "your@email.com", text: $email, keyboardType: .emailAddress)
                            SBCInputField(title: "Password", placeholder: "••••••••", text: $password)
                        }
                        .padding()
                        .cardStyle()
                        .padding(.horizontal)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(SBCFont.caption(13))
                                .foregroundColor(.brandRed)
                                .padding(.horizontal, 24)
                        }

                        Button(action: login) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .disabled(isLoading)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }

    func login() {
        errorMessage = ""
        guard !email.isEmpty else { errorMessage = "Please enter your email."; return }
        guard !password.isEmpty else { errorMessage = "Please enter your password."; return }
        guard email.contains("@") else { errorMessage = "Please enter a valid email."; return }
        guard password.count >= 6 else { errorMessage = "Password must be at least 6 characters."; return }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let name = email.components(separatedBy: "@").first?.capitalized ?? "User"
            appState.userName = name
            appState.userEmail = email
            appState.isLoggedIn = true
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.brandGradient)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("Create Account")
                                .font(SBCFont.display(26))
                            Text("Start calculating your projects")
                                .font(SBCFont.body(15))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 16) {
                            SBCInputField(title: "Full Name", placeholder: "John Builder", text: $name)
                            SBCInputField(title: "Email", placeholder: "your@email.com", text: $email, keyboardType: .emailAddress)
                            SBCInputField(title: "Password", placeholder: "Min. 6 characters", text: $password)
                        }
                        .padding()
                        .cardStyle()
                        .padding(.horizontal)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(SBCFont.caption(13))
                                .foregroundColor(.brandRed)
                                .padding(.horizontal, 24)
                        }

                        Button(action: signUp) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .disabled(isLoading)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }

    func signUp() {
        errorMessage = ""
        guard !name.isEmpty else { errorMessage = "Please enter your name."; return }
        guard !email.isEmpty else { errorMessage = "Please enter your email."; return }
        guard email.contains("@") else { errorMessage = "Please enter a valid email."; return }
        guard password.count >= 6 else { errorMessage = "Password must be at least 6 characters."; return }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            appState.userName = name
            appState.userEmail = email
            appState.isLoggedIn = true
            presentationMode.wrappedValue.dismiss()
        }
    }
}
