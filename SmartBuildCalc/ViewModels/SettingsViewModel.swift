import SwiftUI
import Combine
import UserNotifications

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
