import SwiftUI
import AVFoundation

struct FlashcardDrillView: View {
    let languageCode: String
    let userId: String
    let dueOnly: Bool
    
    @ObservedObject var viewModel: FlashcardDrillViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isFlipped = false
    @State private var fadeIn = false
    
    // Primary initializer
    init(languageCode: String, userId: String, dueOnly: Bool) {
        self.languageCode = languageCode
        self.userId = userId
        self.dueOnly = dueOnly
        self.viewModel = FlashcardDrillViewModel()
    }
    
    // Alternative initializer for previews 
    init(viewModel: FlashcardDrillViewModel, userId: String) {
        self.viewModel = viewModel
        self.languageCode = "preview"
        self.userId = userId
        self.dueOnly = false
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress header
            HStack {
                VStack(alignment: .leading) {
                    Text("\(viewModel.currentIndex + 1) of \(viewModel.flashcards.count)")
                        .font(.headline)
                    
                    ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(viewModel.flashcards.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.arcticBlue))
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Flashcard
            if viewModel.isLoading {
                ProgressView("Loading flashcards...")
            } else if viewModel.currentFlashcard == nil {
                emptyStateView
            } else {
                flashcardView
            }
            
            Spacer()
            
            // Rating buttons (only shown when card is flipped)
            if isFlipped && viewModel.currentFlashcard != nil {
                HStack(spacing: 20) {
                    feedbackButton(text: "Hard", color: .red) {
                        Task {
                            await viewModel.submitReview(feedback: .hard, userId: userId)
                        }
                        moveToNextCard()
                    }
                    
                    feedbackButton(text: "Good", color: Color.arcticBlue) {
                        Task {
                            await viewModel.submitReview(feedback: .good, userId: userId)
                        }
                        moveToNextCard()
                    }
                    
                    feedbackButton(text: "Easy", color: .green) {
                        Task {
                            await viewModel.submitReview(feedback: .easy, userId: userId)
                        }
                        moveToNextCard()
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: isFlipped)
            }
        }
        .padding()
        .navigationTitle(dueOnly ? "Due Cards" : "All Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCards()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Color.arcticBlue)
            
            Text("No flashcards to review!")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("You've reviewed all your flashcards for now. Check back later!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    private var flashcardView: some View {
        ZStack {
            // Card background with nice shadow effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.arcticBlue.opacity(0.5), lineWidth: 1)
                )
            
            // Card content
            VStack(spacing: 30) {
                if let card = viewModel.currentFlashcard {
                    if !isFlipped {
                        // Front of card
                        VStack(spacing: 16) {
                            Text(card.word)
                                .font(.system(size: 36, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            // Placeholder for pronunciation
                            // Text("[\(card.pronunciation)]")
                            //    .font(.title3)
                            //    .italic()
                            //    .foregroundColor(.secondary)
                        }
                    } else {
                        // Back of card
                        VStack(spacing: 16) {
                            Text(card.translation)
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            // Example sentence - placeholder if none available
                            // if !card.example.isEmpty {
                            //     Text(card.example)
                            //         .font(.body)
                            //         .multilineTextAlignment(.center)
                            //         .padding(.horizontal)
                            //         .foregroundColor(.secondary)
                            // }
                        }
                    }
                }
                
                // Tap to flip instruction
                Text("Tap to flip")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(0.7)
            }
            .padding(40)
            .opacity(fadeIn ? 1 : 0)
            .animation(.easeIn, value: fadeIn)
        }
        .frame(height: 350)
        .rotation3DEffect(
            isFlipped ? .degrees(180) : .degrees(0),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                isFlipped.toggle()
            }
        }
    }
    
    private func feedbackButton(text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(12)
        }
    }
    
    private func loadCards() {
        Task {
            await viewModel.fetchDueFlashcards(for: userId)
            fadeIn = true
        }
    }
    
    private func moveToNextCard() {
        withAnimation {
            fadeIn = false
            isFlipped = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.viewModel.currentIndex < self.viewModel.flashcards.count - 1 {
                self.viewModel.currentIndex += 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    fadeIn = true
                }
            }
        }
    }
}

// Define our own specific colors to avoid ambiguity
private extension Color {
    static let arcticBlue = Color(red: 0, green: 191/255, blue: 255/255)
}

// Use the PreviewProvider approach for consistency
struct FlashcardDrillView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Use a distinct initializer for preview to avoid ambiguity
            let previewViewModel = FlashcardDrillViewModel()
            FlashcardDrillView(
                viewModel: previewViewModel,
                userId: "preview-user"
            )
        }
    }
} 