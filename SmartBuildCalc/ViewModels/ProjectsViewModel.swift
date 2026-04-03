import SwiftUI
import Combine

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var materials: [Material] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var measurements: [Measurement] = []
    @Published var tasks: [BuildTask] = []

    private let projectsKey = "sbc_projects"
    private let materialsKey = "sbc_materials"
    private let shoppingKey = "sbc_shopping"
    private let measurementsKey = "sbc_measurements"
    private let tasksKey = "sbc_tasks"

    init() {
        loadAll()
    }

    // MARK: - Projects
    func addProject(_ project: Project) {
        projects.insert(project, at: 0)
        saveProjects()
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            saveProjects()
        }
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        materials.removeAll { $0.projectId == project.id }
        shoppingItems.removeAll { $0.projectId == project.id }
        saveProjects()
        saveMaterials()
        saveShoppingItems()
    }

    func addRoom(_ room: Room, to project: inout Project) {
        project.rooms.append(room)
        updateProject(project)
    }

    func deleteRoom(at offsets: IndexSet, from project: inout Project) {
        project.rooms.remove(atOffsets: offsets)
        updateProject(project)
    }

    // MARK: - Materials
    func addMaterial(_ material: Material) {
        materials.insert(material, at: 0)
        saveMaterials()
    }

    func updateMaterial(_ material: Material) {
        if let idx = materials.firstIndex(where: { $0.id == material.id }) {
            materials[idx] = material
            saveMaterials()
        }
    }

    func deleteMaterial(_ material: Material) {
        materials.removeAll { $0.id == material.id }
        saveMaterials()
    }

    func materials(for projectId: UUID) -> [Material] {
        materials.filter { $0.projectId == projectId }
    }

    var totalMaterialCost: Double {
        materials.reduce(0) { $0 + $1.totalCost }
    }

    // MARK: - Shopping
    func addShoppingItem(_ item: ShoppingItem) {
        shoppingItems.insert(item, at: 0)
        saveShoppingItems()
    }

    func togglePurchased(_ item: ShoppingItem) {
        if let idx = shoppingItems.firstIndex(where: { $0.id == item.id }) {
            shoppingItems[idx].isPurchased.toggle()
            saveShoppingItems()
        }
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        shoppingItems.removeAll { $0.id == item.id }
        saveShoppingItems()
    }

    var purchasedCount: Int { shoppingItems.filter { $0.isPurchased }.count }
    var totalShoppingCost: Double { shoppingItems.reduce(0) { $0 + $1.estimatedCost } }
    var remainingShoppingCost: Double { shoppingItems.filter { !$0.isPurchased }.reduce(0) { $0 + $1.estimatedCost } }

    // MARK: - Measurements
    func addMeasurement(_ measurement: Measurement) {
        measurements.insert(measurement, at: 0)
        saveMeasurements()
    }

    func deleteMeasurement(_ measurement: Measurement) {
        measurements.removeAll { $0.id == measurement.id }
        saveMeasurements()
    }

    // MARK: - Tasks
    func addTask(_ task: BuildTask) {
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func toggleTaskCompleted(_ task: BuildTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            saveTasks()
        }
    }

    func deleteTask(_ task: BuildTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    var completedTaskCount: Int { tasks.filter { $0.isCompleted }.count }
    var pendingTaskCount: Int { tasks.filter { !$0.isCompleted }.count }

    // MARK: - Persistence
    private func saveProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: projectsKey)
        }
    }

    private func saveMaterials() {
        if let data = try? JSONEncoder().encode(materials) {
            UserDefaults.standard.set(data, forKey: materialsKey)
        }
    }

    private func saveShoppingItems() {
        if let data = try? JSONEncoder().encode(shoppingItems) {
            UserDefaults.standard.set(data, forKey: shoppingKey)
        }
    }

    private func saveMeasurements() {
        if let data = try? JSONEncoder().encode(measurements) {
            UserDefaults.standard.set(data, forKey: measurementsKey)
        }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }

    private func loadAll() {
        if let data = UserDefaults.standard.data(forKey: projectsKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
        if let data = UserDefaults.standard.data(forKey: materialsKey),
           let decoded = try? JSONDecoder().decode([Material].self, from: data) {
            materials = decoded
        }
        if let data = UserDefaults.standard.data(forKey: shoppingKey),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            shoppingItems = decoded
        }
        if let data = UserDefaults.standard.data(forKey: measurementsKey),
           let decoded = try? JSONDecoder().decode([Measurement].self, from: data) {
            measurements = decoded
        }
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([BuildTask].self, from: data) {
            tasks = decoded
        }
    }
}
