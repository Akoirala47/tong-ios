import Foundation
import SwiftUI
import Combine

enum BossQuestionType: String {
    case multipleChoice = "Multiple Choice"
    case typing = "Typing"
    case ordering = "Ordering"
}

struct BossQuestion: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]
    let correctAnswer: String
    let level: String
    let type: BossQuestionType
    let image: UIImage?
    let points: Int
    
    init(
        text: String,
        options: [String],
        correctAnswer: String,
        level: String,
        type: BossQuestionType,
        image: UIImage? = nil
    ) {
        self.text = text
        self.options = options
        self.correctAnswer = correctAnswer
        self.level = level
        self.type = type
        self.image = image
        
        // Points are determined by level and question type
        let levelMultiplier: Int
        switch level {
        case "NL": levelMultiplier = 1
        case "NM": levelMultiplier = 2
        case "NH": levelMultiplier = 3
        case "IL": levelMultiplier = 4
        case "IM": levelMultiplier = 5
        case "IH": levelMultiplier = 6
        case "AL": levelMultiplier = 7
        case "AM": levelMultiplier = 8
        case "AH": levelMultiplier = 9
        case "S": levelMultiplier = 10
        default: levelMultiplier = 1
        }
        
        let typeMultiplier: Int
        switch type {
        case .multipleChoice: typeMultiplier = 5
        case .typing: typeMultiplier = 8
        case .ordering: typeMultiplier = 10
        }
        
        self.points = levelMultiplier * typeMultiplier
    }
}

class BossBattleViewModel: ObservableObject {
    @Published var questions: [BossQuestion] = []
    @Published var currentIndex = 0
    @Published var score = 0
    @Published var timeRemaining: TimeInterval = 180 // 3 minutes
    @Published var isLoading = true
    @Published var streakCount = 0
    @Published var correctAnswers = 0
    @Published var timeBonus = 0
    @Published var streakBonus = 0
    
    private var timer: Timer?
    private var contentRepo = ContentRepository.shared
    
    var currentQuestion: BossQuestion? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var isComplete: Bool {
        return currentIndex >= questions.count
    }
    
    var totalQuestions: Int {
        return questions.count
    }
    
    var maxPossibleScore: Int {
        return questions.reduce(0) { $0 + $1.points } + 100 // Base + max time/streak bonus
    }
    
    var passingScore: Int {
        return Int(Double(maxPossibleScore) * 0.7) // 70% to pass
    }
    
    func loadQuestions(userId: String, languageCode: String, levelCode: String) async {
        isLoading = true
        
        // Load flashcards from the content repository
        let topics = contentRepo.getTopics(langCode: languageCode, levelCode: levelCode)
        
        var generatedQuestions: [BossQuestion] = []
        
        // Generate questions from each topic
        for topic in topics {
            for lesson in topic.lessons {
                for card in lesson.cards {
                    // Multiple choice questions (forward and backward)
                    if let question = createMultipleChoiceQuestion(
                        card: card,
                        cards: flattenCards(topics: topics),
                        level: levelCode,
                        isForward: true
                    ) {
                        generatedQuestions.append(question)
                    }
                    
                    if let question = createMultipleChoiceQuestion(
                        card: card,
                        cards: flattenCards(topics: topics),
                        level: levelCode,
                        isForward: false
                    ) {
                        generatedQuestions.append(question)
                    }
                    
                    // Typing questions
                    if let question = createTypingQuestion(
                        card: card,
                        level: levelCode,
                        isForward: Bool.random()
                    ) {
                        generatedQuestions.append(question)
                    }
                }
                
                // Ordering questions for the whole lesson
                if let question = createOrderingQuestion(lesson: lesson, level: levelCode) {
                    generatedQuestions.append(question)
                }
            }
        }
        
        // Shuffle and take a subset
        generatedQuestions.shuffle()
        let selectedQuestions = Array(generatedQuestions.prefix(10))
        
        // Sort by difficulty (convert level codes to numeric values)
        let sortedQuestions = selectedQuestions.sorted { q1, q2 in
            let levelOrder = ["NL": 1, "NM": 2, "NH": 3, "IL": 4, "IM": 5, "IH": 6, "AL": 7, "AM": 8, "AH": 9, "S": 10]
            let order1 = levelOrder[q1.level] ?? 1
            let order2 = levelOrder[q2.level] ?? 1
            return order1 < order2
        }
        
        await MainActor.run {
            self.questions = sortedQuestions
            self.currentIndex = 0
            self.score = 0
            self.streakCount = 0
            self.correctAnswers = 0
            self.timeBonus = 0
            self.streakBonus = 0
            self.isLoading = false
        }
    }
    
    func startTimer() {
        timeRemaining = 180 // Reset to 3 minutes
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                // Time's up
                self.stopTimer()
                
                // Calculate final score
                self.calculateTimeBonus()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        
        // Calculate time bonus if there's time left
        calculateTimeBonus()
    }
    
    func submitAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        
        let normalizedUserAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrectAnswer = question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        let isCorrect: Bool
        
        switch question.type {
        case .multipleChoice:
            // Exact match for multiple choice
            isCorrect = normalizedUserAnswer == normalizedCorrectAnswer
            
        case .typing:
            // For typing, allow for minor typos
            isCorrect = normalizedUserAnswer == normalizedCorrectAnswer ||
                        normalizedUserAnswer.levenshteinDistance(to: normalizedCorrectAnswer) <= 2
            
        case .ordering:
            // For ordering, compare the sequence
            isCorrect = normalizedUserAnswer == normalizedCorrectAnswer
        }
        
        // Update score and streak
        if isCorrect {
            score += question.points
            streakCount += 1
            correctAnswers += 1
            
            // Streak bonus (max 5 streak)
            if streakCount >= 3 {
                let bonus = min(streakCount - 2, 5) * 5 // 5 points per streak level (max: 25)
                score += bonus
                streakBonus += bonus
            }
        } else {
            streakCount = 0
        }
        
        // Move to next question
        currentIndex += 1
    }
    
    private func calculateTimeBonus() {
        // Only award time bonus if there's time left
        if timeRemaining > 0 {
            // Convert to percentage of original time (180 seconds)
            let timePercentage = min(1.0, timeRemaining / 180.0)
            
            // Maximum 50 points for time bonus
            let bonus = Int(timePercentage * 50)
            
            // Only add the bonus once
            if timeBonus == 0 {
                score += bonus
                timeBonus = bonus
            }
        }
    }
    
    private func createMultipleChoiceQuestion(
        card: ContentModels.Card,
        cards: [ContentModels.Card],
        level: String,
        isForward: Bool
    ) -> BossQuestion? {
        let questionText: String
        let correctAnswer: String
        
        if isForward {
            // Foreign to native
            questionText = "What is the meaning of '\(card.word)'?"
            correctAnswer = card.translation
        } else {
            // Native to foreign
            questionText = "How do you say '\(card.translation)' in Spanish?"
            correctAnswer = card.word
        }
        
        // Create options (correct answer + 3 distractors)
        var options = [correctAnswer]
        
        // Get all possible options that are not the correct answer
        let possibleOptions = cards.filter { $0.id != card.id }.map { isForward ? $0.translation : $0.word }
        
        // Add 3 random options
        for option in possibleOptions.shuffled().prefix(3) {
            options.append(option)
        }
        
        // If we don't have enough options, add some generic ones
        while options.count < 4 {
            options.append("Option \(options.count)")
        }
        
        // Shuffle the options
        options.shuffle()
        
        return BossQuestion(
            text: questionText,
            options: options,
            correctAnswer: correctAnswer,
            level: level,
            type: .multipleChoice
        )
    }
    
    private func createTypingQuestion(
        card: ContentModels.Card,
        level: String,
        isForward: Bool
    ) -> BossQuestion? {
        let questionText: String
        let correctAnswer: String
        
        if isForward {
            // Foreign to native
            questionText = "Type the English translation of '\(card.word)':"
            correctAnswer = card.translation
        } else {
            // Native to foreign
            questionText = "Type the Spanish word for '\(card.translation)':"
            correctAnswer = card.word
        }
        
        return BossQuestion(
            text: questionText,
            options: [],
            correctAnswer: correctAnswer,
            level: level,
            type: .typing
        )
    }
    
    private func createOrderingQuestion(
        lesson: ContentModels.Lesson,
        level: String
    ) -> BossQuestion? {
        // Need at least 4 cards for a meaningful ordering question
        guard lesson.cards.count >= 4 else { return nil }
        
        // Take 4 random cards from the lesson
        let selectedCards = Array(lesson.cards.shuffled().prefix(4))
        
        let options = selectedCards.map { $0.word }
        let correctAnswer = options.joined(separator: ",")
        
        return BossQuestion(
            text: "Arrange these words in the correct order:",
            options: options.shuffled(),
            correctAnswer: correctAnswer,
            level: level,
            type: .ordering
        )
    }
    
    private func flattenCards(topics: [ContentModels.Topic]) -> [ContentModels.Card] {
        var allCards: [ContentModels.Card] = []
        
        for topic in topics {
            for lesson in topic.lessons {
                allCards.append(contentsOf: lesson.cards)
            }
        }
        
        return allCards
    }
} 