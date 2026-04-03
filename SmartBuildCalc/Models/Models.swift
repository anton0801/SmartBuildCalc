import Foundation
import SwiftUI

// MARK: - Project Model
struct Project: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var buildingType: BuildingType
    var rooms: [Room]
    var createdAt: Date
    var totalEstimate: Double

    enum BuildingType: String, Codable, CaseIterable {
        case house = "House"
        case apartment = "Apartment"
        case office = "Office"
        case commercial = "Commercial"
        case industrial = "Industrial"

        var icon: String {
            switch self {
            case .house: return "house.fill"
            case .apartment: return "building.2.fill"
            case .office: return "building.columns.fill"
            case .commercial: return "storefront.fill"
            case .industrial: return "building.fill"
            }
        }
    }

    var roomCount: Int { rooms.count }
    var totalArea: Double { rooms.reduce(0) { $0 + $1.area } }
}

// MARK: - Room Model
struct Room: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var roomType: RoomType
    var length: Double
    var width: Double
    var height: Double

    var area: Double { length * width }
    var perimeter: Double { 2 * (length + width) }
    var wallArea: Double { perimeter * height }
    var volume: Double { area * height }

    enum RoomType: String, Codable, CaseIterable {
        case kitchen = "Kitchen"
        case bathroom = "Bathroom"
        case bedroom = "Bedroom"
        case livingRoom = "Living Room"
        case hallway = "Hallway"
        case garage = "Garage"
        case other = "Other"

        var icon: String {
            switch self {
            case .kitchen: return "fork.knife"
            case .bathroom: return "shower.fill"
            case .bedroom: return "bed.double.fill"
            case .livingRoom: return "sofa.fill"
            case .hallway: return "arrow.left.arrow.right"
            case .garage: return "car.fill"
            case .other: return "square.dashed"
            }
        }
    }
}

// MARK: - Material Model
struct Material: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: MaterialType
    var requiredAmount: Double
    var unit: String
    var pricePerUnit: Double
    var projectId: UUID?
    var notes: String

    var totalCost: Double { requiredAmount * pricePerUnit }

    enum MaterialType: String, Codable, CaseIterable {
        case brick = "Brick"
        case concrete = "Concrete"
        case tile = "Tile"
        case paint = "Paint"
        case drywall = "Drywall"
        case insulation = "Insulation"
        case wood = "Wood"
        case steel = "Steel"
        case other = "Other"

        var icon: String {
            switch self {
            case .brick: return "square.3.layers.3d.down.right"
            case .concrete: return "cube.fill"
            case .tile: return "square.grid.2x2.fill"
            case .paint: return "paintbrush.fill"
            case .drywall: return "rectangle.split.2x1.fill"
            case .insulation: return "thermometer.snowflake"
            case .wood: return "tree.fill"
            case .steel: return "link"
            case .other: return "tray.fill"
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
            case .wood: return Color(hex: "#8B6914")
            case .steel: return Color(hex: "#607D8B")
            case .other: return Color(hex: "#F4621F")
            }
        }
    }
}

// MARK: - Shopping Item
struct ShoppingItem: Identifiable, Codable {
    var id: UUID = UUID()
    var materialName: String
    var quantity: Double
    var unit: String
    var estimatedCost: Double
    var isPurchased: Bool = false
    var projectId: UUID?
    var notes: String = ""
}

// MARK: - Measurement
struct Measurement: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var length: Double
    var width: Double
    var height: Double
    var createdAt: Date

    var area: Double { length * width }
    var perimeter: Double { 2 * (length + width) }
    var volume: Double { length * width * height }
}

// MARK: - Task
struct BuildTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var notes: String
    var dueDate: Date
    var isCompleted: Bool = false
    var priority: Priority

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low: return .brandGreen
            case .medium: return .brandGold
            case .high: return .brandRed
            }
        }
    }
}

// MARK: - Calculator Result
struct CalculatorResult {
    var materialName: String
    var amount: Double
    var unit: String
    var estimatedCost: Double
    var breakdown: [(label: String, value: String)]
}
