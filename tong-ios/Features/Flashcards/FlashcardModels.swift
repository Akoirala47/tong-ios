import Foundation

// UI-specific flashcard model for use in the Flashcards feature
struct UIFlashcard: Identifiable, Decodable {
    let id: String
    let word: String
    let translation: String
    let imageURL: String?
    let audioURL: String?
}

struct CardReview: Identifiable, Decodable {
    let id: Int
    let card_id: Int
    let user_id: String
    let next_review_date: String // ISO8601 string
    let interval: Int
    let ease_factor: Double
    let last_reviewed_at: String?
} 