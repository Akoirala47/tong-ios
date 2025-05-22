import Foundation

struct FlashcardProgress: Identifiable {
    var id: String
    var userId: String
    var flashcardId: String
    var languageCode: String
    var interval: Int
    var dueDate: Date
    var lastReviewDate: Date?
    var reviewCount: Int
    var lastDifficulty: CardDifficulty?
    
    // The associated flashcard 
    var flashcard: ContentModels.Card?
    
    var isNew: Bool {
        return reviewCount == 0
    }
    
    var isDue: Bool {
        return dueDate <= Date()
    }
    
    init(
        id: String,
        userId: String,
        flashcardId: String,
        languageCode: String,
        interval: Int,
        dueDate: Date,
        lastReviewDate: Date? = nil,
        reviewCount: Int = 0,
        lastDifficulty: CardDifficulty? = nil,
        flashcard: ContentModels.Card? = nil
    ) {
        self.id = id
        self.userId = userId
        self.flashcardId = flashcardId
        self.languageCode = languageCode
        self.interval = interval
        self.dueDate = dueDate
        self.lastReviewDate = lastReviewDate
        self.reviewCount = reviewCount
        self.lastDifficulty = lastDifficulty
        self.flashcard = flashcard
    }
    
    // Initialize from Supabase JSON response
    init?(json: [String: Any]) {
        guard 
            let id = json["id"] as? String,
            let userId = json["user_id"] as? String,
            let flashcardId = json["flashcard_id"] as? String,
            let languageCode = json["lang_code"] as? String,
            let interval = json["interval"] as? Int,
            let dueDateString = json["due_date"] as? String,
            let reviewCount = json["review_count"] as? Int
        else {
            return nil
        }
        
        let isoDateFormatter = ISO8601DateFormatter()
        
        guard let dueDate = isoDateFormatter.date(from: dueDateString) else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.flashcardId = flashcardId
        self.languageCode = languageCode
        self.interval = interval
        self.dueDate = dueDate
        self.reviewCount = reviewCount
        
        // Optional fields
        if let lastReviewDateString = json["last_review_date"] as? String {
            self.lastReviewDate = isoDateFormatter.date(from: lastReviewDateString)
        }
        
        if let difficultyRaw = json["last_difficulty"] as? Int {
            self.lastDifficulty = CardDifficulty(rawValue: difficultyRaw)
        }
        
        // Extract flashcard data if available
        if let flashcardJson = json["flashcard"] as? [String: Any],
           let id = flashcardJson["id"] as? String,
           let uuid = UUID(uuidString: id),
           let word = flashcardJson["word"] as? String,
           let translation = flashcardJson["translation"] as? String,
           let exampleSentence = flashcardJson["example_sentence"] as? String,
           let orderInLesson = flashcardJson["order_in_lesson"] as? Int {
            
            self.flashcard = ContentModels.Card(
                id: uuid,
                word: word,
                translation: translation,
                ipa: flashcardJson["ipa"] as? String,
                audioURL: flashcardJson["audio_url"] as? String,
                imageURL: flashcardJson["image_url"] as? String,
                exampleSentence: exampleSentence,
                grammarExplanation: flashcardJson["grammar_explanation"] as? String,
                orderInLesson: orderInLesson
            )
        }
    }
} 