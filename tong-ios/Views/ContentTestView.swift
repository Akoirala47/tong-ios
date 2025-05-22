import SwiftUI

struct ContentTestView: View {
    @State private var topics: [ContentModels.Topic] = []
    @State private var selectedLevel = "NL"
    
    private let levels = ["NL", "NM", "NH", "IL", "IM", "IH", "AL", "AM", "AH", "S"]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Level picker
                Picker("ACTFL Level", selection: $selectedLevel) {
                    ForEach(levels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedLevel) { oldValue, newValue in
                    loadTopics(for: newValue)
                }
                
                if topics.isEmpty {
                    ContentUnavailableView(
                        "No Content Available",
                        systemImage: "book.closed",
                        description: Text("No topics found for level \(selectedLevel)")
                    )
                } else {
                    List {
                        ForEach(topics) { topic in
                            NavigationLink(destination: TopicDetailView(topic: topic)) {
                                TopicRowView(topic: topic)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spanish Content")
            .onAppear {
                loadTopics(for: selectedLevel)
            }
        }
    }
    
    private func loadTopics(for level: String) {
        topics = ESContentLoader.getTopics(levelCode: level)
    }
}

struct TopicRowView: View {
    let topic: ContentModels.Topic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(topic.title)
                .font(.headline)
            
            Text(topic.canDoStatement)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(topic.lessons.count) lessons")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
}

struct TopicDetailView: View {
    let topic: ContentModels.Topic
    
    var body: some View {
        List {
            Section {
                Text(topic.canDoStatement)
                    .italic()
                    .foregroundColor(.secondary)
            }
            
            Section("Lessons") {
                ForEach(topic.lessons.sorted(by: { $0.orderInTopic < $1.orderInTopic })) { lesson in
                    NavigationLink(destination: ContentLessonDetailView(lesson: lesson)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title)
                                .font(.headline)
                            
                            Text(lesson.objective)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(lesson.cards.count) flashcards")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(topic.title)
    }
}

struct ContentLessonDetailView: View {
    let lesson: ContentModels.Lesson
    @State private var showFlashcards = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Lesson objective
                Text(lesson.objective)
                    .font(.subheadline)
                    .italic()
                    .padding(.horizontal)
                
                // Lesson content (Markdown)
                if let content = lesson.content {
                    Text(try! AttributedString(markdown: content))
                        .padding(.horizontal)
                }
                
                // Flashcards button
                Button {
                    showFlashcards.toggle()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.fill.on.rectangle.fill")
                        Text("Study \(lesson.cards.count) Flashcards")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(lesson.title)
        .sheet(isPresented: $showFlashcards) {
            ContentFlashcardsView(cards: lesson.cards)
        }
    }
}

struct ContentFlashcardsView: View {
    let cards: [ContentModels.Card]
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    
    var body: some View {
        VStack {
            if cards.isEmpty {
                Text("No flashcards available")
            } else {
                // Card counter
                Text("\(currentIndex + 1) of \(cards.count)")
                    .font(.caption)
                    .padding()
                
                // Flashcard
                VStack(spacing: 20) {
                    // The card
                    VStack(spacing: 16) {
                        Text(isShowingAnswer ? cards[currentIndex].translation : cards[currentIndex].word)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if isShowingAnswer {
                            if let ipa = cards[currentIndex].ipa {
                                Text(ipa)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(cards[currentIndex].exampleSentence)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation {
                            isShowingAnswer.toggle()
                        }
                    }
                    
                    // Tap to flip text
                    Text("Tap card to flip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Navigation buttons
                    HStack(spacing: 30) {
                        Button {
                            if currentIndex > 0 {
                                currentIndex -= 1
                                isShowingAnswer = false
                            }
                        } label: {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(currentIndex > 0 ? .blue : .gray)
                        }
                        .disabled(currentIndex == 0)
                        
                        Button {
                            if currentIndex < cards.count - 1 {
                                currentIndex += 1
                                isShowingAnswer = false
                            }
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(currentIndex < cards.count - 1 ? .blue : .gray)
                        }
                        .disabled(currentIndex == cards.count - 1)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentTestView()
} 