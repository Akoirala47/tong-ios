import Foundation

// This file contains language level-related utility functions
// We use the LanguageLevel model from SupabaseModels.swift // This comment is slightly outdated, refers to SupabaseLanguageLevel

extension String {
    // Convert language level code to a human-readable name
    func toLanguageLevelName() -> String {
        switch self {
        case "NL": return "Novice Low"
        case "NM": return "Novice Mid"
        case "NH": return "Novice High"
        case "IL": return "Intermediate Low"
        case "IM": return "Intermediate Mid"
        case "IH": return "Intermediate High"
        case "AL": return "Advanced Low"
        case "AM": return "Advanced Mid"
        case "AH": return "Advanced High"
        case "S": return "Superior"
        default: return self
        }
    }
}

// Extension to add functionality to LanguageLevel model
extension SupabaseLanguageLevel { // This was already correctly SupabaseLanguageLevel
    // Get the next level in the standard progression
    func getNextLevel() -> String? {
        let levelProgression = ["NL", "NM", "NH", "IL", "IM", "IH", "AL", "AM", "AH", "S"]
        guard let currentIndex = levelProgression.firstIndex(of: code),
              currentIndex < levelProgression.count - 1 else {
            return nil // Already at highest level
        }
        return levelProgression[currentIndex + 1]
    }
    
    // Calculate experience points needed for this level
    var xpRequired: Int {
        switch code {
        case "NL": return 100
        case "NM": return 300
        case "NH": return 600
        case "IL": return 1000
        case "IM": return 2000
        case "IH": return 3500
        case "AL": return 5000
        case "AM": return 7500
        case "AH": return 10000
        case "S": return 15000
        default: return 100
        }
    }
} 