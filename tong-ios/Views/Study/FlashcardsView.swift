import SwiftUI

struct FlashcardsView: View {
    @State private var selectedLang = "es"
    @State private var selectedLevel = "NL"
    @State private var selectedTopicId: UUID?
    @State private var selectedLessonId: UUID?
    @State private var isShowingCard = false
    @State private var currentCardIndex = 0
    @State private var flipState = false
    @State private var reviewedCards = Set<UUID>()
    
    private let contentRepo = ContentRepository.shared
    
    var topics: [ContentModels.Topic] {
        contentRepo.getTopics(langCode: selectedLang, levelCode: selectedLevel)
    }
    
    var selectedTopic: ContentModels.Topic? {
        if let id = selectedTopicId {
            return topics.first { $0.id == id }
        }
        return nil
    }
    
    var lessons: [ContentModels.Lesson] {
        if let id = selectedTopicId {
            return contentRepo.getLessons(topicId: id)
        }
        return []
    }
    
    var selectedLesson: ContentModels.Lesson? {
        if let id = selectedLessonId {
            return lessons.first { $0.id == id }
        }
        return nil
    }
    
    var cards: [ContentModels.Card] {
        if let id = selectedLessonId {
            return contentRepo.getCards(lessonId: id)
        }
        return []
    }
    
    var currentCard: ContentModels.Card? {
        guard !cards.isEmpty, currentCardIndex < cards.count else { return nil }
        return cards[currentCardIndex]
    }
    
    var body: some View {
        Group {
            if isShowingCard, let card = currentCard {
                flashcardView(card: card)
            } else {
                contentSelectionView
            }
        }
        .toolbar {
            if isShowingCard {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isShowingCard = false
                        currentCardIndex = 0
                        flipState = false
                        reviewedCards.removeAll()
                    }
                }
            }
        }
    }
    
    private var contentSelectionView: some View {
        List {
            Section(header: Text("Language")) {
                Picker("Language", selection: $selectedLang) {
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("Japanese").tag("jp")
                    Text("Chinese").tag("zh")
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedLang) { oldValue, newValue in
                    selectedTopicId = nil
                    selectedLessonId = nil
                }
            }
            
            Section(header: Text("Level")) {
                Picker("Level", selection: $selectedLevel) {
                    Text("Novice Low").tag("NL")
                    Text("Novice Mid").tag("NM")
                    Text("Novice High").tag("NH")
                    Text("Intermediate Low").tag("IL")
                    Text("Intermediate Mid").tag("IM")
                    Text("Intermediate High").tag("IH")
                    Text("Advanced Low").tag("AL")
                    Text("Advanced Mid").tag("AM")
                    Text("Advanced High").tag("AH")
                    Text("Superior").tag("S")
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLevel) { oldValue, newValue in
                    selectedTopicId = nil
                    selectedLessonId = nil
                }
            }
            
            if !topics.isEmpty {
                Section(header: Text("Topics")) {
                    ForEach(topics) { topic in
                        Button(action: {
                            selectedTopicId = topic.id
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(topic.title)
                                        .font(.headline)
                                    Text(topic.canDoStatement)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedTopicId == topic.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "No Content Available",
                        systemImage: "book.closed",
                        description: Text("No topics found for the selected language and level.")
                    )
                }
            }
            
            if let _ = selectedTopicId, !lessons.isEmpty {
                Section(header: Text("Lessons")) {
                    ForEach(lessons) { lesson in
                        Button(action: {
                            selectedLessonId = lesson.id
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(lesson.title)
                                        .font(.headline)
                                    Text(lesson.objective)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedLessonId == lesson.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            if let lesson = selectedLesson {
                Section {
                    Button(action: {
                        isShowingCard = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Start Flashcards")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 8)
                    
                    Text("\(lesson.cards.count) cards available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    private func flashcardView(card: ContentModels.Card) -> some View {
        VStack {
            // Progress indicator
            HStack {
                ForEach(0..<cards.count, id: \.self) { index in
                    Rectangle()
                        .frame(height: 4)
                        .foregroundColor(
                            index == currentCardIndex ? .blue :
                            reviewedCards.contains(cards[index].id) ? .gray : .gray.opacity(0.3)
                        )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Card content
            VStack(spacing: 16) {
                ZStack {
                    // Front
                    VStack(spacing: 24) {
                        Text(card.word)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        if let ipa = card.ipa {
                            Text(ipa)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .opacity(flipState ? 0 : 1)
                    
                    // Back
                    VStack(spacing: 24) {
                        Text(card.translation)
                            .font(.system(size: 34, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text(card.exampleSentence)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if let grammarExplanation = card.grammarExplanation {
                            Text(grammarExplanation)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .opacity(flipState ? 1 : 0)
                }
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(radius: 5)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        flipState.toggle()
                    }
                }
                
                Text("Tap card to flip")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Spacer()
            
            // Review buttons
            HStack(spacing: 16) {
                if flipState {
                    reviewButton(text: "Hard", color: .red, action: {
                        nextCard()
                    })
                    
                    reviewButton(text: "Good", color: .blue, action: {
                        nextCard()
                    })
                    
                    reviewButton(text: "Easy", color: .green, action: {
                        nextCard()
                    })
                } else {
                    // Show 'Reveal' button when card is not flipped
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            flipState.toggle()
                        }
                    }) {
                        Text("Reveal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func reviewButton(text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    private func nextCard() {
        guard let card = currentCard else { return }
        reviewedCards.insert(card.id)
        
        if currentCardIndex < cards.count - 1 {
            withAnimation {
                flipState = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentCardIndex += 1
                }
            }
        } else {
            withAnimation {
                // All cards reviewed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowingCard = false
                    currentCardIndex = 0
                    flipState = false
                    reviewedCards.removeAll()
                }
            }
        }
    }
}

#Preview {
    FlashcardsView()
} 