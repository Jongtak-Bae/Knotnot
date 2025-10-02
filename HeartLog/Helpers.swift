import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // fallback to black
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: Calendar Extension
extension Calendar {
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        return self.startOfDay(for: date1) == self.startOfDay(for: date2)
    }
}


// MARK: Internsity
enum ConflictIntensity: Int, CaseIterable {
    case minor = 0
    case moderate = 1
    case severe = 2
    
    var displayName: String {
        switch self {
        case .minor:
            return NSLocalizedString("Minor", comment: "Minor conflict intensity")
        case .moderate:
            return NSLocalizedString("Moderate", comment: "Moderate conflict intensity")
        case .severe:
            return NSLocalizedString("Severe", comment: "Severe conflict intensity")
        }
    }
    
    var color: Color {
        switch self {
        case .minor: return Color(hex: "#FFC35D")
        case .moderate: return Color(hex: "#FF8D5D")
        case .severe: return Color(hex: "#E75DFF")
        }
    }
    
    // Convert to/from String for Core Data storage
    var stringValue: String {
        // Use English strings for Core Data storage to maintain compatibility
        switch self {
        case .minor: return "Minor"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
    
    init?(string: String?) {
        // Map English strings used in Core Data to enum cases
        switch string {
        case "Minor": self = .minor
        case "Moderate": self = .moderate
        case "Severe": self = .severe
        default: return nil
        }
    }
}
