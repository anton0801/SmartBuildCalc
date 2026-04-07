import SwiftUI
import WebKit


extension WebCoordinator: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        
        popups.append(popup)
        
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        
        switch recognizer.state {
        case .changed:
            if translation.x > 0 {
                popupView.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
            
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in
                    self?.dismissTopPopup()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    popupView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}


struct CalculatorsView: View {
    @StateObject private var calcVM = CalculatorViewModel()
    @State private var selectedCalc: CalcType? = nil

    enum CalcType: String, CaseIterable {
        case brick = "Brick"
        case concrete = "Concrete"
        case tile = "Tile"
        case paint = "Paint"
        case drywall = "Drywall"
        case insulation = "Insulation"

        var icon: String {
            switch self {
            case .brick: return "square.3.layers.3d.down.right"
            case .concrete: return "cube.fill"
            case .tile: return "square.grid.2x2.fill"
            case .paint: return "paintbrush.fill"
            case .drywall: return "rectangle.split.2x1.fill"
            case .insulation: return "thermometer.snowflake"
            }
        }
        var color: Color {
            switch self {
            case .brick: return Color(hex: "#E74C3C")
            case .concrete: return Color(hex: "#95A5A6")
            case .tile: return Color(hex: "#3498DB")
            case .paint: return Color(hex: "#9B59B6")
            case .drywall: return Color(hex: "#F39C12")
            case .insulation: return Color(hex: "#1ABC9C")
            }
        }
        var description: String {
            switch self {
            case .brick: return "Calculate bricks for walls"
            case .concrete: return "Volume and mix ratios"
            case .tile: return "Floor & wall coverage"
            case .paint: return "Coverage by area & coats"
            case .drywall: return "Panel count for walls"
            case .insulation: return "Coverage & R-value"
            }
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Banner
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Material Calculators")
                                    .font(SBCFont.headline(18))
                                    .foregroundColor(.white)
                                Text("Precise estimates with wastage")
                                    .font(SBCFont.body(13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "function")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 18).fill(LinearGradient.slateGradient))

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(CalcType.allCases, id: \.self) { type in
                                CalcCard(type: type)
                                    .onTapGesture { selectedCalc = type }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Calculators")
            .sheet(item: $selectedCalc) { type in
                CalculatorDetailView(calcType: type, calcVM: calcVM)
            }
        }
    }
}

extension CalculatorsView.CalcType: Identifiable {
    var id: String { rawValue }
}

struct CalcCard: View {
    var type: CalculatorsView.CalcType
    @State private var pressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(type.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: type.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(type.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(SBCFont.headline(16))
                Text(type.description)
                    .font(SBCFont.body(12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(type.color)
                    .font(.system(size: 20))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
        .scaleEffect(pressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
    }
}


extension WebCoordinator: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = pan.view else { return false }
        
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}



struct CalculatorDetailView: View {
    var calcType: CalculatorsView.CalcType
    @ObservedObject var calcVM: CalculatorViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSaveSheet = false
    @State private var savedToShopping = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Input fields
                        VStack(spacing: 14) {
                            switch calcType {
                            case .brick: BrickInputs(calcVM: calcVM)
                            case .concrete: ConcreteInputs(calcVM: calcVM)
                            case .tile: TileInputs(calcVM: calcVM)
                            case .paint: PaintInputs(calcVM: calcVM)
                            case .drywall: DrywallInputs(calcVM: calcVM)
                            case .insulation: InsulationInputs(calcVM: calcVM)
                            }
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        // Calculate button
                        Button("Calculate") {
                            calculateForType()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        // Result
                        if let result = resultForType() {
                            ResultCard(result: result, currencySymbol: settingsVM.currencySymbol)
                                .transition(.move(edge: .bottom).combined(with: .opacity))

                            if savedToShopping {
                                Label("Added to Shopping List", systemImage: "checkmark.circle.fill")
                                    .font(SBCFont.caption(14))
                                    .foregroundColor(.brandGreen)
                            }

                            Button("Add to Shopping List") {
                                if let result = resultForType() {
                                    let item = ShoppingItem(
                                        materialName: result.materialName,
                                        quantity: result.amount,
                                        unit: result.unit,
                                        estimatedCost: result.estimatedCost
                                    )
                                    projectsVM.addShoppingItem(item)
                                    withAnimation { savedToShopping = true }
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(calcType.rawValue + " Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: resultForType() != nil)
        }
    }

    func calculateForType() {
        savedToShopping = false
        switch calcType {
        case .brick:
            calcVM.calculateBricks(pricePerBrick: settingsVM.defaultPricePerBrick, wastage: settingsVM.wastagePercentage)
        case .concrete:
            calcVM.calculateConcrete(pricePerM3: settingsVM.defaultPricePerM3Concrete, wastage: settingsVM.wastagePercentage)
        case .tile:
            calcVM.calculateTiles(pricePerM2: settingsVM.defaultPricePerM2Tile, wastage: settingsVM.wastagePercentage)
        case .paint:
            calcVM.calculatePaint(pricePerL: settingsVM.defaultPricePaintPerL, wastage: settingsVM.wastagePercentage)
        case .drywall:
            calcVM.calculateDrywall(pricePerSheet: settingsVM.defaultPriceDrywallPerSheet, wastage: settingsVM.wastagePercentage)
        case .insulation:
            calcVM.calculateInsulation(pricePerM2: settingsVM.defaultPriceInsulationPerM2, wastage: settingsVM.wastagePercentage)
        }
    }

    func resultForType() -> CalculatorResult? {
        switch calcType {
        case .brick: return calcVM.brickResult
        case .concrete: return calcVM.concreteResult
        case .tile: return calcVM.tileResult
        case .paint: return calcVM.paintResult
        case .drywall: return calcVM.drywallResult
        case .insulation: return calcVM.insulationResult
        }
    }
}

// MARK: - Calculator Result Card
struct ResultCard: View {
    var result: CalculatorResult
    var currencySymbol: String

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Calculation Result")
                    .font(SBCFont.headline(16))
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.brandGreen)
                    .font(.system(size: 20))
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.2f", result.amount))
                        .font(SBCFont.display(36))
                        .foregroundColor(.brandOrange)
                    Text(result.unit)
                        .font(SBCFont.body(14))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Est. Cost")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                    Text("\(currencySymbol)\(String(format: "%.2f", result.estimatedCost))")
                        .font(SBCFont.display(22))
                        .foregroundColor(.brandGold)
                }
            }

            Divider()

            VStack(spacing: 8) {
                ForEach(result.breakdown, id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .font(SBCFont.body(13))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(item.value)
                            .font(SBCFont.caption(13))
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Input Forms
struct BrickInputs: View {
    @ObservedObject var calcVM: CalculatorViewModel

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                SBCInputField(title: "Wall Height (m)", placeholder: "3.0", text: $calcVM.brickWallHeight, keyboardType: .decimalPad)
                SBCInputField(title: "Wall Width (m)", placeholder: "5.0", text: $calcVM.brickWallWidth, keyboardType: .decimalPad)
            }
            SBCInputField(title: "Wall Thickness (m)", placeholder: "0.25", text: $calcVM.brickWallThickness, keyboardType: .decimalPad)
            SBCInputField(title: "Mortar Thickness (mm)", placeholder: "10", text: $calcVM.brickMortarThickness, keyboardType: .decimalPad)

            VStack(alignment: .leading, spacing: 6) {
                if #available(iOS 16.0, *) {
                    Text("Brick Size")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                } else {
                    Text("Brick Size")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                }
                Picker("Brick Size", selection: $calcVM.brickSizeType) {
                    ForEach(CalculatorViewModel.BrickSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

struct ConcreteInputs: View {
    @ObservedObject var calcVM: CalculatorViewModel

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                SBCInputField(title: "Length (m)", placeholder: "5.0", text: $calcVM.concreteLength, keyboardType: .decimalPad)
                SBCInputField(title: "Width (m)", placeholder: "4.0", text: $calcVM.concreteWidth, keyboardType: .decimalPad)
            }
            SBCInputField(title: "Depth / Height (m)", placeholder: "0.15", text: $calcVM.concreteHeight, keyboardType: .decimalPad)
            VStack(alignment: .leading, spacing: 6) {
                if #available(iOS 16.0, *) {
                    Text("Concrete Grade")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                } else {
                    Text("Concrete Grade")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                }
                Picker("Grade", selection: $calcVM.concreteGrade) {
                    ForEach(CalculatorViewModel.ConcreteGrade.allCases, id: \.self) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
            }
        }
    }
}

struct TileInputs: View {
    @ObservedObject var calcVM: CalculatorViewModel

    var body: some View {
        VStack(spacing: 14) {
            SBCInputField(title: "Floor/Wall Area (m²)", placeholder: "25.0", text: $calcVM.tileFloorArea, keyboardType: .decimalPad)
            HStack(spacing: 12) {
                SBCInputField(title: "Tile Width (cm)", placeholder: "60", text: $calcVM.tileSizeWidth, keyboardType: .decimalPad)
                SBCInputField(title: "Tile Length (cm)", placeholder: "60", text: $calcVM.tileSizeLength, keyboardType: .decimalPad)
            }
            SBCInputField(title: "Grout Width (mm)", placeholder: "3", text: $calcVM.tileGroutWidth, keyboardType: .decimalPad)
        }
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "smartbuild_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🏗️ [SmartBuild] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct PaintInputs: View {
    @ObservedObject var calcVM: CalculatorViewModel

    var body: some View {
        VStack(spacing: 14) {
            SBCInputField(title: "Wall Area (m²)", placeholder: "50.0", text: $calcVM.paintWallArea, keyboardType: .decimalPad)
            SBCInputField(title: "Coverage per Litre (m²)", placeholder: "10", text: $calcVM.paintCoveragePerL, keyboardType: .decimalPad)
            VStack(alignment: .leading, spacing: 6) {
                if #available(iOS 16.0, *) {
                    Text("Number of Coats")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                } else {
                    Text("Number of Coats")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                }
                Stepper("\(calcVM.paintCoats) coat\(calcVM.paintCoats > 1 ? "s" : "")", value: $calcVM.paintCoats, in: 1...4)
                    .font(SBCFont.body(15))
            }
        }
    }
}

struct DrywallInputs: View {
    @ObservedObject var calcVM: CalculatorViewModel

    var body: some View {
        VStack(spacing: 14) {
            SBCInputField(title: "Total Wall Area (m²)", placeholder: "60.0", text: $calcVM.drywallWallArea, keyboardType: .decimalPad)
            HStack(spacing: 12) {
                SBCInputField(title: "Panel Width (m)", placeholder: "1.2", text: $calcVM.drywallPanelWidth, keyboardType: .decimalPad)
                SBCInputField(title: "Panel Height (m)", placeholder: "2.4", text: $calcVM.drywallPanelHeight, keyboardType: .decimalPad)
            }
        }
    }
}

struct InsulationInputs: View {
    @ObservedObject var calcVM: CalculatorViewModel

    var body: some View {
        VStack(spacing: 14) {
            SBCInputField(title: "Surface Area (m²)", placeholder: "80.0", text: $calcVM.insulationSurfaceArea, keyboardType: .decimalPad)
            SBCInputField(title: "Thickness (cm)", placeholder: "10", text: $calcVM.insulationThickness, keyboardType: .decimalPad)
            VStack(alignment: .leading, spacing: 6) {
                if #available(iOS 16.0, *) {
                    Text("Insulation Type")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                } else {
                    Text("Insulation Type")
                        .font(SBCFont.caption(12))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                }
                Picker("Type", selection: $calcVM.insulationType) {
                    ForEach(CalculatorViewModel.InsulationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}



extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [SmartBuild] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
