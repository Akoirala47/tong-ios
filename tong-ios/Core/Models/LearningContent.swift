import Foundation

// MARK: - Language Models

struct DBLanguage: Identifiable, Codable, Equatable {
    let id: Int
    let code: String
    let name: String
    
    static func == (lhs: DBLanguage, rhs: DBLanguage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DBLanguageLevel: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let languageId: Int
    let code: String
    let name: String
    let ordinal: Int
    let hoursTarget: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case languageId = "language_id"
        case code, name, ordinal
        case hoursTarget = "hours_target"
    }
    
    static func == (lhs: DBLanguageLevel, rhs: DBLanguageLevel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Topic and Lesson Models

struct DBTopic: Identifiable, Codable, Equatable {
    let id: Int
    let languageLevelId: Int
    let title: String
    let slug: String
    let canDoStatement: String
    let orderInLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case languageLevelId = "language_level_id"
        case title, slug
        case canDoStatement = "can_do_statement"
        case orderInLevel = "order_in_level"
    }
    
    static func == (lhs: DBTopic, rhs: DBTopic) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DBLesson: Identifiable, Codable, Equatable {
    let id: Int
    let topicId: Int
    let title: String
    let slug: String
    let objective: String
    let content: String
    let orderInTopic: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case topicId = "topic_id"
        case title, slug, objective, content
        case orderInTopic = "order_in_topic"
    }
    
    static func == (lhs: DBLesson, rhs: DBLesson) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Flashcard Models

struct DBFlashcard: Identifiable, Codable, Equatable {
    let id: Int
    let lessonId: Int
    let word: String
    let translation: String
    let ipa: String?
    let audioUrl: String?
    let imageUrl: String?
    let exampleSentence: String
    let grammarExplanation: String?
    let orderInLesson: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case lessonId = "lesson_id"
        case word, translation, ipa
        case audioUrl = "audio_url"
        case imageUrl = "image_url"
        case exampleSentence = "example_sentence"
        case grammarExplanation = "grammar_explanation"
        case orderInLesson = "order_in_lesson"
    }
    
    // Used for SRS progress tracking
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    var interval: Int = 0
    var easeFactor: Double = 2.5
    
    static func == (lhs: DBFlashcard, rhs: DBFlashcard) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Card Review Model

struct DBCardReview: Identifiable, Codable {
    let id: Int
    let cardId: Int
    let userId: String
    let nextReviewDate: Date
    let interval: Int
    let easeFactor: Double
    let lastReviewedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardId = "card_id"
        case userId = "user_id"
        case nextReviewDate = "next_review_date"
        case interval
        case easeFactor = "ease_factor"
        case lastReviewedAt = "last_reviewed_at"
    }
}

// MARK: - Response Models

struct LanguageResponse: Decodable {
    let data: [DBLanguage]?
    let error: SupabaseError?
}

struct LanguageLevelResponse: Decodable {
    let data: [DBLanguageLevel]?
    let error: SupabaseError?
}

struct TopicResponse: Decodable {
    let data: [DBTopic]?
    let error: SupabaseError?
}

struct LessonResponse: Decodable {
    let data: [DBLesson]?
    let error: SupabaseError?
}

struct FlashcardResponse: Decodable {
    let data: [DBFlashcard]?
    let error: SupabaseError?
}

struct CardReviewResponse: Decodable {
    let data: [DBCardReview]?
    let error: SupabaseError?
}

struct SupabaseError: Decodable {
    let message: String
} 