import SwiftUI

struct LearnModeView: View {
    let languageCode: String
    let userId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var selectedOption: Int? = nil
    @State private var isCorrect: Bool? = nil
    @State private var streak = 0
    @State private var lives = 3
    @State private var showCompletion = false
    
    // Sample vocabulary items - in a real app, these would come from your database
    let vocabItems: [LearnModeVocabItemData] = [
        LearnModeVocabItemData(
            word: "Hola",
            translation: "Hello",
            pronunciation: "oh-lah",
            options: ["Hello", "Goodbye", "Thank you", "Please"],
            correctOptionIndex: 0
        ),
        LearnModeVocabItemData(
            word: "Gracias",
            translation: "Thank you",
            pronunciation: "grah-see-as",
            options: ["Welcome", "Please", "Thank you", "Good morning"],
            correctOptionIndex: 2
        ),
        LearnModeVocabItemData(
            word: "Adiós",
            translation: "Goodbye",
            pronunciation: "ah-dee-ohs",
            options: ["Hello", "Welcome", "Goodbye", "Good night"],
            correctOptionIndex: 2
        ),
        LearnModeVocabItemData(
            word: "Por favor",
            translation: "Please",
            pronunciation: "pohr fah-vohr",
            options: ["Thank you", "Please", "You're welcome", "Excuse me"],
            correctOptionIndex: 1
        ),
        LearnModeVocabItemData(
            word: "Buenos días",
            translation: "Good morning",
            pronunciation: "bweh-nohs dee-ahs",
            options: ["Good night", "Good afternoon", "Good morning", "Good evening"],
            correctOptionIndex: 2
        ),
        LearnModeVocabItemData(
            word: "Buenas noches",
            translation: "Good night",
            pronunciation: "bweh-nahs noh-chehs",
            options: ["Good morning", "Good evening", "Good afternoon", "Good night"],
            correctOptionIndex: 3
        ),
        LearnModeVocabItemData(
            word: "Sí",
            translation: "Yes",
            pronunciation: "see",
            options: ["No", "Maybe", "Yes", "Please"],
            correctOptionIndex: 2
        ),
        LearnModeVocabItemData(
            word: "No",
            translation: "No",
            pronunciation: "noh",
            options: ["Yes", "No", "Maybe", "Hello"],
            correctOptionIndex: 1
        ),
    ]
    
    var currentItem: LearnModeVocabItemData {
        vocabItems[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if showCompletion {
                completionView
            } else {
                contentView
            }
        }
        .navigationBarTitle("Learn", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            // Progress and lives
            HStack {
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentIndex + 1) of \(vocabItems.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(currentIndex + 1), total: Double(vocabItems.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.0, green: 0.75, blue: 1.0)))
                }
                
                Spacer()
                
                // Lives
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < lives ? "heart.fill" : "heart")
                            .foregroundColor(i < lives ? .red : .gray)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Word card
            VStack(spacing: 16) {
                Text(currentItem.word)
                    .font(.system(size: 40, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("[\(currentItem.pronunciation)]")
                    .font(.body)
                    .italic()
                    .foregroundColor(.secondary)
                
                if showAnswer {
                    Text(currentItem.translation)
                        .font(.title2)
                        .padding(.top, 8)
                        .foregroundColor(.blue)
                        .transition(.opacity)
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            .padding(.horizontal)
            
            Spacer()
            
            // Options
            Text("Choose the correct translation:")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 12) {
                ForEach(0..<currentItem.options.count, id: \.self) { index in
                    optionButton(index: index)
                }
            }
            .padding(.horizontal)
            
            // Continue button (shown after answer)
            if showAnswer {
                Button(action: nextItem) {
                    Text(currentIndex == vocabItems.count - 1 ? "Finish" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.0, green: 0.75, blue: 1.0))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.top, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private func optionButton(index: Int) -> some View {
        Button(action: {
            if !showAnswer {
                selectedOption = index
                isCorrect = index == currentItem.correctOptionIndex
                
                // Update streak and lives
                if isCorrect == true {
                    streak += 1
                } else {
                    lives = max(0, lives - 1)
                }
                
                withAnimation {
                    showAnswer = true
                }
            }
        }) {
            HStack {
                Text(currentItem.options[index])
                    .font(.body)
                    .padding()
                
                Spacer()
                
                if showAnswer && selectedOption == index {
                    Image(systemName: isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect == true ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .background(backgroundForOption(index))
            .cornerRadius(12)
        }
        .disabled(showAnswer)
    }
    
    private func backgroundForOption(_ index: Int) -> some View {
        Group {
            if showAnswer {
                if index == currentItem.correctOptionIndex {
                    Color.green.opacity(0.2)
                } else if index == selectedOption {
                    Color.red.opacity(0.2)
                } else {
                    Color(.systemGray6)
                }
            } else {
                Color(.systemGray6)
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))
                .padding()
            
            Text("Lesson Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've learned \(vocabItems.count) new words.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Words learned: \(vocabItems.count)")
                }
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Lives remaining: \(lives)/3")
                }
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Longest streak: \(streak)")
                }
            }
            .font(.headline)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            Button(action: {
                dismiss()
            }) {
                Text("Return to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.0, green: 0.75, blue: 1.0))
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private func nextItem() {
        withAnimation {
            showAnswer = false
            selectedOption = nil
            isCorrect = nil
            
            if currentIndex < vocabItems.count - 1 {
                currentIndex += 1
            } else {
                showCompletion = true
            }
        }
    }
    
    // Add a preview-specific initializer
    init(forPreview: Bool) {
        self.languageCode = "es"
        self.userId = "preview-user"
        // This initializer is only used for previews
    }
    
    // Add the standard initializer for normal usage
    init(languageCode: String, userId: String, forPreview: Bool = false) {
        self.languageCode = languageCode
        self.userId = userId
    }
}

// MARK: - Models for Learn Mode

struct LearnModeVocabItemData: Identifiable {
    let id = UUID()
    let word: String
    let translation: String
    let pronunciation: String
    let options: [String]
    let correctOptionIndex: Int
}

#Preview {
    NavigationView {
        LearnModeView(forPreview: true)
    }
} 