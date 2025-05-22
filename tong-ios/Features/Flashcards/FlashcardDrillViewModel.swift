import Foundation
import Supabase

// Import our Models module for access to SupabaseModels
import SwiftUI

// Forward declaration of SRSFeedback and SRSState
public enum SRSFeedback: Int {
    case hard = 1
    case good = 3
    case easy = 5
}

public struct SRSState: Codable {
    public var interval: Int // days
    public var easeFactor: Double
    public var repetitions: Int
    public var nextReviewDate: Date
    
    public init(interval: Int, easeFactor: Double, repetitions: Int, nextReviewDate: Date) {
        self.interval = interval
        self.easeFactor = easeFactor
        self.repetitions = repetitions
        self.nextReviewDate = nextReviewDate
    }
}

public struct SRSService {
    // Default ease factor for new cards
    public static let defaultEaseFactor: Double = 2.5

    public static func nextState(
        previous: SRSState?,
        feedback: SRSFeedback,
        currentDate: Date = Date()
    ) -> SRSState {
        var interval = 1
        var easeFactor = previous?.easeFactor ?? defaultEaseFactor
        var repetitions = (previous?.repetitions ?? 0) + 1

        if let prev = previous {
            // SM-2 algorithm
            easeFactor = max(1.3, prev.easeFactor + (0.1 - (5 - Double(feedback.rawValue)) * (0.08 + (5 - Double(feedback.rawValue)) * 0.02)))
            if feedback == .hard {
                repetitions = 0
                interval = 1
            } else if feedback == .good {
                interval = prev.interval == 1 ? 6 : Int(Double(prev.interval) * easeFactor)
            } else if feedback == .easy {
                interval = prev.interval == 1 ? 6 : Int(Double(prev.interval) * easeFactor * 1.3)
            }
        }
        let nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: currentDate)!
        return SRSState(interval: interval, easeFactor: easeFactor, repetitions: repetitions, nextReviewDate: nextReviewDate)
    }
}

// Add our own CardReview definition
struct FlashcardReview: Identifiable, Decodable {
    let id: Int
    let card_id: Int
    let user_id: String
    let next_review_date: String // ISO8601 string
    let interval: Int
    let ease_factor: Double
    let last_reviewed_at: String?
}

@MainActor
final class FlashcardDrillViewModel: ObservableObject {
    @Published var flashcards: [SupabaseFlashcard] = []
    @Published var cardReviews: [String: FlashcardReview] = [:] // card_id: FlashcardReview
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client

    var currentFlashcard: SupabaseFlashcard? {
        guard !flashcards.isEmpty, currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }

    var currentReview: FlashcardReview? {
        guard let card = currentFlashcard else { return nil }
        return cardReviews[card.id]
    }

    func fetchDueFlashcards(for userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Fetch due card_reviews for the user
            let today = ISO8601DateFormatter().string(from: Date())
            let reviews: [FlashcardReview] = try await client
                .from("card_reviews")
                .select()
                .eq("user_id", value: userId)
                .lte("next_review_date", value: today)
                .execute()
                .value

            // 2. Fetch the corresponding cards
            let cardIds = reviews.map { $0.card_id }
            guard !cardIds.isEmpty else {
                self.flashcards = []
                self.cardReviews = [:]
                isLoading = false
                return
            }
            
            let cards: [SupabaseFlashcard] = try await client
                .from("cards")
                .select()
                .in("id", values: cardIds)
                .execute()
                .value

            // 3. Map reviews by card_id for quick lookup
            var reviewDict: [String: FlashcardReview] = [:]
            for review in reviews {
                reviewDict[String(review.card_id)] = review
            }

            // 4. Update state
            self.flashcards = cards
            self.cardReviews = reviewDict
            self.currentIndex = 0
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func submitReview(feedback: SRSFeedback, userId: String) async {
        guard let _ = currentFlashcard,
              let review = currentReview else { return }

        // Build SRSState from CardReview
        let prevState = SRSState(
            interval: review.interval,
            easeFactor: review.ease_factor,
            repetitions: 1, // You can store repetitions in the DB if you want
            nextReviewDate: ISO8601DateFormatter().date(from: review.next_review_date) ?? Date()
        )
        let newState = SRSService.nextState(previous: prevState, feedback: feedback)

        do {
            // Update card_reviews in Supabase
            _ = try await client
                .from("card_reviews")
                .update([
                    "interval": String(newState.interval),
                    "ease_factor": String(newState.easeFactor),
                    "next_review_date": ISO8601DateFormatter().string(from: newState.nextReviewDate),
                    "last_reviewed_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: review.id)
                .execute()

            // Move to next card
            if currentIndex < flashcards.count - 1 {
                currentIndex += 1
            } else {
                // All done!
                // You can show a completion view or reset
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Preview Mock
    static func mockForPreview() -> FlashcardDrillViewModel {
        let viewModel = FlashcardDrillViewModel()
        let sampleCard1 = SupabaseFlashcard(
            id: "1", 
            word: "Hola", 
            translation: "Hello", 
            ipa: nil,
            audioUrl: nil, 
            imageUrl: nil,
            exampleSentence: "¡Hola! ¿Cómo estás?",
            grammarExplanation: nil,
            lessonId: "1",
            orderInLesson: 1
        )
        
        let sampleCard2 = SupabaseFlashcard(
            id: "2", 
            word: "Adiós", 
            translation: "Goodbye", 
            ipa: nil,
            audioUrl: nil, 
            imageUrl: nil,
            exampleSentence: "¡Adiós! Hasta luego.",
            grammarExplanation: nil,
            lessonId: "1",
            orderInLesson: 2
        )
        
        viewModel.flashcards = [sampleCard1, sampleCard2]
        
        let review1 = FlashcardReview(
            id: 1,
            card_id: 1,
            user_id: "preview-user",
            next_review_date: ISO8601DateFormatter().string(from: Date()),
            interval: 1,
            ease_factor: 2.5,
            last_reviewed_at: nil
        )
        let review2 = FlashcardReview(
            id: 2,
            card_id: 2,
            user_id: "preview-user",
            next_review_date: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)), // Tomorrow
            interval: 1,
            ease_factor: 2.5,
            last_reviewed_at: nil
        )
        viewModel.cardReviews = ["1": review1, "2": review2]
        viewModel.currentIndex = 0
        return viewModel
    }
}