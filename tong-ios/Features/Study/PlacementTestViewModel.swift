import Foundation
import Combine

// A new struct to hold language level data with similar properties to the old enum
struct LevelData: Hashable {
    let code: String
    let name: String
    let order: Int
    
    // Properties for ProgressRingsView
    var shortName: String {
        // Example: Novice Low -> NL
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        } else if !name.isEmpty {
            return String(name.prefix(1))
        }
        return ""
    }

    var subcategory: String { // Simplified, assuming first word is category if two words
        let parts = name.split(separator: " ")
        return parts.count > 1 ? String(parts[1]) : ""
    }

    var color: String { // Example colors, replace with actual hex codes
        switch code {
        case "NL": return "FF5733" // Example: Orange
        case "NM": return "FF8C00" // Example: DarkOrange
        case "NH": return "FFA500" // Example: Orange
        case "IL": return "3498DB" // Example: Blue
        case "IM": return "2980B9" // Example: DarkBlue
        case "IH": return "1F618D" // Example: DarkerBlue
        case "AL": return "2ECC71" // Example: Green
        case "AM": return "27AE60" // Example: DarkGreen
        case "AH": return "1E8449" // Example: DarkerGreen
        case "S":  return "9B59B6" // Example: Purple
        default:   return "7F8C8D" // Example: Gray
        }
    }
    
    static let allCases: [LevelData] = [
        LevelData(code: "NL", name: "Novice Low", order: 0),
        LevelData(code: "NM", name: "Novice Mid", order: 1),
        LevelData(code: "NH", name: "Novice High", order: 2),
        LevelData(code: "IL", name: "Intermediate Low", order: 3),
        LevelData(code: "IM", name: "Intermediate Mid", order: 4),
        LevelData(code: "IH", name: "Intermediate High", order: 5),
        LevelData(code: "AL", name: "Advanced Low", order: 6),
        LevelData(code: "AM", name: "Advanced Mid", order: 7),
        LevelData(code: "AH", name: "Advanced High", order: 8),
        LevelData(code: "S", name: "Superior", order: 9)
    ]
    
    static func getLevel(forCode code: String) -> LevelData {
        return allCases.first { $0.code == code } ?? allCases[0]
    }
    
    static func getLevel(forOrder order: Int) -> LevelData {
        return allCases.first { $0.order == order } ?? allCases[0]
    }

    // Add Hashable conformance
    static func == (lhs: LevelData, rhs: LevelData) -> Bool {
        lhs.code == rhs.code
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

@MainActor
class PlacementTestViewModel: ObservableObject {
    @Published var questions: [PlacementQuestion] = []
    @Published var currentIndex = 0
    @Published var isLoading = true
    @Published var isTestComplete = false
    @Published var hasStarted = false
    @Published var selectedOptionIndex: Int?
    @Published var determinedLevel: LevelData?
    
    private var responseStartTime: Date?
    private var responses: [(questionIndex: Int, answerIndex: Int, isCorrect: Bool, responseTime: TimeInterval)] = []
    
    private let contentRepo = ContentRepository.shared
    
    var totalQuestions: Int {
        return min(questions.count, 12) // Cap at 12 questions
    }
    
    var currentQuestion: PlacementQuestion? {
        guard !questions.isEmpty, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var progressPercentage: Double {
        if totalQuestions == 0 { return 0.0 }
        return Double(currentIndex) / Double(totalQuestions)
    }
    
    var isLastQuestion: Bool {
        return currentIndex >= totalQuestions - 1
    }
    
    func loadQuestions(for languageCode: String) async {
        // These updates are fine as we are on @MainActor
        isLoading = true
        selectedOptionIndex = nil
        responses = []
        currentIndex = 0
        hasStarted = false
        
        // Capture languageCode for use in the detached task (it's Sendable)
        let taskLanguageCode = languageCode

        // Perform data loading and processing in a background task
        let loadedQuestions = await Task.detached { () -> [PlacementQuestion] in
            var allQuestions: [PlacementQuestion] = []
            let levels = LevelData.allCases
            
            // Access shared repository directly in the detached task
            let contentRepo = ContentRepository.shared

            for level in levels {
                // Assuming contentRepo.getTopics is safe to call from a background thread
                let topics = contentRepo.getTopics(langCode: taskLanguageCode, levelCode: level.code)
                
                for topic in topics {
                    for lesson in topic.lessons {
                        for card in lesson.cards {
                            // Call the static version of createQuestion
                            if let question = await PlacementTestViewModel.staticCreateQuestion(from: card, level: level, languageCode: taskLanguageCode) {
                                allQuestions.append(question)
                            }
                        }
                    }
                }
            }
            
            // If we don't have enough real content, create some placeholder questions
            if allQuestions.count < 12 {
                // Call the static version of createPlaceholderQuestions
                let placeholderQuestions = await PlacementTestViewModel.staticCreatePlaceholderQuestions(languageCode: taskLanguageCode)
                allQuestions.append(contentsOf: placeholderQuestions)
            }
            
            allQuestions.shuffle()
            return Array(allQuestions.prefix(12))
        }.value // Get the result of the detached task
        
        // Back on the MainActor (due to class being @MainActor) to update @Published properties
        self.questions = loadedQuestions.sorted { $0.difficulty < $1.difficulty }
        self.isLoading = false
    }
    
    func startTest() {
        hasStarted = true
        responseStartTime = Date()
    }
    
    func selectAnswer(at index: Int) {
        selectedOptionIndex = index
    }
    
    func nextQuestion() {
        guard let selectedIndex = selectedOptionIndex,
              let question = currentQuestion else { return }
        
        // Record response time
        let endTime = Date()
        let responseTime = responseStartTime?.distance(to: endTime) ?? 0
        
        // Record answer
        let isCorrect = selectedIndex == question.correctIndex
        responses.append((
            questionIndex: currentIndex,
            answerIndex: selectedIndex,
            isCorrect: isCorrect,
            responseTime: responseTime
        ))
        
        // Reset for next question
        selectedOptionIndex = nil
        
        if isLastQuestion {
            // Finish test
            finishTest()
        } else {
            // Move to next question
            currentIndex += 1
            responseStartTime = Date()
        }
    }
    
    func previousQuestion() {
        if currentIndex > 0 {
            currentIndex -= 1
            
            // Restore previous answer if available
            let previousResponse = responses.first(where: { $0.questionIndex == currentIndex })
            selectedOptionIndex = previousResponse?.answerIndex
            
            // Reset timer
            responseStartTime = Date()
        }
    }
    
    func finishTest() {
        // Calculate results and determine level
        let level = calculateLanguageLevel()
        determinedLevel = level
        isTestComplete = true
    }
    
    private func calculateLanguageLevel() -> LevelData {
        // Simple algorithm that weighs:
        // 1. Correctness of answers
        // 2. Speed of responses
        // 3. Level of questions answered correctly
        
        var totalScore = 0.0
        var maxPossibleScore = 0.0
        
        for response in responses {
            let question = questions[response.questionIndex]
            let levelWeight = Double(question.level.order + 1) // Weight by level (1-10)
            let difficultyWeight = Double(question.difficulty) / 10.0 // 0.1 to 1.0
            
            // Base points for the question
            let basePoints = levelWeight * difficultyWeight * 10.0
            maxPossibleScore += basePoints
            
            if response.isCorrect {
                // Calculate speed bonus (faster = more points)
                // Target time is 10 seconds, faster gets bonus, slower gets penalty
                let timeWeight = min(1.5, max(0.5, 10.0 / max(1.0, response.responseTime)))
                
                // Calculate total points
                let points = basePoints * timeWeight
                totalScore += points
            }
        }
        
        // Calculate percentage score
        let percentage = totalScore / max(1.0, maxPossibleScore)
        
        // Map percentage to language level
        return mapScoreToLevel(percentage)
    }
    
    private func mapScoreToLevel(_ percentage: Double) -> LevelData {
        // Simple mapping of score percentage to language level
        switch percentage {
        case 0.0..<0.15:
            return LevelData.getLevel(forCode: "NL")
        case 0.15..<0.25:
            return LevelData.getLevel(forCode: "NM")
        case 0.25..<0.35:
            return LevelData.getLevel(forCode: "NH")
        case 0.35..<0.45:
            return LevelData.getLevel(forCode: "IL")
        case 0.45..<0.55:
            return LevelData.getLevel(forCode: "IM")
        case 0.55..<0.65:
            return LevelData.getLevel(forCode: "IH")
        case 0.65..<0.75:
            return LevelData.getLevel(forCode: "AL")
        case 0.75..<0.85:
            return LevelData.getLevel(forCode: "AM")
        case 0.85..<0.95:
            return LevelData.getLevel(forCode: "AH")
        default:
            return LevelData.getLevel(forCode: "S")
        }
    }
    
    static func staticCreateQuestion(from card: ContentModels.Card, level: LevelData, languageCode: String) async -> PlacementQuestion? {
        // Create a multiple-choice question from a flashcard
        // A real implementation would have more sophisticated question generation
        
        guard !card.word.isEmpty, !card.translation.isEmpty else {
            return nil
        }
        
        let isForwardDirection = Bool.random() // Randomly choose direction
        let questionText: String
        let correctAnswer: String
        
        // Determine language name for the question string
        let targetLanguageName: String
        switch languageCode.lowercased() {
            case "es": targetLanguageName = "Spanish"
            case "fr": targetLanguageName = "French"
            // Add other languages as needed
            default: targetLanguageName = languageCode.capitalized
        }

        if isForwardDirection {
            questionText = "What is the meaning of '\(card.word)'?"
            correctAnswer = card.translation
        } else {
            questionText = "How do you say '\(card.translation)' in \(targetLanguageName)?"
            correctAnswer = card.word
        }
        
        // Create 3 incorrect options
        var options = [correctAnswer]
        
        // In a real app, you'd generate sensible distractors here
        // For now, we'll use placeholder wrong answers
        options.append(correctAnswer + " (wrong)")
        options.append("incorrect option")
        options.append("another incorrect option")
        
        options.shuffle()
        let correctIndex = options.firstIndex(of: correctAnswer) ?? 0
        
        return PlacementQuestion(
            text: questionText,
            options: options,
            correctIndex: correctIndex,
            level: level,
            difficulty: Int.random(in: 1...10) // Random difficulty for now
        )
    }
    
    static func staticCreatePlaceholderQuestions(languageCode: String) async -> [PlacementQuestion] {
        var placeholders: [PlacementQuestion] = []
        
        // Create placeholder questions with varying difficulties
        // In a real app, these would be curated assessment questions
        let levels: [LevelData] = [LevelData.getLevel(forCode: "NL"), LevelData.getLevel(forCode: "NM"), LevelData.getLevel(forCode: "NH"), LevelData.getLevel(forCode: "IL")]
        
        for level in levels {
            for i in 1...3 {
                let difficulty = (level.order * 2) + i
                
                let question = PlacementQuestion(
                    text: "Placeholder question #\(placeholders.count + 1) for \(level.name) (\(languageCode.uppercased()))",
                    options: [
                        "Correct answer",
                        "Wrong answer 1",
                        "Wrong answer 2",
                        "Wrong answer 3"
                    ],
                    correctIndex: 0,
                    level: level,
                    difficulty: min(10, difficulty)
                )
                
                placeholders.append(question)
            }
        }
        
        return placeholders
    }
} 
