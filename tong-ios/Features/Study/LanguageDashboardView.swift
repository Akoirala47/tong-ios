import SwiftUI

// Extension to convert between SupabaseLanguageLevel and LevelData
extension SupabaseLanguageLevel {
    func toLevelData() -> LevelData {
        return LevelData(code: self.code, name: self.name, order: self.ordinal)
    }
}

extension LevelData {
    func toSupabaseLanguageLevel() -> SupabaseLanguageLevel {
        return SupabaseLanguageLevel(id: 0, code: self.code, name: self.name, ordinal: self.order, languageId: 0)
    }
}

struct LanguageDashboardView: View {
    let languageCode: String
    let userId: String
    
    @StateObject private var viewModel: LanguageDashboardViewModel
    @State private var showPlacementTest = false
    @State private var selectedStudyMode: StudyMode = .learn
    
    // Navigation states
    @State private var activeNavigation: NavigationDestination? = nil
    
    // Initializer to set up the viewModel
    init(languageCode: String, userId: String) {
        self.languageCode = languageCode
        self.userId = userId
        // Initialize viewModel in the init. This is a temporary placeholder
        // as we need to fetch the SupabaseLanguage object first. This will be moved to onAppear.
        // The actual initialization with a fetched language object will be done in .onAppear
        // to handle the async fetching of the SupabaseLanguage object.
        // For the @StateObject to be initialized here, we give it a temporary placeholder.
        // This will be immediately overwritten in .onAppear.
        // A better pattern might involve an intermediate loading state or passing the SupabaseLanguage object directly.
        _viewModel = StateObject(wrappedValue: LanguageDashboardViewModel(language: SupabaseLanguage(id: 0, code: "loading", name: "Loading..."), userId: userId))
    }
    
    // Define navigation destinations
    enum NavigationDestination: Identifiable, Hashable {
        case learnMode(languageCode: String, userId: String)
        case reviewMode(languageCode: String, userId: String)
        case bossBattle(languageCode: String, userId: String, level: SupabaseLanguageLevel)
        case flashcardReview(languageCode: String, userId: String, dueOnly: Bool)
        
        var id: String {
            switch self {
            case .learnMode: return "learn"
            case .reviewMode: return "review"
            case .bossBattle: return "boss"
            case .flashcardReview(_, _, let dueOnly): return "flashcards-\(dueOnly ? "due" : "all")"
            }
        }
        
        // Implement Hashable
        func hash(into hasher: inout Hasher) {
            switch self {
            case .learnMode(let languageCode, let userId):
                hasher.combine("learnMode")
                hasher.combine(languageCode)
                hasher.combine(userId)
            case .reviewMode(let languageCode, let userId):
                hasher.combine("reviewMode")
                hasher.combine(languageCode)
                hasher.combine(userId)
            case .bossBattle(let languageCode, let userId, let level):
                hasher.combine("bossBattle")
                hasher.combine(languageCode)
                hasher.combine(userId)
                hasher.combine(level)
            case .flashcardReview(let languageCode, let userId, let dueOnly):
                hasher.combine("flashcardReview")
                hasher.combine(languageCode)
                hasher.combine(userId)
                hasher.combine(dueOnly)
            }
        }
        
        // Implement Equatable
        static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
            switch (lhs, rhs) {
            case (.learnMode(let lhsLang, let lhsUserId), .learnMode(let rhsLang, let rhsUserId)):
                return lhsLang == rhsLang && lhsUserId == rhsUserId
            case (.reviewMode(let lhsLang, let lhsUserId), .reviewMode(let rhsLang, let rhsUserId)):
                return lhsLang == rhsLang && lhsUserId == rhsUserId
            case (.bossBattle(let lhsLang, let lhsUserId, let lhsLevel), .bossBattle(let rhsLang, let rhsUserId, let rhsLevel)):
                return lhsLang == rhsLang && lhsUserId == rhsUserId && lhsLevel == rhsLevel
            case (.flashcardReview(let lhsLang, let lhsUserId, let lhsDue), .flashcardReview(let rhsLang, let rhsUserId, let rhsDue)):
                return lhsLang == rhsLang && lhsUserId == rhsUserId && lhsDue == rhsDue
            default:
                return false
            }
        }
    }
    
    enum StudyMode: String, CaseIterable, Identifiable {
        case learn = "Learn"
        case review = "Review"
        case bossBattle = "Boss Battle"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .learn: return "book.fill"
            case .review: return "arrow.counterclockwise"
            case .bossBattle: return "crown.fill"
            }
        }
        
        var description: String {
            switch self {
            case .learn:
                return "Introduce new grammar & vocabulary with 8-12 items"
            case .review:
                return "SR review queue for long-term retention of learned items"
            case .bossBattle:
                return "Timed, mixed-modality challenge to unlock next level"
            }
        }
        
        var color: Color {
            switch self {
            case .learn: return Color(hex: "00BFFF") // Arctic Blue
            case .review: return Color(hex: "8A2BE2") // Purple
            case .bossBattle: return Color(hex: "FF9F1C") // Warm Orange
            }
        }
        
        var isLocked: Bool {
            switch self {
            case .learn: return false // Always unlocked
            case .review: return false // For now, unlock all modes
            case .bossBattle: return false // For now, unlock all modes
            }
        }
    }
    
    var languageName: String {
        switch languageCode {
        case "es": return "Spanish"
        case "fr": return "French"
        case "jp": return "Japanese"
        case "zh": return "Chinese"
        default: return "Language"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with language info and proficiency
                languageHeaderView
                
                // ACTFL Progress rings showing current level and completed levels
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACTFL Proficiency")
                        .font(.headline)
                        .padding(.leading, 4)
                        
                    ProgressRingsView(
                        currentLevelData: viewModel.currentLevel?.toLevelData(),
                        completedLevelData: viewModel.completedLevels.map { $0.toLevelData() }
                    )
                    .frame(height: 120)
                }
                .padding(.vertical, 8)
                
                // Study modes
                studyModesView
                
                // Flashcards for current level
                flashcardsView
            }
            .padding()
        }
        .navigationTitle(languageName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDataOnAppear()
        }
        .fullScreenCover(isPresented: $showPlacementTest) {
            placementTestView
        }
        // Add navigation destination handlers - Fix to properly activate navigation links
        .onChange(of: activeNavigation) { oldValue, newValue in
            if newValue != nil {
                print("[DEBUG] Navigation activated to: \(String(describing: newValue))")
            }
        }
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .learnMode(_, let userId):
                LearnModeView(languageCode: languageCode, userId: userId, forPreview: false)
            case .reviewMode(_, let userId):
                ReviewModeView(languageCode: languageCode, userId: userId)
            case .bossBattle(_, _, let level):
                BossBattleView(
                    language: languageName,
                    level: level,
                    topic: "General" // Pass a default topic string instead of nil
                )
            case .flashcardReview(let languageCode, _, _):
                FlashcardReviewView(langCode: languageCode)
            }
        }
        // Add navigation links for each destination
        .background(learnModeNavigationLink)
        .background(reviewModeNavigationLink)
        .background(bossBattleNavigationLink)
        .background(allFlashcardsNavigationLink)
        .background(dueFlashcardsNavigationLink)
    }
    
    // Extracted method for onAppear logic to simplify the complex expression
    private func loadDataOnAppear() {
            Task {
            // Fetch the SupabaseLanguage object based on languageCode
            await fetchLanguageAndInitViewModel()
                
                // Debug print to see the current values
                print("[DEBUG] Language: \(languageCode), needsPlacementTest: \(viewModel.needsPlacementTest), currentLevel: \(String(describing: viewModel.currentLevel))")
                
            // Check if placement test is needed
            await checkPlacementTestStatus()
        }
    }
    
    // Fetch language and initialize/update the view model
    private func fetchLanguageAndInitViewModel() async {
        do {
            let languages = try await SupabaseService.shared.getLanguages()
            if let language = languages.first(where: { $0.code == languageCode }) {
                // Update the current language in the viewModel
                await MainActor.run {
                    if viewModel.currentLanguage.code == "loading" {
                        // Instead of directly assigning to wrappedValue, create a temporary local variable
                        // and assign the view model state from it
                        let newViewModel = LanguageDashboardViewModel(language: language, userId: userId)
                        viewModel.currentLanguage = newViewModel.currentLanguage
                        viewModel.languageLevels = newViewModel.languageLevels
                        viewModel.selectedLevel = newViewModel.selectedLevel
                        viewModel.topicsByLevel = newViewModel.topicsByLevel
                        viewModel.lessonsByTopic = newViewModel.lessonsByTopic
                        viewModel.needsPlacementTest = newViewModel.needsPlacementTest
                        viewModel.currentLevel = newViewModel.currentLevel
                        viewModel.completedLevels = newViewModel.completedLevels
                        viewModel.upcomingContent = newViewModel.upcomingContent
                        viewModel.cardsStudied = newViewModel.cardsStudied
                        viewModel.daysStreak = newViewModel.daysStreak
                        viewModel.estimatedHours = newViewModel.estimatedHours
                        viewModel.dueCardCount = newViewModel.dueCardCount
                        viewModel.globalProgress = newViewModel.globalProgress
                    } else {
                        // View model already initialized - just update the current language
                        viewModel.currentLanguage = language
                    }
                }
                
                // This call doesn't exist in the view model
                // await viewModel.loadUserLanguageLevel(userId: userId, languageCode: languageCode)
            } else {
                print("[ERROR] Could not find language with code: \(languageCode) to initialize LanguageDashboardViewModel")
            }
        } catch {
            print("[ERROR] Failed to fetch languages: \(error)")
        }
    }
    
    // Check if we need to show the placement test
    private func checkPlacementTestStatus() async {
        // Double-check UserDefaults to ensure we don't show test unnecessarily
        let testCompletionKey = "placement_test_completed_\(languageCode)_\(userId)"
        let hasCompletedTest = UserDefaults.standard.bool(forKey: testCompletionKey)
        
        print("[DEBUG] Checking placement test status - hasCompletedTest: \(hasCompletedTest)")
        
        // Always ensure we have a current level if test is completed but level is nil
        await MainActor.run {
            if hasCompletedTest && viewModel.currentLevel == nil {
                print("[DEBUG] Test is completed but no level is set, setting default level")
                if let firstLevel = viewModel.languageLevels.first {
                    viewModel.currentLevel = firstLevel
                    viewModel.completedLevels = []
                    viewModel.calculateGlobalProgress()
                    viewModel.needsPlacementTest = false
                }
            }
        }
        
        // Only show placement test if not completed in UserDefaults
        await MainActor.run {
            if !hasCompletedTest {
                print("[DEBUG] Showing placement test since it hasn't been completed: \(languageCode)")
                viewModel.needsPlacementTest = true
                showPlacementTest = true
            } else {
                print("[DEBUG] Not showing placement test - already completed")
                showPlacementTest = false
            }
        }
    }
    
    private var languageHeaderView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Language flag/icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "00BFFF").opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(String(languageName.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "00BFFF"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let level = viewModel.currentLevel {
                        Text(level.name)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Take placement test to start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Global progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.globalProgress))
                        .stroke(Color(hex: "00BFFF"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(viewModel.globalProgress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            // Stats row
            HStack(spacing: 24) {
                Spacer()
                
                VStack {
                    Text("\(viewModel.cardsStudied)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(viewModel.daysStreak)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("\(viewModel.estimatedHours)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var studyModesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Modes")
                .font(.headline)
                .padding(.leading, 4)
            
            TabView(selection: $selectedStudyMode) {
                ForEach(StudyMode.allCases) { mode in
                    studyModeCard(mode)
                        .tag(mode)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
        }
    }
    
    private func studyModeCard(_ mode: StudyMode) -> some View {
        Button(action: {
            print("[DEBUG] Tapped study mode: \(mode.rawValue)")
            if !mode.isLocked {
                startStudySession(mode: mode)
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Mode icon
                    ZStack {
                        Circle()
                            .fill(mode.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: mode.icon)
                            .foregroundColor(mode.color)
                            .font(.system(size: 24))
                    }
                    
                    Spacer()
                    
                    // Lock indicator
                    if mode.isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(mode.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(mode.isLocked ? .gray : .primary)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(mode.isLocked ? .gray : .secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Start button
                HStack {
                    Spacer()
                    
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(mode.isLocked ? Color.gray : mode.color)
                        .cornerRadius(20)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .opacity(mode.isLocked ? 0.7 : 1.0)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle()) // Use plain button style for better tap handling
        .disabled(mode.isLocked)
    }
    
    private var flashcardsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Flashcards")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.dueCardCount) due today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.leading, 4)
            
            if viewModel.currentLevel == nil {
                Text("Complete your placement test to see flashcards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
            } else {
                // Flashcard preview
                Button(action: {
                    print("[DEBUG] Tapped flashcard preview")
                    // Navigate to flashcard drill view with all cards
                    navigateToFlashcards(languageCode: languageCode, userId: userId, dueOnly: false)
                }) {
                    ZStack {
                        // Card background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        // Card content
                        VStack(spacing: 20) {
                            Text(viewModel.currentLevel?.flashcardPreviewWord ?? "Hola")
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Tap to review")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .frame(height: 150)
                }
                .buttonStyle(PlainButtonStyle()) // Use plain button style for better tap handling
                
                // Flashcard stats & review button
                HStack {
                    Button(action: {
                        print("[DEBUG] Tapped Review All")
                        // Navigate to full flashcard review
                        navigateToFlashcards(languageCode: languageCode, userId: userId, dueOnly: false)
                    }) {
                        Text("Review All")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "00BFFF"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        print("[DEBUG] Tapped Due Cards")
                        // Navigate to due cards only
                        navigateToFlashcards(languageCode: languageCode, userId: userId, dueOnly: true)
                    }) {
                        Text("Due Cards")
                            .font(.headline)
                            .foregroundColor(Color(hex: "00BFFF"))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "00BFFF").opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func startStudySession(mode: StudyMode) {
        print("[DEBUG] Starting study session for mode: \(mode.rawValue)")
        
        // Set the navigation tag directly
        switch mode {
        case .learn:
            let destination = NavigationDestination.learnMode(languageCode: languageCode, userId: userId)
            activeNavigation = destination
            
        case .review:
            let destination = NavigationDestination.reviewMode(languageCode: languageCode, userId: userId)
            activeNavigation = destination
            
        case .bossBattle:
            if let level = viewModel.currentLevel {
                let destination = NavigationDestination.bossBattle(languageCode: languageCode, userId: userId, level: level)
                activeNavigation = destination
            } else {
                print("[ERROR] Cannot start boss battle without a current level")
            }
        }
    }
    
    private func navigateToFlashcards(languageCode: String, userId: String, dueOnly: Bool) {
        activeNavigation = .flashcardReview(languageCode: languageCode, userId: userId, dueOnly: dueOnly)
    }
    
    // MARK: - Navigation Views
    
    private var placementTestView: some View {
        PlacementTestView(
            languageCode: languageCode,
            userId: userId,
            onComplete: { level in
                // Convert from LevelData to SupabaseLanguageLevel 
                let supabaseLevel = level.toSupabaseLanguageLevel()
                viewModel.currentLevel = supabaseLevel
                viewModel.needsPlacementTest = false
                
                // Save completion status to UserDefaults here too as a backup
                let testCompletionKey = "placement_test_completed_\(languageCode)_\(userId)"
                UserDefaults.standard.set(true, forKey: testCompletionKey)
                
                Task {
                    await viewModel.saveUserLanguageLevel(
                        userId: userId,
                        languageCode: languageCode, 
                        level: LanguageLevel(rawValue: level.code) ?? .noviceLow
                    )
                }
            }
        )
    }
    
    private var learnModeNavigationLink: some View {
        NavigationLink(value: NavigationDestination.learnMode(languageCode: languageCode, userId: userId)) {
            EmptyView()
        }
        .hidden()
    }
    
    private var reviewModeNavigationLink: some View {
        NavigationLink(value: NavigationDestination.reviewMode(languageCode: languageCode, userId: userId)) {
            EmptyView()
        }
        .hidden()
    }
    
    private var bossBattleNavigationLink: some View {
        Group {
            if let level = viewModel.currentLevel {
                NavigationLink(value: NavigationDestination.bossBattle(languageCode: languageCode, userId: userId, level: level)) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }
    
    private var allFlashcardsNavigationLink: some View {
        NavigationLink(value: NavigationDestination.flashcardReview(languageCode: languageCode, userId: userId, dueOnly: false)) {
            EmptyView()
        }
        .hidden()
    }
    
    private var dueFlashcardsNavigationLink: some View {
        NavigationLink(value: NavigationDestination.flashcardReview(languageCode: languageCode, userId: userId, dueOnly: true)) {
            EmptyView()
        }
        .hidden()
    }
}

// Removed placeholder ReviewModeView. The primary definition is in Features/Study/ReviewModeView.swift
// struct ReviewModeView: View {
//     let languageCode: String
//     let userId: String
//
//     var body: some View {
//         VStack(spacing: 20) {
//             Text("Review Mode")
//                 .font(.largeTitle)
//                 .fontWeight(.bold)
//
//             Text("SRS review queue for long-term retention of learned items")
//                 .font(.headline)
//                 .multilineTextAlignment(.center)
//                 .padding()
//
//             // Placeholder for actual content
//             Text("This is where you'll review previous content")
//                 .padding()
//
//             Spacer()
//         }
//         .padding()
//         .navigationTitle("Review")
//     }
// }

#Preview {
    NavigationStack {
        LanguageDashboardView(languageCode: "es", userId: "preview-user")
    }
} 
