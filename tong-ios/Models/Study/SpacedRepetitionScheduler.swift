import Foundation

// MARK: - SRS Algorithm Implementation
/// Implementation of the Supermemo 2 (SM-2) spaced repetition algorithm.
/// This is used to schedule flashcard reviews.
class SpacedRepetitionScheduler {
    
    // MARK: - Constants
    private static let minInterval = 1 // Minimum interval in days
    private static let defaultEaseFactor = 2.5 // Default ease factor for new cards
    private static let minEaseFactor = 1.3 // Minimum ease factor
    
    // MARK: - SRS Quality Assessment
    enum Quality: Int {
        case completelyForgotten = 0 // Completely forgot the answer
        case barelyRemembered = 1    // Remembered with significant difficulty
        case difficult = 2           // Remembered with difficulty
        case moderate = 3            // Remembered with moderate difficulty
        case easy = 4                // Remembered with little difficulty
        case perfect = 5             // Perfect recall
        
        /// Maps our simplified UI feedback to quality ratings
        static func fromDifficulty(_ difficulty: CardDifficulty) -> Quality {
            switch difficulty {
            case .hard:
                return .difficult
            case .good:
                return .moderate
            case .easy:
                return .perfect
            }
        }
    }
    
    // MARK: - Core Algorithm
    
    /// Calculate the next review interval for a card based on the SM-2 algorithm
    /// - Parameters:
    ///   - quality: The quality of the recall (0-5)
    ///   - currentInterval: The current interval in days (0 for new cards)
    ///   - currentEF: The current ease factor (2.5 for new cards)
    ///   - repetitions: Number of successful reviews in a row
    /// - Returns: A tuple containing the new interval, ease factor, and repetition count
    static func calculateNextReview(
        quality: Quality,
        currentInterval: Int = 0,
        currentEF: Double = defaultEaseFactor,
        repetitions: Int = 0
    ) -> (interval: Int, easeFactor: Double, repetitions: Int) {
        
        // Calculate new ease factor
        let q = Double(quality.rawValue)
        var newEF = currentEF + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
        newEF = max(minEaseFactor, newEF) // Ensure EF doesn't go below minimum
        
        // Calculate repetitions and interval
        var newRepetitions = repetitions
        var newInterval = currentInterval
        
        if quality.rawValue >= 3 {
            // Successful recall
            newRepetitions += 1
            
            if newRepetitions == 1 {
                newInterval = 1
            } else if newRepetitions == 2 {
                newInterval = 6
            } else {
                newInterval = Int(Double(currentInterval) * newEF)
            }
        } else {
            // Failed recall - reset repetitions
            newRepetitions = 0
            newInterval = 1
        }
        
        // Ensure minimum interval
        newInterval = max(minInterval, newInterval)
        
        return (newInterval, newEF, newRepetitions)
    }
    
    /// Calculates the next due date based on the current date and interval
    /// - Parameters:
    ///   - interval: The interval in days
    ///   - from: The date to calculate from (defaults to now)
    /// - Returns: The next due date
    static func calculateDueDate(interval: Int, from: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: interval, to: from) ?? from
    }
    
    // MARK: - Convenience Methods
    
    /// Process a card review with simplified difficulty feedback
    /// - Parameters:
    ///   - difficulty: Hard, Good, or Easy
    ///   - currentInterval: Current interval in days
    ///   - currentEF: Current ease factor
    ///   - repetitions: Current repetition count
    /// - Returns: Updated SRS state (interval, ease factor, repetitions, due date)
    static func processReview(
        difficulty: CardDifficulty,
        currentInterval: Int = 0,
        currentEF: Double = defaultEaseFactor,
        repetitions: Int = 0
    ) -> (interval: Int, easeFactor: Double, repetitions: Int, dueDate: Date) {
        
        let quality = Quality.fromDifficulty(difficulty)
        let (newInterval, newEF, newRepetitions) = calculateNextReview(
            quality: quality,
                    currentInterval: currentInterval,
            currentEF: currentEF,
            repetitions: repetitions
                )
                
        let dueDate = calculateDueDate(interval: newInterval)
        
        return (newInterval, newEF, newRepetitions, dueDate)
    }
}

// MARK: - Card Difficulty
/// Simplified difficulty rating for the user interface
enum CardDifficulty: Int {
    case hard = 1
    case good = 2
    case easy = 3
} 