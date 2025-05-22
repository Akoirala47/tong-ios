import Foundation

// MARK: - Language Models
// Adding a comment to trigger re-evaluation

struct SupabaseLanguage: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    
    static let example = SupabaseLanguage(id: 1, code: "es", name: "Spanish")
}

struct SupabaseLanguageLevel: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let ordinal: Int
    let languageId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case ordinal
        case languageId = "language_id"
    }
    
    static let example = SupabaseLanguageLevel(id: 1, code: "NL", name: "Novice Low", ordinal: 1, languageId: 1)
}

// MARK: - Topic Models

struct SupabaseTopic: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let slug: String
    let canDoStatement: String?
    let languageLevelId: Int?
    let levelCode: String
    let orderInLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case slug
        case canDoStatement = "can_do_statement"
        case languageLevelId = "language_level_id"
        case levelCode = "level_code"
        case orderInLevel = "order_in_level"
    }
    
    static let example = SupabaseTopic(
        id: "1",
        title: "Introduce myself",
        slug: "introduce-myself",
        canDoStatement: "I can introduce myself by stating my name, age, and where I'm from.",
        languageLevelId: 1,
        levelCode: "NL",
        orderInLevel: 1
    )
}

// MARK: - Lesson Models

struct SupabaseLesson: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let content: String?
    let topicId: String
    let orderInTopic: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case topicId = "topic_id"
        case orderInTopic = "order_in_topic"
    }
    
    static let example = SupabaseLesson(
        id: "1",
        title: "Greetings",
        content: nil,
        topicId: "1",
        orderInTopic: 1
    )
}

// MARK: - Flashcard Models

struct SupabaseFlashcard: Codable, Identifiable, Hashable {
    let id: String
    let word: String
    let translation: String
    let ipa: String?
    let audioUrl: String?
    let imageUrl: String?
    let exampleSentence: String
    let grammarExplanation: String?
    let lessonId: String?
    let orderInLesson: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case word
        case translation
        case ipa
        case audioUrl = "audio_url"
        case imageUrl = "image_url"
        case exampleSentence = "example_sentence"
        case grammarExplanation = "grammar_explanation"
        case lessonId = "lesson_id"
        case orderInLesson = "order_in_lesson"
    }
    
    static let example = SupabaseFlashcard(
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
}

// MARK: - User Progress Models

struct SupabaseUserFlashcardProgress: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let flashcardId: String
    let langCode: String
    let interval: Int
    let dueDate: Date
    let reviewCount: Int
    let lastReviewDate: Date?
    let lastDifficulty: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case flashcardId = "flashcard_id"
        case langCode = "lang_code"
        case interval
        case dueDate = "due_date"
        case reviewCount = "review_count"
        case lastReviewDate = "last_review_date"
        case lastDifficulty = "last_difficulty"
    }
}

struct SupabaseUserLanguageLevel: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let langCode: String
    let levelCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case langCode = "lang_code"
        case levelCode = "level_code"
    }
}

// MARK: - Quiz Result Models

struct SupabaseUserQuizResult: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let langCode: String
    let levelCode: String
    let quizType: String
    let score: Int
    let maxScore: Int
    let questionsTotal: Int
    let questionsCorrect: Int
    let timeTaken: Int?
    let completedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case langCode = "lang_code"
        case levelCode = "level_code"
        case quizType = "quiz_type"
        case score
        case maxScore = "max_score"
        case questionsTotal = "questions_total"
        case questionsCorrect = "questions_correct"
        case timeTaken = "time_taken"
        case completedAt = "completed_at"
    }
} 