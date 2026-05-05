import Foundation

/// Represents a user interaction event in the app.
/// Every tap, swipe, and dwell duration is a signal that reveals preference.
public struct BehavioralSignal: Codable {
    public let signalType: SignalType
    public let timestamp: Date
    public let sessionId: String
    public let carSnapshot: CarSnapshot?
    public let dwellDurationSeconds: Double?
    public let filterState: FilterState?

    public init(
        signalType: SignalType,
        timestamp: Date = Date(),
        sessionId: String,
        carSnapshot: CarSnapshot? = nil,
        dwellDurationSeconds: Double? = nil,
        filterState: FilterState? = nil
    ) {
        self.signalType = signalType
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.carSnapshot = carSnapshot
        self.dwellDurationSeconds = dwellDurationSeconds
        self.filterState = filterState
    }

    public enum SignalType: String, Codable {
        case swipeRight      = "swipe_right"
        case swipeLeftFast   = "swipe_left_fast"
        case swipeLeftSlow   = "swipe_left_slow"
        case swipeUp         = "swipe_up"
        case dwellPhoto      = "dwell_photo"
        case dwellSpecs      = "dwell_specs"
        case dwellPrice      = "dwell_price"
        case compareAction   = "compare_action"
        case repeatedView    = "repeated_view"
        case saveAction      = "save_action"
        case contactAction   = "contact_action"
        case chatMessage     = "chat_message"
        case filterChange    = "filter_change"
    }

    public struct CarSnapshot: Codable {
        public let id: String
        public let marca: String
        public let modelo: String
        public let año: Int
        public let precio: Double
        public let tipo: String
        public let combustible: String
        public let transmision: String
        public let nivelLujo: String

        public init(
            id: String,
            marca: String,
            modelo: String,
            año: Int,
            precio: Double,
            tipo: String,
            combustible: String,
            transmision: String,
            nivelLujo: String
        ) {
            self.id = id
            self.marca = marca
            self.modelo = modelo
            self.año = año
            self.precio = precio
            self.tipo = tipo
            self.combustible = combustible
            self.transmision = transmision
            self.nivelLujo = nivelLujo
        }
    }

    public struct FilterState: Codable {
        public let precioMin: Double?
        public let precioMax: Double?
        public let tiposSeleccionados: [String]
        public let ciudadesSeleccionadas: [String]
        public let añoMin: Int?
        public let añoMax: Int?

        public init(
            precioMin: Double? = nil,
            precioMax: Double? = nil,
            tiposSeleccionados: [String] = [],
            ciudadesSeleccionadas: [String] = [],
            añoMin: Int? = nil,
            añoMax: Int? = nil
        ) {
            self.precioMin = precioMin
            self.precioMax = precioMax
            self.tiposSeleccionados = tiposSeleccionados
            self.ciudadesSeleccionadas = ciudadesSeleccionadas
            self.añoMin = añoMin
            self.añoMax = añoMax
        }
    }
}
