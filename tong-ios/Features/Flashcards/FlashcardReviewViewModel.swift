import Foundation
import Combine
import SwiftUI

@MainActor
class FlashcardReviewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var flashcards: [SupabaseFlashcard] = []
    @Published var currentCardIndex: Int = 0
    @Published var streak: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAnswer: Bool = false
    @Published var reviewComplete: Bool = false
    
    // MARK: - Computed Properties
    var currentCard: SupabaseFlashcard? {
        guard !flashcards.isEmpty, currentCardIndex < flashcards.count else { return nil }
        return flashcards[currentCardIndex]
    }
    
    var totalCards: Int {
        flashcards.count
    }
    
    var isReviewComplete: Bool {
        currentCardIndex >= totalCards && !flashcards.isEmpty
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var userId: String = "temp-user-id" // Should come from auth service
    private var langCode: String = "es" // Default to Spanish
    
    // Cache of card progress data to avoid redundant lookups
    private var progressCache: [String: (interval: Int, reviewCount: Int)] = [:]
    
    private var srs = SpacedRepetitionScheduler()
    private var currentLanguageCode: String? // Store current language
    
    // MARK: - Initialization
    init(langCode: String = "es") {
        self.langCode = langCode
        // In a real app, we would get the authenticated user ID here
    }
    
    // MARK: - Public Methods
    
    func loadFlashcards() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // First try to load due flashcards based on spaced repetition
                var cards = try await SupabaseService.shared.getDueFlashcards(for: userId, langCode: langCode)
                
                // If no cards are due, load some random ones from the first lesson
                if cards.isEmpty {
                    // Get the first level for this language
                    let languages = try await SupabaseService.shared.getLanguages()
                    if let language = languages.first(where: { $0.code == langCode }) {
                        let levels = try await SupabaseService.shared.getLanguageLevels(for: language.id)
                        if let firstLevel = levels.first {
                            let topics = try await SupabaseService.shared.getTopics(for: firstLevel.id)
                            if let firstTopic = topics.first, let topicId = Int(firstTopic.id) {
                                let lessons = try await SupabaseService.shared.getLessons(for: String(topicId))
                                if let firstLesson = lessons.first {
                                    cards = try await SupabaseService.shared.getFlashcards(for: firstLesson.id)
                                }
                            }
                        }
                    }
                    
                    // If still empty, fall back to sample data
                    if cards.isEmpty {
                        cards = sampleFlashcards
                    }
                }
                
                // Load progress data for each card
                for card in cards {
                    do {
                        let progress = try await SupabaseService.shared.getFlashcardProgress(userId: userId, flashcardId: card.id)
                        if let progress = progress {
                            progressCache[card.id] = (progress.interval, progress.reviewCount)
                        }
                    } catch {
                        print("Error loading progress for card \(card.id): \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.flashcards = cards
                    self.currentCardIndex = 0
                    self.streak = 0
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load flashcards: \(error.localizedDescription)"
                    self.isLoading = false
                    self.flashcards = sampleFlashcards // Fallback to samples on error
                }
                print("Error loading flashcards: \(error)")
            }
        }
    }
    
    func processAnswer(difficulty: CardDifficulty) {
        guard let currentCard = currentCard else { return }
        
        // Update streak
        if difficulty == .hard {
            streak = 0
        } else {
            streak += 1
        }
        
        // Get current progress from cache or use defaults
        let cachedProgress = progressCache[currentCard.id]
        let currentInterval = cachedProgress?.interval ?? 0
        let reviewCount = (cachedProgress?.reviewCount ?? 0) + 1
        
        // Calculate next review
        let nextReview = calculateNextReview(
            cardId: currentCard.id, 
            difficulty: difficulty,
            currentInterval: currentInterval, 
            reviewCount: reviewCount
        )
        
        // Update the cache
        progressCache[currentCard.id] = (nextReview.interval, reviewCount)
        
        // Update in Supabase
        Task {
            do {
                try await SupabaseService.shared.updateFlashcardProgress(
                    userId: userId,
                    flashcardId: currentCard.id,
                    langCode: langCode,
                    interval: nextReview.interval,
                    dueDate: nextReview.dueDate,
                    reviewCount: reviewCount,
                    lastDifficulty: difficulty.rawValue
                )
            } catch {
                print("Error updating flashcard progress: \(error)")
            }
        }
        
        // Move to the next card
        if currentCardIndex < flashcards.count {
            currentCardIndex += 1
        }
    }
    
    func resetReview() {
        currentCardIndex = 0
        streak = 0
        
        // Optionally shuffle the cards
        flashcards.shuffle()
    }
    
    func changeLanguage(to langCode: String) {
        self.langCode = langCode
        loadFlashcards()
    }
    
    // MARK: - SRS Algorithm Implementation
    
    func calculateNextReview(cardId: String, difficulty: CardDifficulty, 
                           currentInterval: Int = 0, reviewCount: Int = 0) -> (interval: Int, dueDate: Date) {
        // SM-2 Spaced Repetition Algorithm (simplified)
        // Reference: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
        
        let easeFactor = calculateEaseFactor(difficulty: difficulty, reviewCount: reviewCount)
        var newInterval = 0
        
        switch reviewCount {
        case 0:
            // First review
            newInterval = difficulty == .hard ? 1 : (difficulty == .good ? 1 : 2)
        case 1:
            // Second review
            newInterval = difficulty == .hard ? 3 : (difficulty == .good ? 4 : 5)
        default:
            // Calculate interval based on previous interval and ease factor
            let baseInterval = Double(currentInterval) * Double(difficulty.rawValue) * 0.5
            newInterval = max(1, Int(baseInterval))
        }
        
        // Calculate the due date (days from now)
        let dueDate = Calendar.current.date(byAdding: .day, value: newInterval, to: Date())!
        
        return (newInterval, dueDate)
    }
    
    private func calculateEaseFactor(difficulty: CardDifficulty, reviewCount: Int) -> Double {
        // SM-2 algorithm uses a base ease factor of 2.5
        // We adjust it based on difficulty and number of reviews
        let baseEaseFactor = 2.5
        
        // Adjust based on difficulty
        let difficultyAdjustment: Double
        switch difficulty {
        case .hard:
            difficultyAdjustment = -0.3
        case .good:
            difficultyAdjustment = 0.0
        case .easy:
            difficultyAdjustment = 0.15
        }
        
        // Apply smaller adjustments for cards with more reviews (stability)
        let reviewFactor = min(1.0, Double(reviewCount) / 10.0)
        let adjustedDifficultyFactor = difficultyAdjustment * (1.0 - reviewFactor * 0.5)
        
        // Calculate new ease factor with a minimum of 1.3
        let newEaseFactor = max(1.3, baseEaseFactor + adjustedDifficultyFactor)
        
        return newEaseFactor
    }
    
    // MARK: - Static func for SwiftUI Preview
    static func mockForPreview() -> FlashcardReviewViewModel {
        let viewModel = FlashcardReviewViewModel()
        viewModel.flashcards = [
            SupabaseFlashcard(
                id: "preview1",
                word: "Hola",
                translation: "Hello",
                ipa: "ˈo.la",
                audioUrl: nil,
                imageUrl: nil,
                exampleSentence: "¡Hola! ¿Cómo estás?",
                grammarExplanation: "A common greeting.",
                lessonId: "lesson1",
                orderInLesson: 1
            ),
            SupabaseFlashcard(
                id: "preview2",
                word: "Adiós",
                translation: "Goodbye",
                ipa: "aˈðjos",
                audioUrl: nil,
                imageUrl: nil,
                exampleSentence: "Adiós, amigo.",
                grammarExplanation: "A common farewell.",
                lessonId: "lesson1",
                orderInLesson: 2
            )
        ]
        viewModel.userId = "preview-user"
        viewModel.currentLanguageCode = "es"
        return viewModel
    }
}

// MARK: - Sample Data

let sampleFlashcards: [SupabaseFlashcard] = [
    SupabaseFlashcard(
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
    ),
    SupabaseFlashcard(
        id: "2",
        word: "Gracias",
        translation: "Thank you",
        ipa: nil,
        audioUrl: nil,
        imageUrl: nil,
        exampleSentence: "Muchas gracias por tu ayuda.",
        grammarExplanation: nil,
        lessonId: "1",
        orderInLesson: 2
    ),
    SupabaseFlashcard(
        id: "3",
        word: "Por favor",
        translation: "Please",
        ipa: nil,
        audioUrl: nil,
        imageUrl: nil,
        exampleSentence: "Por favor, pásame el libro.",
        grammarExplanation: nil,
        lessonId: "1",
        orderInLesson: 3
    ),
    SupabaseFlashcard(
        id: "4",
        word: "Quiero",
        translation: "I want",
        ipa: nil,
        audioUrl: nil,
        imageUrl: nil,
        exampleSentence: "Quiero aprender español.",
        grammarExplanation: "First person singular of 'querer'",
        lessonId: "1",
        orderInLesson: 4
    ),
    SupabaseFlashcard(
        id: "5",
        word: "Tengo",
        translation: "I have",
        ipa: nil,
        audioUrl: nil,
        imageUrl: nil,
        exampleSentence: "Tengo dos hermanos.",
        grammarExplanation: "First person singular of 'tener'",
        lessonId: "1",
        orderInLesson: 5
    )
] 