import SwiftUI

struct FlashcardReviewView: View {
    @StateObject private var viewModel: FlashcardReviewViewModel
    @State private var isShowingAnswer = false
    @State private var offset: CGSize = .zero
    @State private var currentAngle: Angle = .degrees(0)
    @State private var currentScale: CGFloat = 1.0
    
    // Card constants
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let cardHeight: CGFloat = 400
    private let rotationAngle: Double = 5
    private let swipeThreshold: CGFloat = 120
    
    // Animation settings
    private let animationDuration: Double = 0.3
    
    init(langCode: String = "es") {
        _viewModel = StateObject(wrappedValue: FlashcardReviewViewModel(langCode: langCode))
    }
    
    var body: some View {
        ZStack {
            backgroundView
            
            // Content
            VStack {
                // Progress indicator
                progressView
                
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if viewModel.flashcards.isEmpty {
                    emptyStateView
                } else {
                    // Card container
                    cardContainer
                    
                    // Answer buttons when answer is revealed
                    if isShowingAnswer {
                        answerButtonsView
                    }
                    
                    // Instructions
                    instructionsView
                }
            }
            .padding()
        }
        .navigationTitle("Flashcard Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadFlashcards()
        }
    }
    
    // MARK: - Component Views
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var progressView: some View {
        HStack {
            if !viewModel.flashcards.isEmpty {
                Text("Card \(viewModel.currentCardIndex + 1) of \(viewModel.totalCards)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Streak: \(viewModel.streak)")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading flashcards...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: cardHeight + 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding()
            
            Text("No flashcards due for review")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Check back later or try another language")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.loadFlashcards()
            }) {
                Text("Refresh")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .frame(height: cardHeight + 40)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()
            
            Text("Error loading flashcards")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.loadFlashcards()
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .frame(height: cardHeight + 40)
    }
    
    private var cardContainer: some View {
        ZStack {
            // Show "No more cards" view if we're done
            if viewModel.isReviewComplete {
                noMoreCardsView
            } else {
                // Main flashcard
                currentCardView
                    .offset(offset)
                    .rotationEffect(currentAngle)
                    .scaleEffect(currentScale)
                    .gesture(
                        DragGesture()
                            .onChanged(onDragChanged)
                            .onEnded(onDragEnded)
                    )
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded {
                                if !viewModel.isReviewComplete {
                                    withAnimation {
                                        isShowingAnswer.toggle()
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: cardHeight + 40)
    }
    
    private var currentCardView: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 5)
            
            // Card content
            VStack(spacing: 20) {
                if let card = viewModel.currentCard {
                    // Front content (always shown)
                    Text(card.word)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    if let ipa = card.ipa, !ipa.isEmpty {
                        Text(ipa)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.top, -15)
                    }
                    
                    Spacer()
                    
                    // Back content (shown when flipped)
                    if isShowingAnswer {
                        Divider()
                            .padding(.horizontal)
                        
                        Text(card.translation)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 5)
                        
                        Text(card.exampleSentence)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let explanation = card.grammarExplanation, !explanation.isEmpty {
                            Text(explanation)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 5)
                        }
                    }
                }
            }
            .padding()
            .frame(width: cardWidth, height: cardHeight)
            
            // Reveal hint
            if !isShowingAnswer {
                VStack {
                    Spacer()
                    Text("Tap to reveal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
            }
        }
    }
    
    private var answerButtonsView: some View {
        HStack(spacing: 10) {
            difficultyButton(text: "Hard", difficulty: .hard, color: .red)
            difficultyButton(text: "Good", difficulty: .good, color: .blue)
            difficultyButton(text: "Easy", difficulty: .easy, color: .green)
        }
        .padding(.vertical)
    }
    
    private var instructionsView: some View {
        VStack(spacing: 5) {
            Text("Swipe right if you know it well")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("Swipe left if it's difficult")
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.bottom)
    }
    
    private var noMoreCardsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Review Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've reviewed \(viewModel.totalCards) cards")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                withAnimation {
                    viewModel.resetReview()
                    isShowingAnswer = false
                }
            }) {
                Text("Start Over")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 5))
    }
    
    // MARK: - Helper Views
    
    private func difficultyButton(text: String, difficulty: CardDifficulty, color: Color) -> some View {
        Button(action: {
            handleAnswer(difficulty: difficulty)
        }) {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(color)
                .cornerRadius(10)
        }
    }
    
    // MARK: - Gesture Handlers
    
    private func onDragChanged(_ gesture: DragGesture.Value) {
        offset = gesture.translation
        
        // Calculate rotation based on horizontal movement
        let xOffsetFactor = min(1, abs(offset.width) / (cardWidth / 2))
        let angle = rotationAngle * xOffsetFactor * (offset.width > 0 ? 1 : -1)
        currentAngle = .degrees(angle)
        
        // Scale down slightly when dragging
        currentScale = max(0.95, 1 - xOffsetFactor * 0.05)
    }
    
    private func onDragEnded(_ gesture: DragGesture.Value) {
        let horizontalMovement = gesture.translation.width
        
        // If dragged beyond threshold, process the card
        if abs(horizontalMovement) > swipeThreshold {
            let difficulty: CardDifficulty = horizontalMovement > 0 ? .easy : .hard
            
            // Animate the card flying off screen
            withAnimation(.easeOut(duration: animationDuration)) {
                offset.width = horizontalMovement > 0 ? 1000 : -1000
                currentAngle = .degrees(rotationAngle * 2 * (horizontalMovement > 0 ? 1 : -1))
            }
            
            // Process the answer after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                handleAnswer(difficulty: difficulty)
            }
        } else {
            // Reset the card position if not dragged far enough
            withAnimation(.spring()) {
                offset = .zero
                currentAngle = .degrees(0)
                currentScale = 1.0
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleAnswer(difficulty: CardDifficulty) {
        viewModel.processAnswer(difficulty: difficulty)
        
        // Reset state for next card
        isShowingAnswer = false
        withAnimation(.spring()) {
            offset = .zero
            currentAngle = .degrees(0)
            currentScale = 1.0
        }
    }
}

// MARK: - Preview

struct FlashcardReviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FlashcardReviewView()
        }
    }
} 