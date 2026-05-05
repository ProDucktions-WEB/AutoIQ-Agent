import XCTest
@testable import AutoIQ

final class BehavioralSignalTests: XCTestCase {

    func testSignalCreation() {
        let signal = BehavioralSignal(
            signalType: .swipeRight,
            sessionId: "session_123"
        )
        XCTAssertEqual(signal.signalType, .swipeRight)
        XCTAssertEqual(signal.sessionId, "session_123")
        XCTAssertNil(signal.carSnapshot)
    }

    func testCarSnapshot() {
        let snapshot = BehavioralSignal.CarSnapshot(
            id: "car_456",
            marca: "Toyota",
            modelo: "Corolla",
            año: 2022,
            precio: 45_000_000,
            tipo: "sedan",
            combustible: "gasolina",
            transmision: "automática",
            nivelLujo: "estándar"
        )
        XCTAssertEqual(snapshot.marca, "Toyota")
        XCTAssertEqual(snapshot.modelo, "Corolla")
        XCTAssertEqual(snapshot.año, 2022)
        XCTAssertEqual(snapshot.precio, 45_000_000)
    }

    func testFilterState() {
        let filter = BehavioralSignal.FilterState(
            precioMin: 20_000_000,
            precioMax: 80_000_000,
            tiposSeleccionados: ["sedan", "suv"],
            ciudadesSeleccionadas: ["Bogotá", "Medellín"]
        )
        XCTAssertEqual(filter.precioMin, 20_000_000)
        XCTAssertEqual(filter.precioMax, 80_000_000)
        XCTAssertEqual(filter.tiposSeleccionados.count, 2)
        XCTAssertEqual(filter.ciudadesSeleccionadas.count, 2)
    }

    func testSignalTypes() {
        let types: [BehavioralSignal.SignalType] = [
            .swipeRight, .swipeLeftFast, .swipeLeftSlow, .swipeUp,
            .dwellPhoto, .dwellSpecs, .dwellPrice,
            .compareAction, .repeatedView, .saveAction, .contactAction,
            .chatMessage, .filterChange
        ]
        XCTAssertEqual(types.count, 13)
    }

    func testSignalCodable() throws {
        let signal = BehavioralSignal(
            signalType: .swipeRight,
            sessionId: "session_123"
        )
        let data = try JSONEncoder().encode(signal)
        let decoded = try JSONDecoder().decode(BehavioralSignal.self, from: data)
        XCTAssertEqual(decoded.signalType, signal.signalType)
        XCTAssertEqual(decoded.sessionId, signal.sessionId)
    }

    func testDwellTimeDifferentiation() {
        let fastSwipe = BehavioralSignal(
            signalType: .swipeLeftFast,
            sessionId: "s1",
            dwellDurationSeconds: 0.8
        )
        let slowSwipe = BehavioralSignal(
            signalType: .swipeLeftSlow,
            sessionId: "s2",
            dwellDurationSeconds: 4.5
        )
        XCTAssertLess(fastSwipe.dwellDurationSeconds ?? 0, 1.5)
        XCTAssertGreater(slowSwipe.dwellDurationSeconds ?? 0, 3.0)
    }
}
