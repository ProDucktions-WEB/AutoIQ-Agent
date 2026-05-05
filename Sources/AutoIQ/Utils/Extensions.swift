import Foundation

// MARK: - Number Formatting

public extension Int {
    /// Format number as Colombian Peso (COP) with proper locale.
    var formattedCOP: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_CO")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

public extension Double {
    /// Format number as Colombian Peso (COP) with proper locale.
    var formattedCOP: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_CO")
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
    }
}

// MARK: - Date Formatting

public extension Date {
    /// Format date in Colombian locale (dd/MM/yyyy).
    var formattedLocale: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "es_CO")
        return formatter.string(from: self)
    }
}

// MARK: - Archetype Display Names

public enum ArchetypeNames {
    public static func display(_ key: String) -> String {
        [
            "RATIONAL": "Racional",
            "ASPIRATIONAL": "Aspiracional",
            "FAMILY": "Familiar",
            "FIRST_TIME": "Primera vez",
            "UPGRADER": "Mejora",
            "INVESTOR": "Inversionista",
            "ECO": "Eco-consciente",
            "ADVENTURER": "Aventurero",
            "URBAN_COMMUTER": "Urbano"
        ][key] ?? key
    }
}
