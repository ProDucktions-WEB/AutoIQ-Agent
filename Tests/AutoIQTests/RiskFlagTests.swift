import XCTest
@testable import AutoIQ

final class RiskFlagTests: XCTestCase {

    func testRiskFlagCreation() {
        let flag = RiskFlag(
            riskType: "price_fraud",
            severity: .high,
            message: "El precio está muy por debajo del mercado",
            recommendedAction: "Evita este vehículo"
        )
        XCTAssertEqual(flag.riskType, "price_fraud")
        XCTAssertEqual(flag.severity, .high)
        XCTAssertNotNil(flag.id)
    }

    func testSeverityDisplay() {
        XCTAssertEqual(RiskFlag.Severity.low.displayColor, "yellow")
        XCTAssertEqual(RiskFlag.Severity.medium.displayColor, "orange")
        XCTAssertEqual(RiskFlag.Severity.high.displayColor, "red")
        XCTAssertEqual(RiskFlag.Severity.critical.displayColor, "red")
    }

    func testMultipleRiskFlags() {
        let flags = [
            RiskFlag(riskType: "vin_anomaly", severity: .medium, message: "VIN inconsistencia", recommendedAction: "Verificar"),
            RiskFlag(riskType: "flood_damage", severity: .critical, message: "Posible daño por agua", recommendedAction: "No comprar")
        ]
        XCTAssertEqual(flags.count, 2)
        XCTAssertNotEqual(flags[0].id, flags[1].id)
    }
}
