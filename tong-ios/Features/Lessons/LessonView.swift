import SwiftUI

struct LessonView: View {
    @StateObject var viewModel: LessonViewModel
    let lesson: SupabaseLesson
    @State private var lessonFlashcards: [SupabaseFlashcard] = []
    @State private var showPracticeSheet = false
    @State private var practiceCard: SupabaseFlashcard?
    
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var currentPage = 0
    @State private var progress: Double = 0.0
    
    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading lesson...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
                .padding()
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Error loading lesson")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        loadLesson()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 300)
            } else if let lesson = lesson {
                VStack(alignment: .leading, spacing: 20) {
                    // Progress bar
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal)
                    
                    // Lesson content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(lesson.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if let subtitle = lesson.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        // Markdown content
                        if let content = lesson.content, !content.isEmpty {
                            Text(content)
                                .padding(.horizontal)
                        } else {
                            Text("This lesson has no content yet.")
                                .italic()
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        // Flashcards section
                        if !lessonFlashcards.isEmpty {
                            Divider()
                                .padding(.vertical)
                            
                            Text("Vocabulary")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Flashcard list
                            VStack(spacing: 12) {
                                ForEach(lessonFlashcards) { card in
                                    VocabularyItem(
                                        word: card.word,
                                        translation: card.translation,
                                        exampleSentence: card.exampleSentence,
                                        ipa: card.ipa
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Practice button
                        Button(action: {
                            practicePronunciation(for: lesson)
                        }) {
                            Text("Practice Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
            } else {
                Text("Lesson not found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            loadLesson()
        }
    }
    
    private func loadLesson() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Load lesson details
                let lessons: [SupabaseLesson] = try await SupabaseService.shared.getLessonById(lesson.id)
                
                guard let loadedLesson = lessons.first else {
                    throw NSError(domain: "LessonView", code: 404, userInfo: [NSLocalizedDescriptionKey: "Lesson not found"])
                }
                
                // Load flashcards for this lesson
                let loadedFlashcards = try await SupabaseService.shared.getFlashcards(for: lesson.id)
                
                DispatchQueue.main.async {
                    self.lesson = loadedLesson
                    self.lessonFlashcards = loadedFlashcards
                    self.progress = 0.0 // Start at 0, will update as user progresses
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load lesson: \(error.localizedDescription)"
                    self.isLoading = false
                }
                print("Error loading lesson: \(error)")
            }
        }
    }
    
    private func practicePronunciation(for card: SupabaseFlashcard) {
        self.practiceCard = card
        self.showPracticeSheet = true
    }
}

struct VocabularyItem: View {
    let word: String
    let translation: String
    let exampleSentence: String?
    let ipa: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word)
                        .font(.headline)
                    
                    if let ipa = ipa, !ipa.isEmpty {
                        Text(ipa)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(translation)
                    .font(.body)
                    .foregroundColor(.blue)
            }
            
            if let example = exampleSentence, !example.isEmpty {
                Text(example)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LessonView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LessonView(lesson: SupabaseLesson(id: "1", title: "Sample Lesson", subtitle: "A brief description", content: "This is a sample lesson content."))
        }
    }
} 