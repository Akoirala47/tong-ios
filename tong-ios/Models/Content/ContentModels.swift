import Foundation

// MARK: - Content Models
public enum ContentModels {
    /// Represents a language learning card (flashcard)
    public struct Card: Identifiable, Codable, Hashable {
        public let id: UUID
        public let word: String
        public let translation: String
        public let ipa: String?
        public let audioURL: String?
        public let imageURL: String?
        public let exampleSentence: String
        public let grammarExplanation: String?
        public let orderInLesson: Int
        
        public init(
            id: UUID, 
            word: String, 
            translation: String, 
            ipa: String?, 
            audioURL: String? = nil, 
            imageURL: String? = nil, 
            exampleSentence: String, 
            grammarExplanation: String? = nil,
            orderInLesson: Int
        ) {
            self.id = id
            self.word = word
            self.translation = translation
            self.ipa = ipa
            self.audioURL = audioURL
            self.imageURL = imageURL
            self.exampleSentence = exampleSentence
            self.grammarExplanation = grammarExplanation
            self.orderInLesson = orderInLesson
        }
    }

    /// Represents a language learning lesson
    public struct Lesson: Identifiable, Codable, Hashable {
        public let id: UUID
        public let slug: String
        public let title: String
        public let objective: String
        public let orderInTopic: Int
        public let content: String?
        public let cards: [Card]
        
        public init(
            id: UUID, 
            slug: String, 
            title: String, 
            objective: String, 
            orderInTopic: Int, 
            content: String? = nil, 
            cards: [Card]
        ) {
            self.id = id
            self.slug = slug
            self.title = title
            self.objective = objective
            self.orderInTopic = orderInTopic
            self.content = content
            self.cards = cards
        }
    }

    /// Represents a collection of lessons focused on an ACTFL Can-Do statement
    public struct Topic: Identifiable, Codable, Hashable {
        public let id: UUID
        public let slug: String
        public let title: String
        public let canDoStatement: String
        public let levelCode: String
        public let langCode: String
        public let lessons: [Lesson]
        
        public init(
            id: UUID, 
            slug: String, 
            title: String, 
            canDoStatement: String, 
            levelCode: String, 
            langCode: String,
            lessons: [Lesson]
        ) {
            self.id = id
            self.slug = slug
            self.title = title
            self.canDoStatement = canDoStatement
            self.levelCode = levelCode
            self.langCode = langCode
            self.lessons = lessons
        }
    }
}

/// Spanish content loader
class ESContentLoader {
    /// Get all Spanish topics for a specific level
    static func getTopics(levelCode: String) -> [ContentModels.Topic] {
        // Stub implementation - in a real app this would load from JSON or API
        let topicId = UUID()
        let lessonId = UUID()
        let cardId = UUID()
        
        // Create sample card
        let card = ContentModels.Card(
            id: cardId,
            word: "Hola",
            translation: "Hello",
            ipa: nil,
            audioURL: nil,
            imageURL: nil,
            exampleSentence: "¡Hola! ¿Cómo estás?",
            grammarExplanation: nil,
            orderInLesson: 1
        )
        
        // Create sample lesson with the card
        let lesson = ContentModels.Lesson(
            id: lessonId,
            slug: "greetings",
            title: "Greetings",
            objective: "Learn common Spanish greetings",
            orderInTopic: 1,
            content: "# Greetings in Spanish\n\nIn this lesson, you'll learn common Spanish greetings.",
            cards: [card]
        )
        
        // Create sample topic with the lesson
        let topic = ContentModels.Topic(
            id: topicId,
            slug: "introduce-myself",
            title: "Introduce Myself",
            canDoStatement: "I can introduce myself by stating my name, age, and where I'm from.",
            levelCode: levelCode,
            langCode: "es",
            lessons: [lesson]
        )
        
        return [topic]
    }
    
    /// Get all lessons for a specific topic
    static func getLessons(topicId: UUID) -> [ContentModels.Lesson] {
        // Return the lessons from the topic
        let topics = getTopics(levelCode: "NL")
        return topics.first(where: { $0.id == topicId })?.lessons ?? []
    }
    
    /// Get a specific lesson by ID
    static func getLesson(lessonId: UUID) -> ContentModels.Lesson? {
        // Search for the lesson in all topics
        let topics = getTopics(levelCode: "NL")
        for topic in topics {
            if let lesson = topic.lessons.first(where: { $0.id == lessonId }) {
                return lesson
            }
        }
        return nil
    }
    
    /// Get all cards for a specific lesson
    static func getCards(lessonId: UUID) -> [ContentModels.Card] {
        // Return the cards from the lesson
        if let lesson = getLesson(lessonId: lessonId) {
            return lesson.cards
        }
        return []
    }
}

/// Repository for accessing content
public class ContentRepository {
    
    public static let shared = ContentRepository()
    
    private init() {}
    
    /// Get all topics for a specific language and level
    public func getTopics(langCode: String, levelCode: String) -> [ContentModels.Topic] {
        switch langCode.lowercased() {
        case "es":
            return getSpanishTopics(levelCode: levelCode)
        case "fr":
            return []  // Not implemented yet
        case "jp":
            return []  // Not implemented yet
        case "zh":
            return []  // Not implemented yet
        default:
            return []
        }
    }
    
    /// Get all Spanish topics for a specific level
    private func getSpanishTopics(levelCode: String) -> [ContentModels.Topic] {
        // Use the ESContentLoader to load Spanish content from JSON
        return ESContentLoader.getTopics(levelCode: levelCode)
    }
    
    /// Get all lessons for a specific topic
    public func getLessons(topicId: UUID) -> [ContentModels.Lesson] {
        // First check Spanish content using ESContentLoader
        let spanishLessons = ESContentLoader.getLessons(topicId: topicId)
        if !spanishLessons.isEmpty {
            return spanishLessons
        }
        
        // Fall back to checking other languages (when implemented)
        let languages = ["fr", "jp", "zh"]
        let levels = ["NL", "NM", "NH", "IL", "IM", "IH", "AL", "AM", "AH", "S"]
        
        for lang in languages {
            for level in levels {
                let topics = getTopics(langCode: lang, levelCode: level)
                if let topic = topics.first(where: { $0.id == topicId }) {
                    return topic.lessons
                }
            }
        }
        
        return []
    }
    
    /// Get a specific lesson by ID
    public func getLesson(lessonId: UUID) -> ContentModels.Lesson? {
        // First check Spanish content using ESContentLoader
        if let spanishLesson = ESContentLoader.getLesson(lessonId: lessonId) {
            return spanishLesson
        }
        
        // Fall back to checking other languages (when implemented)
        let languages = ["fr", "jp", "zh"]
        let levels = ["NL", "NM", "NH", "IL", "IM", "IH", "AL", "AM", "AH", "S"]
        
        for lang in languages {
            for level in levels {
                let topics = getTopics(langCode: lang, levelCode: level)
                for topic in topics {
                    if let lesson = topic.lessons.first(where: { $0.id == lessonId }) {
                        return lesson
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Get all cards for a specific lesson
    public func getCards(lessonId: UUID) -> [ContentModels.Card] {
        // First check Spanish content using ESContentLoader
        let spanishCards = ESContentLoader.getCards(lessonId: lessonId)
        if !spanishCards.isEmpty {
            return spanishCards
        }
        
        // Fall back to the standard implementation if needed
        guard let lesson = getLesson(lessonId: lessonId) else {
            return []
        }
        
        return lesson.cards
    }
} 