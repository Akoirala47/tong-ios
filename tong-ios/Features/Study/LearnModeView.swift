import SwiftUI

struct LearnModeView: View {
    let languageCode: String
    let userId: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LearnModeViewModel
    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var selectedOption: Int? = nil
    @State private var isCorrect: Bool? = nil
    @State private var streak = 0
    @State private var lives = 3
    @State private var showCompletion = false
    
    var currentItem: LearnModeVocabItemData {
        guard !viewModel.vocabItems.isEmpty, currentIndex < viewModel.vocabItems.count else {
            // Provide a fallback item if no data is available
            return LearnModeVocabItemData(
                word: "Loading...",
                translation: "Please wait",
                pronunciation: "loading",
                options: ["Option 1", "Option 2", "Option 3", "Option 4"],
                correctOptionIndex: 0
            )
        }
        return viewModel.vocabItems[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasError {
                errorView
            } else if showCompletion {
                completionView
            } else if viewModel.vocabItems.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationBarTitle(viewModel.currentLesson?.title ?? "Learn", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            await viewModel.loadUserData()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading lesson content...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load content")
                .font(.headline)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: loadData) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("No lessons available")
                .font(.headline)
            
            Text("There are no lessons available at your current level. Please check back later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("Return to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            // Progress and lives
            HStack {
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentIndex + 1) of \(viewModel.vocabItems.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(currentIndex + 1), total: Double(viewModel.vocabItems.count))
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
            
            // Topic and lesson info
            if let topic = viewModel.currentTopic {
                Text(topic.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
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
                    Text(currentIndex == viewModel.vocabItems.count - 1 ? "Finish" : "Continue")
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
            
            if let lesson = viewModel.currentLesson, let topic = viewModel.currentTopic {
                Text("You've completed \"\(lesson.title)\" from \"\(topic.title)\"")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("You've learned \(viewModel.vocabItems.count) new words.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Words learned: \(viewModel.vocabItems.count)")
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
                // Record completion and update progress
                Task {
                    await viewModel.recordLessonCompletion()
                    dismiss()
                }
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
            
            if currentIndex < viewModel.vocabItems.count - 1 {
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
        // Initialize the view model
        self._viewModel = StateObject(wrappedValue: LearnModeViewModel(userId: "preview-user", languageCode: "es"))
    }
    
    // Add the standard initializer for normal usage
    init(languageCode: String, userId: String, forPreview: Bool = false) {
        self.languageCode = languageCode
        self.userId = userId
        // Initialize the view model
        self._viewModel = StateObject(wrappedValue: LearnModeViewModel(userId: userId, languageCode: languageCode))
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