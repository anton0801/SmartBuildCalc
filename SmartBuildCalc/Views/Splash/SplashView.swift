import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    
    @StateObject private var app: SmartBuildApplication
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let validation = SupabaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _app = StateObject(wrappedValue: SmartBuildApplication(
            storage: storage,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.brandSlate, Color(hex: "#0D1520")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    ZStack {
                        Color.black.ignoresSafeArea()
                        Image("loading_scr")
                            .resizable().scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .ignoresSafeArea()
                            .blur(radius: 6)
                            .opacity(0.8)
                    }
                }
                .ignoresSafeArea()
                
                // Decorative rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.brandOrange.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                        .frame(width: CGFloat(180 + i * 80), height: CGFloat(180 + i * 80))
                        .scaleEffect(ringScale + CGFloat(i) * 0.1)
                        .opacity(ringOpacity)
                }
                
                // Particle dots
                ForEach(0..<12) { i in
                    let angle = Double(i) * 30.0
                    let radius: Double = 120
                    Circle()
                        .fill(Color.brandOrange.opacity(0.6))
                        .frame(width: i % 3 == 0 ? 6 : 4, height: i % 3 == 0 ? 6 : 4)
                        .offset(
                            x: CGFloat(cos(angle * .pi / 180) * radius),
                            y: CGFloat(sin(angle * .pi / 180) * radius)
                        )
                        .opacity(particleOpacity)
                }
                
                NavigationLink(
                    destination: SmartBuildWebView().navigationBarHidden(true),
                    isActive: $app.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $app.navigateToMain
                ) { EmptyView() }
                
                VStack(spacing: 24) {
                    // Logo icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(LinearGradient.brandGradient)
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.brandOrange.opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    VStack(spacing: 8) {
                        Text("SmartBuild")
                            .font(SBCFont.display(32))
                            .foregroundColor(.white)
                        + Text(" Calc")
                            .font(SBCFont.display(32))
                            .foregroundColor(.brandOrange)
                        
                        Text("Calculate materials for construction")
                            .font(SBCFont.body(15))
                            .foregroundColor(.white.opacity(0.6))
                        
                        ProgressView()
                            .tint(.white)
                    }
                    .opacity(textOpacity)
                }
            }
            .onAppear {
                setupStreams()
                setupNetworkMonitoring()
                app.initialize()
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                    ringScale = 1.0
                    ringOpacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
                    particleOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
                    textOpacity = 1.0
                }
            }
            
            .fullScreenCover(isPresented: $app.showPermissionPrompt) {
                SmartBuildNotificationView(app: app)
            }
            .fullScreenCover(isPresented: $app.showOfflineView) {
                UnavailableView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                app.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                app.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                app.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct SmartBuildNotificationView: View {
    let app: SmartBuildApplication
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "main_pp_bg2" : "main_pp_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                app.requestPermission()
            } label: {
                Image("main_pp_button")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                app.deferPermission()
            } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(0.7)
            }
        }
        .padding(.horizontal, 12)
    }
}



struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(geometry.size.width > geometry.size.height ? "wifi_scr2" : "wifi_scr")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 6)
                    .opacity(0.8)
                
                Image("wifi_scr_alr")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    UnavailableView()
}
