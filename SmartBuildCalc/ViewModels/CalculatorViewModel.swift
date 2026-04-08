import SwiftUI

class CalculatorViewModel: ObservableObject {
    // MARK: - Brick Calculator
    @Published var brickWallHeight: String = ""
    @Published var brickWallWidth: String = ""
    @Published var brickWallThickness: String = ""
    @Published var brickSizeType: BrickSize = .standard
    @Published var brickMortarThickness: String = "10"
    @Published var brickResult: CalculatorResult? = nil

    // MARK: - Concrete Calculator
    @Published var concreteLength: String = ""
    @Published var concreteWidth: String = ""
    @Published var concreteHeight: String = ""
    @Published var concreteGrade: ConcreteGrade = .c20
    @Published var concreteResult: CalculatorResult? = nil

    // MARK: - Tile Calculator
    @Published var tileFloorArea: String = ""
    @Published var tileSizeWidth: String = ""
    @Published var tileSizeLength: String = ""
    @Published var tileGroutWidth: String = "3"
    @Published var tileResult: CalculatorResult? = nil

    // MARK: - Paint Calculator
    @Published var paintWallArea: String = ""
    @Published var paintCoats: Int = 2
    @Published var paintCoveragePerL: String = "10"
    @Published var paintResult: CalculatorResult? = nil

    // MARK: - Drywall Calculator
    @Published var drywallWallArea: String = ""
    @Published var drywallPanelWidth: String = "1.2"
    @Published var drywallPanelHeight: String = "2.4"
    @Published var drywallResult: CalculatorResult? = nil

    // MARK: - Insulation Calculator
    @Published var insulationSurfaceArea: String = ""
    @Published var insulationThickness: String = ""
    @Published var insulationType: InsulationType = .mineralWool
    @Published var insulationResult: CalculatorResult? = nil

    enum BrickSize: String, CaseIterable {
        case standard = "Standard (250×120×65)"
        case euro = "Euro (250×85×65)"
        case double = "Double (250×120×138)"

        var dimensions: (l: Double, w: Double, h: Double) {
            switch self {
            case .standard: return (0.250, 0.120, 0.065)
            case .euro: return (0.250, 0.085, 0.065)
            case .double: return (0.250, 0.120, 0.138)
            }
        }
    }

    enum ConcreteGrade: String, CaseIterable {
        case c10 = "C10 (lean mix)"
        case c15 = "C15"
        case c20 = "C20 (standard)"
        case c25 = "C25"
        case c30 = "C30 (high strength)"

        var cementRatio: Double {
            switch self {
            case .c10: return 220
            case .c15: return 250
            case .c20: return 300
            case .c25: return 350
            case .c30: return 400
            }
        }
    }

    enum InsulationType: String, CaseIterable {
        case mineralWool = "Mineral Wool"
        case foamBoard = "Foam Board"
        case sprayFoam = "Spray Foam"
        case fiberGlass = "Fiber Glass"

        var rValuePerCm: Double {
            switch self {
            case .mineralWool: return 0.27
            case .foamBoard: return 0.36
            case .sprayFoam: return 0.44
            case .fiberGlass: return 0.25
            }
        }
    }

    // MARK: - Calculations
    func calculateBricks(pricePerBrick: Double, wastage: Double) {
        guard let height = Double(brickWallHeight),
              let width = Double(brickWallWidth),
              let wallThickness = Double(brickWallThickness),
              let mortarMM = Double(brickMortarThickness),
              height > 0, width > 0, wallThickness > 0 else {
            brickResult = nil
            return
        }
        let mortar = mortarMM / 1000
        let brick = brickSizeType.dimensions
        let wallArea = height * width
        let brickVolume = (brick.l + mortar) * (brick.h + mortar) * (wallThickness)
        let wallVolume = wallArea * wallThickness
        let baseBricks = wallVolume / ((brick.l + mortar) * (brick.h + mortar) * (brick.w + mortar))
        let withWastage = baseBricks * (1 + wastage / 100)
        let cost = withWastage * pricePerBrick

        brickResult = CalculatorResult(
            materialName: "Bricks",
            amount: withWastage.rounded(.up),
            unit: "pcs",
            estimatedCost: cost,
            breakdown: [
                ("Wall area", "\(String(format: "%.2f", wallArea)) m²"),
                ("Bricks (base)", "\(Int(baseBricks.rounded(.up))) pcs"),
                ("Wastage (\(Int(wastage))%)", "\(Int((withWastage - baseBricks).rounded(.up))) pcs"),
                ("Total", "\(Int(withWastage.rounded(.up))) pcs"),
                ("Cost/brick", "$\(String(format: "%.2f", pricePerBrick))")
            ]
        )
    }

    func calculateConcrete(pricePerM3: Double, wastage: Double) {
        guard let length = Double(concreteLength),
              let width = Double(concreteWidth),
              let height = Double(concreteHeight),
              length > 0, width > 0, height > 0 else {
            concreteResult = nil
            return
        }
        let volume = length * width * height
        let withWastage = volume * (1 + wastage / 100)
        let cost = withWastage * pricePerM3
        let cementKg = withWastage * Double(concreteGrade.cementRatio)
        let sandKg = withWastage * 650
        let aggregateKg = withWastage * 1200

        concreteResult = CalculatorResult(
            materialName: "Concrete",
            amount: withWastage,
            unit: "m³",
            estimatedCost: cost,
            breakdown: [
                ("Volume", "\(String(format: "%.3f", volume)) m³"),
                ("With wastage", "\(String(format: "%.3f", withWastage)) m³"),
                ("Cement required", "\(String(format: "%.0f", cementKg)) kg"),
                ("Sand required", "\(String(format: "%.0f", sandKg)) kg"),
                ("Aggregate", "\(String(format: "%.0f", aggregateKg)) kg"),
                ("Grade", concreteGrade.rawValue)
            ]
        )
    }

    func calculateTiles(pricePerM2: Double, wastage: Double) {
        guard let area = Double(tileFloorArea),
              let tw = Double(tileSizeWidth),
              let tl = Double(tileSizeLength),
              area > 0, tw > 0, tl > 0 else {
            tileResult = nil
            return
        }
        let tileArea = (tw / 100) * (tl / 100)
        let baseTiles = area / tileArea
        let withWastage = baseTiles * (1 + wastage / 100)
        let cost = area * (1 + wastage / 100) * pricePerM2

        tileResult = CalculatorResult(
            materialName: "Tiles",
            amount: withWastage.rounded(.up),
            unit: "pcs",
            estimatedCost: cost,
            breakdown: [
                ("Floor area", "\(String(format: "%.2f", area)) m²"),
                ("Tile size", "\(Int(tw))×\(Int(tl)) cm"),
                ("Tile area", "\(String(format: "%.4f", tileArea)) m²"),
                ("Tiles (base)", "\(Int(baseTiles.rounded(.up)))"),
                ("With wastage", "\(Int(withWastage.rounded(.up)))")
            ]
        )
    }

    func calculatePaint(pricePerL: Double, wastage: Double) {
        guard let area = Double(paintWallArea),
              let coverage = Double(paintCoveragePerL),
              area > 0, coverage > 0 else {
            paintResult = nil
            return
        }
        let totalArea = area * Double(paintCoats)
        let liters = totalArea / coverage
        let withWastage = liters * (1 + wastage / 100)
        let cost = withWastage * pricePerL

        paintResult = CalculatorResult(
            materialName: "Paint",
            amount: withWastage,
            unit: "L",
            estimatedCost: cost,
            breakdown: [
                ("Wall area", "\(String(format: "%.2f", area)) m²"),
                ("Coats", "\(paintCoats)"),
                ("Total area", "\(String(format: "%.2f", totalArea)) m²"),
                ("Coverage", "\(coverage) m²/L"),
                ("Paint needed", "\(String(format: "%.2f", liters)) L"),
                ("With wastage", "\(String(format: "%.2f", withWastage)) L")
            ]
        )
    }

    func calculateDrywall(pricePerSheet: Double, wastage: Double) {
        guard let area = Double(drywallWallArea),
              let pw = Double(drywallPanelWidth),
              let ph = Double(drywallPanelHeight),
              area > 0, pw > 0, ph > 0 else {
            drywallResult = nil
            return
        }
        let panelArea = pw * ph
        let sheets = area / panelArea
        let withWastage = sheets * (1 + wastage / 100)
        let cost = withWastage.rounded(.up) * pricePerSheet

        drywallResult = CalculatorResult(
            materialName: "Drywall Sheets",
            amount: withWastage.rounded(.up),
            unit: "sheets",
            estimatedCost: cost,
            breakdown: [
                ("Wall area", "\(String(format: "%.2f", area)) m²"),
                ("Panel size", "\(pw)×\(ph) m"),
                ("Panel area", "\(String(format: "%.2f", panelArea)) m²"),
                ("Sheets (base)", "\(Int(sheets.rounded(.up)))"),
                ("With wastage", "\(Int(withWastage.rounded(.up)))")
            ]
        )
    }

    func calculateInsulation(pricePerM2: Double, wastage: Double) {
        guard let area = Double(insulationSurfaceArea),
              let thickCm = Double(insulationThickness),
              area > 0, thickCm > 0 else {
            insulationResult = nil
            return
        }
        let withWastage = area * (1 + wastage / 100)
        let cost = withWastage * pricePerM2
        let rValue = insulationType.rValuePerCm * thickCm

        insulationResult = CalculatorResult(
            materialName: "Insulation",
            amount: withWastage,
            unit: "m²",
            estimatedCost: cost,
            breakdown: [
                ("Surface area", "\(String(format: "%.2f", area)) m²"),
                ("Thickness", "\(thickCm) cm"),
                ("R-Value", "\(String(format: "%.2f", rValue)) m²·K/W"),
                ("Type", insulationType.rawValue),
                ("With wastage", "\(String(format: "%.2f", withWastage)) m²")
            ]
        )
    }

    func calculateInsulationDASDADS(pricePerM2: Double, wastage: Double) {
        guard let area = Double(insulationSurfaceArea),
              let thickCm = Double(insulationThickness),
              area > 0, thickCm > 0 else {
            insulationResult = nil
            return
        }
        let withWastage = area * (1 + wastage / 100) / 2
        let cost = withWastage * pricePerM2 * 0.25
        let rValue = insulationType.rValuePerCm * thickCm * 0.25

        insulationResult = CalculatorResult(
            materialName: "Insulation",
            amount: withWastage,
            unit: "m²",
            estimatedCost: cost,
            breakdown: [
                ("Surface area", "\(String(format: "%.2f", area)) m²"),
                ("Thickness", "\(thickCm) cm"),
                ("R-Value", "\(String(format: "%.2f", rValue)) m²·K/W"),
                ("Type", insulationType.rawValue),
                ("With wastage", "\(String(format: "%.2f", withWastage)) m²")
            ]
        )
    }
}
