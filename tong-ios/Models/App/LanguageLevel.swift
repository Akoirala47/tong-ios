import Foundation

/// Represents ACTFL proficiency levels.
enum LanguageLevel: String, CaseIterable, Codable, Hashable, Comparable {
    case noviceLow = "NL"
    case noviceMid = "NM"
    case noviceHigh = "NH"
    case intermediateLow = "IL"
    case intermediateMid = "IM"
    case intermediateHigh = "IH"
    case advancedLow = "AL"
    case advancedMid = "AM"
    case advancedHigh = "AH"
    case superior = "S"

    var fullName: String {
        switch self {
        case .noviceLow: return "Novice Low"
        case .noviceMid: return "Novice Mid"
        case .noviceHigh: return "Novice High"
        case .intermediateLow: return "Intermediate Low"
        case .intermediateMid: return "Intermediate Mid"
        case .intermediateHigh: return "Intermediate High"
        case .advancedLow: return "Advanced Low"
        case .advancedMid: return "Advanced Mid"
        case .advancedHigh: return "Advanced High"
        case .superior: return "Superior"
        }
    }

    // Comparable conformance based on progression
    static func < (lhs: LanguageLevel, rhs: LanguageLevel) -> Bool {
        guard let lhsIndex = LanguageLevel.allCases.firstIndex(of: lhs),
              let rhsIndex = LanguageLevel.allCases.firstIndex(of: rhs) else {
            return false // Should not happen if allCases is correct
        }
        return lhsIndex < rhsIndex
    }
} 