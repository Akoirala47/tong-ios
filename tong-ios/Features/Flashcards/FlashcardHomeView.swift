import SwiftUI

struct FlashcardHomeView: View {
    @ObservedObject var drillViewModel: FlashcardDrillViewModel
    @ObservedObject var statsViewModel: ProfileStatsViewModel
    @StateObject private var viewModel = FlashcardHomeViewModel()
    let userId: String
    @State private var dailyXP = 25 // Example value
    @State private var dueCardCount = 0
    private let dailyXPGoal = 50
    @State private var navigateToLesson: Bool = false
    @State private var navigateToDrill: Bool = false
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationDestination(isPresented: $navigateToLesson) {
                    LessonDetailView(lesson: viewModel.lastStudiedLesson, userId: userId)
                }
                .navigationDestination(isPresented: $navigateToDrill) {
                    FlashcardDrillView(
                        languageCode: viewModel.selectedLanguageCode ?? "en",
                        userId: userId,
                        dueOnly: true
                    )
                }
        }
    }

    // Extracted to reduce complexity for the Swift compiler
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    topSection
                    middleSection
                    topicLessonSection
                    bottomSection
                }
                .padding(.top)
            }
            
            // Loading indicator overlay
            if viewModel.isLoading {
                ZStack {
                    Color(.systemBackground).opacity(0.7)
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            
            // Error message overlay
            if let error = viewModel.errorMessage {
                VStack {
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                    
                    Button("Retry") {
                        Task { await viewModel.loadInitialContent() }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Home")
        .onAppear {
            Task {
                await statsViewModel.fetchProfileStats(userId: userId)
                await viewModel.loadInitialContent()
                dueCardCount = await viewModel.getDueCardCount(for: userId)
            }
        }
    }

    // MARK: - Extracted Sections

    @ViewBuilder private var topSection: some View {
        VStack(spacing: 16) {
            streakView
            dailyXPView
        }
        .padding(.horizontal)
    }

    private var streakView: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(red: 255/255, green: 159/255, blue: 28/255).opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 28/255))
            }
            VStack(alignment: .leading) {
                Text("\(statsViewModel.streak) Day Streak")
                    .font(.headline)
                Text("Keep it going!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var dailyXPView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Daily XP Goal")
                    .font(.headline)
                Spacer()
                Text("\(dailyXP)/\(dailyXPGoal) XP")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0, green: 191/255, blue: 255/255))
            }
            ProgressView(value: Float(dailyXP), total: Float(dailyXPGoal))
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(Color(red: 0, green: 191/255, blue: 255/255))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    @ViewBuilder private var middleSection: some View {
        VStack(spacing: 16) {
            ActionCard(
                icon: "book.fill",
                title: "Resume Lesson",
                subtitle: viewModel.lastStudiedLesson?.title ?? "Start your learning journey",
                buttonText: "Continue",
                buttonAction: { navigateToLesson = true },
                backgroundColor: Color(red: 0, green: 191/255, blue: 255/255),
                progress: viewModel.lessonProgress
            )
            ActionCard(
                icon: "sparkles",
                title: "Flashcard Drill",
                subtitle: "\(dueCardCount) cards due for review",
                buttonText: "Start Drill",
                buttonAction: { navigateToDrill = true },
                backgroundColor: Color(red: 255/255, green: 159/255, blue: 28/255)
            )
            ActionCard(
                icon: "mic.fill",
                title: "Quick Talk Game",
                subtitle: "Practice your speaking skills",
                buttonText: "Find Match",
                buttonAction: {},
                backgroundColor: Color.purple
            )
        }
        .padding(.horizontal)
    }

    @ViewBuilder private var topicLessonSection: some View {
        if !viewModel.topics.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Topics")
                        .font(.headline)
                    Spacer()
                    Picker("Level", selection: $viewModel.selectedLevel) {
                        ForEach(viewModel.levels, id: \.id) { level in
                            Text(level.name).tag(level as SupabaseLanguageLevel?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.selectedLevel) { oldValue, newValue in
                        if let level = newValue {
                            Task { await viewModel.selectLevel(level) }
                        }
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.topics) { topic in
                            TopicCard(
                                topic: topic,
                                isSelected: viewModel.lastStudiedTopic?.id == topic.id,
                                onTap: { Task { await viewModel.loadLessonsForTopic(topic) } }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                if !viewModel.currentLessons.isEmpty {
                    Text("Lessons")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.currentLessons) { lesson in
                                LessonCard(
                                    lesson: lesson,
                                    isSelected: viewModel.lastStudiedLesson?.id == lesson.id,
                                    onTap: {
                                        viewModel.lastStudiedLesson = lesson
                                        navigateToLesson = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
            .padding(.horizontal)
        }
    }

    @ViewBuilder private var bottomSection: some View {
        VStack(spacing: 16) {
            aiTipView
            teacherBanner
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private var aiTipView: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .padding(12)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Circle())
                .padding(.trailing, 4)
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Tip of the Day")
                    .font(.headline)
                Text("Try practicing with short sentences before moving to longer ones.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var teacherBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill.viewfinder")
                    .font(.title)
                    .foregroundColor(.white)
                VStack(alignment: .leading) {
                    Text("Ready for the next level?")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Try your first live lesson with a teacher!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            Button(action: {}) {
                Text("Schedule Lesson")
                    .font(.headline)
                    .foregroundColor(Color(red: 0, green: 191/255, blue: 255/255))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0, green: 191/255, blue: 255/255), Color(red: 0, green: 191/255, blue: 255/255).opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// Topic Card View
struct TopicCard: View {
    let topic: ContentModels.Topic
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(topic.title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text(topic.canDoStatement)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 160, height: 120)
        .padding()
        .background(isSelected ? Color(red: 0, green: 191/255, blue: 255/255) : Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: isSelected ? Color(red: 0, green: 191/255, blue: 255/255).opacity(0.4) : Color.clear, radius: 5)
        .onTapGesture(perform: onTap)
    }
}

// Lesson Card View
struct LessonCard: View {
    let lesson: ContentModels.Lesson
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lesson.title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            Text(lesson.objective)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 140, height: 80)
        .padding()
        .background(isSelected ? Color(red: 255/255, green: 159/255, blue: 28/255) : Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: isSelected ? Color(red: 255/255, green: 159/255, blue: 28/255).opacity(0.4) : Color.clear, radius: 5)
        .onTapGesture(perform: onTap)
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonAction: () -> Void
    let backgroundColor: Color
    var progress: CGFloat? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(backgroundColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(backgroundColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Optional progress bar
            if let progress = progress {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 6)
                                .opacity(0.1)
                                .foregroundColor(backgroundColor)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 6)
                                .foregroundColor(backgroundColor)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        Text("\(Int(progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            
            Button(action: buttonAction) {
                Text(buttonText)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(backgroundColor)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// Lesson Detail View
struct LessonDetailView: View {
    let lesson: ContentModels.Lesson?
    let userId: String
    @State private var flashcards: [SupabaseFlashcard] = []
    @State private var isLoading = false
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let lesson = lesson {
                    // Lesson Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lesson.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(lesson.objective)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Divider()
                    }
                    .padding(.horizontal)
                    
                    // Lesson Content (could be markdown rendered in the future)
                    if let content = lesson.content, !content.isEmpty {
                        Text(content)
                            .padding(.horizontal)
                    }
                    
                    // Flashcards Section
                    if !flashcards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vocabulary")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 10)
                                .padding(.horizontal)
                            
                            ForEach(flashcards) { card in
                                FlashcardItemView(card: card)
                                    .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    Text("Select a lesson to begin learning")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            loadLessonContent()
        }
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color(.systemBackground).opacity(0.7)
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
        )
    }
    
    private func loadLessonContent() {
        guard let lesson = lesson else { return }
        
        isLoading = true
        
        Task {
            let cards = await FlashcardHomeViewModel().loadLesson(lesson)
            
            DispatchQueue.main.async {
                self.flashcards = cards
                self.isLoading = false
            }
        }
    }
}

// Flashcard Item in Lesson Detail
struct FlashcardItemView: View {
    let card: SupabaseFlashcard
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.word)
                        .font(.headline)
                    
                    if let ipa = card.ipa, !ipa.isEmpty {
                        Text(ipa)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(card.translation)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    
                    Text("Example:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(card.exampleSentence)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let grammar = card.grammarExplanation, !grammar.isEmpty {
                        Text("Grammar Note:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        
                        Text(grammar)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        let vm = ProfileStatsViewModel()
        vm.streak = 7
        vm.xp = 450
        vm.level = 3
        return FlashcardHomeView(
            drillViewModel: FlashcardDrillViewModel.mockForPreview(),
            statsViewModel: vm,
            userId: "preview-user"
        )
    }
} 