import SwiftUI

enum BossBattleQuestionType {
    case multipleChoice
    case fillInBlank
    case matching
    case trueOrFalse
}

struct BossBattleView: View {
    let language: String // e.g., "Spanish"
    let level: SupabaseLanguageLevel // Changed from LanguageLevel
    let topic: String // e.g., "Travel"
    
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining = 180 // 3 minutes in seconds
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var showAnswer = false
    @State private var selectedOptionIndex: Int? = nil
    @State private var showResults = false
    @State private var timer: Timer? = nil
    @State private var isAnimating = false
    
    @StateObject private var viewModel = BossBattleViewModel()
    
    // Primary initializer
    init(language: String, level: SupabaseLanguageLevel, topic: String) {
        self.language = language
        self.level = level
        self.topic = topic
    }
    
    // Special initializer for preview macro
    init(forPreview: Bool) {
        if forPreview {
            // Use default values for preview
            self.language = "Spanish"
            self.level = SupabaseLanguageLevel(id: 1, code: "B1", name: "Intermediate", ordinal: 3, languageId: 1)
            self.topic = "Travel"
        } else {
            // This is called from LanguageDashboardView, so use default values
            // In a real app, these would be passed in somehow
            self.language = "Spanish"
            self.level = SupabaseLanguageLevel(id: 1, code: "B1", name: "Intermediate", ordinal: 3, languageId: 1)
            self.topic = "Travel"
        }
    }
    
    // Sample questions for boss battle - in a real app, these would be generated based on level
    let questions: [BossBattleQuestion] = [
        BossBattleQuestion(
            text: "What does 'Buenos días' mean?",
            options: ["Good night", "Good afternoon", "Good morning", "Hello"],
            correctOptionIndex: 2,
            type: .multipleChoice
        ),
        BossBattleQuestion(
            text: "Fill in the blank: Yo _____ español.",
            options: ["hablas", "hablan", "hablo", "habla"],
            correctOptionIndex: 2,
            type: .fillInBlank
        ),
        BossBattleQuestion(
            text: "Match the correct translation for 'gracias'",
            options: ["Hello", "Goodbye", "Please", "Thank you"],
            correctOptionIndex: 3,
            type: .matching
        ),
        BossBattleQuestion(
            text: "'Por favor' means 'please' in English",
            options: ["True", "False"],
            correctOptionIndex: 0,
            type: .trueOrFalse
        ),
        BossBattleQuestion(
            text: "How do you say 'I am from America' in Spanish?",
            options: ["Soy de América", "Estoy de América", "Yo América", "De América yo"],
            correctOptionIndex: 0,
            type: .multipleChoice
        ),
        BossBattleQuestion(
            text: "Complete: '¿_____ te llamas?'",
            options: ["Qué", "Cómo", "Dónde", "Quién"],
            correctOptionIndex: 1,
            type: .fillInBlank
        ),
        BossBattleQuestion(
            text: "Match the correct translation for 'libro'",
            options: ["Pencil", "Book", "Notebook", "Phone"],
            correctOptionIndex: 1,
            type: .matching
        ),
        BossBattleQuestion(
            text: "The Spanish word for 'water' is 'agua'",
            options: ["True", "False"],
            correctOptionIndex: 0,
            type: .trueOrFalse
        ),
    ]
    
    var currentQuestion: BossBattleQuestion {
        questions[currentQuestionIndex]
    }
    
    // Calculate time as MM:SS
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Calculate final score as percentage
    var scorePercentage: Int {
        return Int((Double(score) / Double(questions.count)) * 100)
    }
    
    // Medal based on score
    var medal: (name: String, color: Color) {
        switch scorePercentage {
        case 90...100:
            return ("Gold", Color.goldColor)
        case 75..<90:
            return ("Silver", Color.silverColor)
        case 60..<75:
            return ("Bronze", Color.bronzeColor)
        default:
            return ("No Medal", Color.gray)
        }
    }
    
    var passed: Bool {
        return scorePercentage >= 60
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if showResults {
                resultsView
            } else {
                contentView
            }
        }
        .navigationBarTitle("Boss Battle", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { 
                    stopTimer()
                    dismiss() 
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // Header with timer and progress
            HStack {
                // Timer
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(timeRemaining <= 30 ? .red : .primary)
                    
                    Text(timeString)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(timeRemaining <= 30 ? .red : .primary)
                        .monospacedDigit()
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                Spacer()
                
                // Progress
                Text("\(currentQuestionIndex + 1)/\(questions.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Question type badge
            HStack {
                Text(questionTypeBadgeText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(questionTypeBadgeColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Spacer()
                
                Text("Level: \(level.name)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.0, green: 0.75, blue: 1.0).opacity(0.2))
                    .foregroundColor(Color(red: 0.0, green: 0.75, blue: 1.0))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Question card
            VStack(spacing: 20) {
                Text(currentQuestion.text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top)
                
                Divider()
                
                // Options
                ForEach(0..<currentQuestion.options.count, id: \.self) { index in
                    Button(action: {
                        if !showAnswer {
                            selectedOptionIndex = index
                            withAnimation {
                                showAnswer = true
                            }
                            
                            // Check answer
                            if index == currentQuestion.correctOptionIndex {
                                score += 1
                            }
                            
                            // Auto advance after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                moveToNextQuestion()
                            }
                        }
                    }) {
                        HStack {
                            Text(currentQuestion.options[index])
                                .padding()
                            
                            Spacer()
                            
                            if showAnswer && index == selectedOptionIndex {
                                Image(systemName: index == currentQuestion.correctOptionIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(index == currentQuestion.correctOptionIndex ? .green : .red)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(optionBackgroundColor(for: index))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(optionBorderColor(for: index), lineWidth: 2)
                        )
                    }
                    .disabled(showAnswer)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var resultsView: some View {
        VStack(spacing: 24) {
            // Medal image
            ZStack {
                Circle()
                    .fill(medal.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .stroke(medal.color, lineWidth: 4)
                    .frame(width: 160, height: 160)
                
                VStack(spacing: 4) {
                    Image(systemName: passed ? "trophy.fill" : "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(passed ? medal.color : .red)
                    
                    Text(passed ? medal.name : "Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(passed ? medal.color : .red)
                }
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            
            Text(passed ? "Challenge Completed!" : "Try Again!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("\(score) correct out of \(questions.count)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Score breakdown
            VStack(spacing: 16) {
                scoreRow(title: "Score", value: "\(scorePercentage)%")
                scoreRow(title: "Time Taken", value: "\(180 - timeRemaining) seconds")
                scoreRow(title: "Level Unlocked", value: passed ? "Yes" : "No")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            if passed {
                // Confetti effect or animation could be added here
                Text("You've unlocked the next level!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("You need at least 60% to pass.")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding()
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    // Reset and try again
                    timeRemaining = 180
                    currentQuestionIndex = 0
                    score = 0
                    showAnswer = false
                    selectedOptionIndex = nil
                    showResults = false
                    startTimer()
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Finish")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.arcticBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func scoreRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    
    private func optionBackgroundColor(for index: Int) -> Color {
        if showAnswer {
            if index == currentQuestion.correctOptionIndex {
                return Color.green.opacity(0.1)
            } else if index == selectedOptionIndex {
                return Color.red.opacity(0.1)
            }
        }
        return Color(.systemBackground)
    }
    
    private func optionBorderColor(for index: Int) -> Color {
        if showAnswer {
            if index == currentQuestion.correctOptionIndex {
                return .green
            } else if index == selectedOptionIndex {
                return .red
            }
        }
        return Color(.systemGray4)
    }
    
    private var questionTypeBadgeText: String {
        switch currentQuestion.type {
        case .multipleChoice:
            return "Multiple Choice"
        case .fillInBlank:
            return "Fill in the Blank"
        case .matching:
            return "Matching"
        case .trueOrFalse:
            return "True or False"
        }
    }
    
    private var questionTypeBadgeColor: Color {
        switch currentQuestion.type {
        case .multipleChoice:
            return Color.purpleViolet // Purple
        case .fillInBlank:
            return Color.warmOrange // Orange
        case .matching:
            return Color.arcticBlue // Blue
        case .trueOrFalse:
            return Color.forestGreen // Green
        }
    }
    
    private func moveToNextQuestion() {
        withAnimation {
            showAnswer = false
            selectedOptionIndex = nil
            
            if currentQuestionIndex < questions.count - 1 {
                currentQuestionIndex += 1
            } else {
                showResults = true
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Time's up
                stopTimer()
                showResults = true
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct BossBattleQuestion {
    let text: String
    let options: [String]
    let correctOptionIndex: Int
    let type: BossBattleQuestionType
}

// Add a private extension with our custom colors
private extension Color {
    static let arcticBlue = Color(red: 0, green: 191/255, blue: 255/255)
    static let warmOrange = Color(red: 255/255, green: 159/255, blue: 28/255)
    static let purpleViolet = Color(red: 138/255, green: 43/255, blue: 226/255)
    static let forestGreen = Color(red: 66/255, green: 184/255, blue: 131/255)
    static let bronzeColor = Color(red: 205/255, green: 127/255, blue: 50/255)
    static let goldColor = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let silverColor = Color(red: 192/255, green: 192/255, blue: 192/255)
}

// Explicit preview provider that uses the forPreview initializer
struct BossBattleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BossBattleView(forPreview: true)
        }
    }
} 