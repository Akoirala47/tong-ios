import SwiftUI

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
                        currentLevel: viewModel.currentLevel,
                        completedLevels: viewModel.completedLevels
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
            Task {
                // Fetch the SupabaseLanguage object based on languageCode
                let languages = try? await SupabaseService.shared.getLanguages()
                if let language = languages?.first(where: { $0.code == languageCode }) {
                    // Now properly initialize or update the viewModel with the correct language
                    // Since @StateObject should be initialized once, we re-assign to its properties if needed
                    // or ensure this onAppear logic correctly sets up the already initialized viewModel.
                    // For this case, since we used a placeholder, we can assign a new instance if absolutely necessary,
                    // but ideally, the viewModel would have an internal method to load data based on language.
                    // Given the current ViewModel structure, replacing it might be okay here IF this onAppear runs once.
                    // However, the most robust way is to have an empty state in ViewModel and then load.
                    // Let's assume the ViewModel can handle being updated or re-kicked-off.
                    viewModel.currentLanguage = language // Update if viewModel is already initialized
                    // Or, if direct replacement is acceptable for @StateObject in this specific scenario:
                    // self.viewModel = LanguageDashboardViewModel(language: language, userId: userId) 
                    // --> This direct replacement of @StateObject is generally not recommended after initial view init.
                    // --> ViewModel should have a method like `func loadData(for language: SupabaseLanguage, userId: String)`

                    // For now, let's update the existing viewModel's properties if possible, or re-initialize if simpler and context allows
                    // Given the viewModel's init already kicks off loading, creating a new one ensures correct initial state.
                    // This is a common pattern if the initial @StateObject was a placeholder.
                    // To avoid issues, ensure this onAppear logic that replaces the viewModel runs reliably once for setup.
                    if viewModel.currentLanguage.code == "loading" { // Check if it's the placeholder
                        _viewModel.wrappedValue = LanguageDashboardViewModel(language: language, userId: userId)
                    }

                await viewModel.loadUserLanguageLevel(userId: userId, languageCode: languageCode)
                } else {
                    print("[ERROR] Could not find language with code: \(languageCode) to initialize LanguageDashboardViewModel")
                    // Handle error: show an error message or dismiss the view
                }
                
                // Debug print to see the current values
                print("[DEBUG] Language: \(languageCode), needsPlacementTest: \(viewModel.needsPlacementTest), currentLevel: \(String(describing: viewModel.currentLevel))")
                
                // Double-check UserDefaults to ensure we don't show test unnecessarily
                let testCompletionKey = "placement_test_completed_\(languageCode)_\(userId)"
                let hasCompletedTest = UserDefaults.standard.bool(forKey: testCompletionKey)
                
                // Only show placement test if explicitly needed AND no level is set AND not completed in UserDefaults
                if viewModel.needsPlacementTest && viewModel.currentLevel == nil && !hasCompletedTest {
                    print("[DEBUG] Showing placement test for language: \(languageCode)")
                    showPlacementTest = true
                } else {
                    print("[DEBUG] Not showing placement test - needsPlacementTest: \(viewModel.needsPlacementTest), currentLevel: \(viewModel.currentLevel != nil), hasCompletedTest: \(hasCompletedTest)")
                    showPlacementTest = false
                }
            }
        }
        .fullScreenCover(isPresented: $showPlacementTest) {
            PlacementTestView(
                languageCode: languageCode,
                userId: userId,
                onComplete: { level in
                    viewModel.currentLevel = level
                    viewModel.needsPlacementTest = false
                    
                    // Save completion status to UserDefaults here too as a backup
                    let testCompletionKey = "placement_test_completed_\(languageCode)_\(userId)"
                    UserDefaults.standard.set(true, forKey: testCompletionKey)
                    
                    Task {
                        await viewModel.saveUserLanguageLevel(
                            userId: userId,
                            languageCode: languageCode, 
                            level: level
                        )
                    }
                }
            )
        }
        // Add navigation links for each destination
        .background(
            NavigationLink(
                tag: NavigationDestination.learnMode(languageCode: languageCode, userId: userId),
                selection: $activeNavigation,
                destination: { 
                    // This would be your learn mode view
                    LearnModeView(languageCode: languageCode, userId: userId)
                },
                label: { EmptyView() }
            )
        )
        .background(
            NavigationLink(
                tag: NavigationDestination.reviewMode(languageCode: languageCode, userId: userId),
                selection: $activeNavigation,
                destination: { 
                    // This would be your review mode view
                    ReviewModeView(languageCode: languageCode, userId: userId)
                },
                label: { EmptyView() }
            )
        )
        .background(
            Group {
                if let level = viewModel.currentLevel {
                    NavigationLink(
                        tag: NavigationDestination.bossBattle(languageCode: languageCode, userId: userId, level: level),
                        selection: $activeNavigation,
                        destination: { 
                            // Create a custom version that passes parameters
                            BossBattleView(
                                languageCode: languageCode,
                                userId: userId,
                                level: level
                            )
                        },
                        label: { EmptyView() }
                    )
                }
            }
        )
        .background(
            NavigationLink(
                tag: NavigationDestination.flashcardReview(languageCode: languageCode, userId: userId, dueOnly: false),
                selection: $activeNavigation,
                destination: { 
                    // This would be your flashcard review view for all cards
                    FlashcardDrillView(languageCode: languageCode, userId: userId, dueOnly: false)
                },
                label: { EmptyView() }
            )
        )
        .background(
            NavigationLink(
                tag: NavigationDestination.flashcardReview(languageCode: languageCode, userId: userId, dueOnly: true),
                selection: $activeNavigation,
                destination: { 
                    // This would be your flashcard review view for due cards only
                    FlashcardDrillView(languageCode: languageCode, userId: userId, dueOnly: true)
                },
                label: { EmptyView() }
            )
        )
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
                        Text(level.fullName)
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
        .buttonStyle(PlainButtonStyle()) // Use plain button style to ensure proper tap area
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
        
        switch mode {
        case .learn:
            activeNavigation = .learnMode(languageCode: languageCode, userId: userId)
        case .review:
            activeNavigation = .reviewMode(languageCode: languageCode, userId: userId)
        case .bossBattle:
            if let level = viewModel.currentLevel {
                // Use the new navigation approach for BossBattle
                activeNavigation = .bossBattle(languageCode: languageCode, userId: userId, level: level)
            } else {
                print("[ERROR] Cannot start boss battle without a current level")
            }
        }
    }
    
    private func navigateToFlashcards(languageCode: String, userId: String, dueOnly: Bool) {
        activeNavigation = .flashcardReview(languageCode: languageCode, userId: userId, dueOnly: dueOnly)
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