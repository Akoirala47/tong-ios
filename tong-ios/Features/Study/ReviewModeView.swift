import SwiftUI

struct ReviewModeView: View {
    let languageCode: String
    let userId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentCardIndex = 0
    @State private var isShowingAnswer = false
    @State private var selectedFeedback: FeedbackType? = nil
    @State private var showCompletion = false
    @State private var cardRotation: Double = 0
    @State private var cardOpacity: Double = 1
    
    enum FeedbackType: String, CaseIterable {
        case again = "Again"
        case hard = "Hard"
        case good = "Good"
        case easy = "Easy"
        
        var intervalDays: Int {
            switch self {
            case .again: return 1
            case .hard: return 3
            case .good: return 7
            case .easy: return 14
            }
        }
        
        var color: Color {
            switch self {
            case .again: return .red
            case .hard: return .orange
            case .good: return Color(hex: "00BFFF")
            case .easy: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .again: return "arrow.counterclockwise"
            case .hard: return "tortoise.fill"
            case .good: return "hand.thumbsup.fill"
            case .easy: return "bolt.fill"
            }
        }
    }
    
    // Sample review cards - in a real app, these would come from your database
    let reviewCards: [ReviewCard] = [
        ReviewCard(
            word: "Hola",
            translation: "Hello",
            example: "¡Hola! ¿Cómo estás?",
            pronunciation: "oh-lah",
            lastInterval: 1
        ),
        ReviewCard(
            word: "Gracias",
            translation: "Thank you",
            example: "Muchas gracias por tu ayuda.",
            pronunciation: "grah-see-as",
            lastInterval: 3
        ),
        ReviewCard(
            word: "Adiós",
            translation: "Goodbye",
            example: "Adiós, hasta mañana.",
            pronunciation: "ah-dee-ohs",
            lastInterval: 2
        ),
        ReviewCard(
            word: "Por favor",
            translation: "Please",
            example: "Dame el libro, por favor.",
            pronunciation: "pohr fah-vohr",
            lastInterval: 1
        ),
        ReviewCard(
            word: "Buenos días",
            translation: "Good morning",
            example: "Buenos días, ¿cómo amaneciste?",
            pronunciation: "bweh-nohs dee-ahs",
            lastInterval: 2
        ),
    ]
    
    var currentCard: ReviewCard {
        reviewCards[currentCardIndex]
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
        .navigationBarTitle("Review", displayMode: .inline)
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
            // Progress bar
            HStack {
                Text("\(currentCardIndex + 1) of \(reviewCards.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: Double(currentCardIndex + 1), total: Double(reviewCards.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "00BFFF")))
                    .frame(width: 100)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Card
            ZStack {
                VStack(spacing: 16) {
                    Text(isShowingAnswer ? currentCard.translation : currentCard.word)
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.vertical)
                    
                    if isShowingAnswer {
                        Text(currentCard.example)
                            .font(.body)
                            .italic()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("[\(currentCard.pronunciation)]")
                            .font(.body)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Tap to reveal \(isShowingAnswer ? "question" : "answer")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(30)
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
                .opacity(cardOpacity)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                        cardRotation += 180
                        // After half of the animation, update the flag
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isShowingAnswer.toggle()
                        }
                    }
                }
            }
            
            Spacer()
            
            // Feedback buttons (only shown if answer is visible)
            if isShowingAnswer {
                Text("How well did you remember this?")
                    .font(.headline)
                    .padding(.top)
                
                HStack(spacing: 12) {
                    ForEach(FeedbackType.allCases, id: \.self) { feedback in
                        feedbackButton(feedback)
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: isShowingAnswer)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private func feedbackButton(_ feedback: FeedbackType) -> some View {
        Button(action: {
            selectedFeedback = feedback
            moveToNextCard()
        }) {
            VStack(spacing: 8) {
                Image(systemName: feedback.icon)
                    .font(.title2)
                
                Text(feedback.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("+\(feedback.intervalDays)d")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(feedback.color.opacity(0.1))
            .foregroundColor(feedback.color)
            .cornerRadius(12)
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
                .padding()
            
            Text("Review Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've reviewed all \(reviewCards.count) cards due today.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.fill")
                        .foregroundColor(Color(hex: "00BFFF"))
                    Text("Cards reviewed: \(reviewCards.count)")
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    Text("Next review: Tomorrow")
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
                    .background(Color(hex: "00BFFF"))
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private func moveToNextCard() {
        // Fade out current card
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOpacity = 0
        }
        
        // After fade out, move to next card or show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentCardIndex < reviewCards.count - 1 {
                currentCardIndex += 1
                isShowingAnswer = false
                cardRotation = 0
                selectedFeedback = nil
                
                // Fade in next card
                withAnimation(.easeInOut(duration: 0.3)) {
                    cardOpacity = 1
                }
            } else {
                showCompletion = true
            }
        }
    }
}

struct ReviewCard {
    let word: String
    let translation: String
    let example: String
    let pronunciation: String
    let lastInterval: Int
}

// Color extension moved to Core/Extensions/Color+Extensions.swift

#Preview {
    NavigationStack {
        ReviewModeView(languageCode: "es", userId: "preview-user")
    }
} 