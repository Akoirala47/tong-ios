import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var statsViewModel = ProfileStatsViewModel()
    private let userId = "temp-user-id" // Should come from auth service
    
    init() {
        // Reset all placement tests by clearing UserDefaults keys
        // TEMPORARY CODE: Remove this after testing
        // resetAllPlacementTests() // Commented out to prevent reset on every launch
    }
    
    // TEMPORARY: Function to reset all placement tests
    private func resetAllPlacementTests() {
        print("[DEBUG] Resetting all placement tests")
        
        // Get all UserDefaults keys
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        
        // Find and remove all placement test keys
        for (key, _) in dictionary {
            if key.starts(with: "placement_test_completed_") {
                print("[DEBUG] Removing placement test key: \(key)")
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                HomeView(
                    drillViewModel: FlashcardDrillViewModel.mockForPreview(),
                    statsViewModel: statsViewModel,
                    userId: authViewModel.currentUserId ?? userId,
                    authViewModel: authViewModel
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            // Study Tab
            NavigationView {
                StudyTabView(
                    drillViewModel: FlashcardDrillViewModel(userId: authViewModel.currentUserId ?? userId), 
                    userId: authViewModel.currentUserId ?? userId
                )
            }
            .tabItem {
                Label("Study", systemImage: "book")
            }
            .tag(1)
            
            // Practice Tab
            NavigationView {
                PracticeView()
            }
            .tabItem {
                Label("Practice", systemImage: "mic")
            }
            .tag(2)
            
            // Compete Tab
            NavigationView {
                CompeteView()
            }
            .tabItem {
                Label("Compete", systemImage: "trophy")
            }
            .tag(3)
            
            // Profile Tab
            NavigationView {
                ProfileView(
                    statsViewModel: statsViewModel,
                    userId: authViewModel.currentUserId ?? userId,
                    authViewModel: authViewModel
                )
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Home Tab

struct HomeView: View {
    @ObservedObject var drillViewModel: FlashcardDrillViewModel
    @ObservedObject var statsViewModel: ProfileStatsViewModel
    @State private var streakDays = 5
    @State private var dailyXP = 30
    @State private var dailyXPGoal = 50
    @State private var isLoading = false
    @State private var languages: [SupabaseLanguage] = []
    @State private var userLanguages: [SupabaseUserLanguageLevel] = []
    @State private var dueCardCounts: [String: Int] = [:]
    
    private let userId: String
    private let authViewModel: AuthViewModel
    
    init(drillViewModel: FlashcardDrillViewModel, statsViewModel: ProfileStatsViewModel, userId: String, authViewModel: AuthViewModel) {
        self.drillViewModel = drillViewModel
        self.statsViewModel = statsViewModel
        self.userId = userId
        self.authViewModel = authViewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak and XP Section
                streakAndXPSection
                
                // Language cards
                languageCardsSection
                
                // Quick Actions
                quickActionsSection
                
                // Tip of the Day
                tipOfTheDaySection
                
                // Live Lesson Promo
                PromoCard(
                    title: "Try Your First Live Lesson",
                    description: "Book a 30-minute session with a native speaker",
                    buttonText: "Book Now",
                    backgroundColor: .orange
                )
            }
            .padding()
        }
        .navigationTitle("Home")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - UI Sections
    
    private var streakAndXPSection: some View {
        HStack(spacing: 16) {
            // Streak
            VStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                Text("\(streakDays) days")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            
            // XP Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily XP: \(dailyXP)/\(dailyXPGoal)")
                    .font(.subheadline)
                
                ProgressView(value: Double(dailyXP), total: Double(dailyXPGoal))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var languageCardsSection: some View {
        Group {
            if !languages.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Languages")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(languages) { language in
                                // Create local constants for the parameter values
                                let langCode = language.code
                                let dueCount = dueCardCounts[langCode] ?? 0
                                let level = userLanguages.first { $0.langCode == langCode }?.levelCode ?? "NL"
                                
                                LanguageCard(
                                    language: language,
                                    level: level,
                                    dueCount: dueCount
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            if let primaryLanguage = languages.first {
                let languageCode = primaryLanguage.code
                let cardCount = dueCardCounts[languageCode] ?? 0
                
                NavigationLink(destination: FlashcardReviewView(langCode: languageCode, userId: userId)) {
                    ActionCard(
                        icon: "doc.text",
                        title: "Resume \(primaryLanguage.name) Flashcards",
                        subtitle: "\(cardCount) cards due today",
                        buttonText: "Start Review",
                        buttonAction: {},
                        backgroundColor: Color.blue
                    )
                }
            } else {
                NavigationLink(destination: FlashcardReviewView(userId: userId)) {
                    ActionCard(
                        icon: "doc.text",
                        title: "Resume Flashcard Review",
                        subtitle: "5 cards due today",
                        buttonText: "Start Review",
                        buttonAction: {},
                        backgroundColor: Color.blue
                    )
                }
            }
            
            ActionCard(
                icon: "mic.fill",
                title: "Quick Talk Practice",
                subtitle: "Practice with AI tutor",
                buttonText: "Start Practice",
                buttonAction: { print("Quick Talk tapped") },
                backgroundColor: Color.green
            )
            
            ActionCard(
                icon: "checkmark.circle",
                title: "Daily Quiz",
                subtitle: "Test your knowledge",
                buttonText: "Start Quiz",
                buttonAction: { print("Daily Quiz tapped") },
                backgroundColor: Color.purple
            )
        }
    }
    
    private var tipOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tip of the Day")
                .font(.headline)
            
            Text("Try to use new vocabulary in context. Make a simple sentence with each new word you learn.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() {
        isLoading = true
        
        Task {
            // Load languages
            do {
                let fetchedLanguages = try await SupabaseService.shared.getLanguages()
                
                // Load user language levels
                let fetchedUserLevels = try await SupabaseService.shared.getUserLanguageLevels(userId: userId)
                
                // Load due card counts for each language
                var cardCounts: [String: Int] = [:]
                for language in fetchedLanguages {
                    do {
                        let cards = try await SupabaseService.shared.getDueFlashcards(for: userId, langCode: language.code)
                        cardCounts[language.code] = cards.count
                    } catch {
                        print("Error loading due cards for \(language.code): \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.languages = fetchedLanguages
                    self.userLanguages = fetchedUserLevels
                    self.dueCardCounts = cardCounts
                    self.isLoading = false
                }
            } catch {
                print("Error loading user data: \(error)")
                self.isLoading = false
            }
        }
    }
}

// Language card for home screen
struct LanguageCard: View {
    let language: SupabaseLanguage
    let level: String
    let dueCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Language name and flag
            HStack {
                Text(language.name)
                    .font(.headline)
                
                Spacer()
                
                Text(flagEmoji(for: language.code))
                    .font(.title)
            }
            
            Divider()
            
            // Level
            Text("Level: \(levelName(for: level))")
                .font(.subheadline)
            
            // Due cards
            HStack {
                Image(systemName: "rectangle.stack")
                    .foregroundColor(.blue)
                
                Text("\(dueCount) cards due")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 180, height: 140)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func flagEmoji(for languageCode: String) -> String {
        switch languageCode {
        case "es": return "🇪🇸"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "it": return "🇮🇹"
        case "pt": return "🇵🇹"
        case "ru": return "🇷🇺"
        case "ja": return "🇯🇵"
        case "zh": return "🇨🇳"
        case "ko": return "🇰🇷"
        case "ar": return "🇸🇦"
        default: return "🌐"
        }
    }
    
    private func levelName(for code: String) -> String {
        switch code {
        case "NL": return "Novice Low"
        case "NM": return "Novice Mid"
        case "NH": return "Novice High"
        case "IL": return "Intermediate Low"
        case "IM": return "Intermediate Mid"
        case "IH": return "Intermediate High"
        case "AL": return "Advanced Low"
        case "AM": return "Advanced Mid"
        case "AH": return "Advanced High"
        case "S": return "Superior"
        default: return code
        }
    }
}

// MARK: - Study Tab

// Removing the current StudyView implementation since we're using StudyTabView
// struct StudyView: View {
//     @State private var selectedSegment = 0
//     @State private var selectedLanguage = "es" // Default to Spanish
//     @State private var isLoading = false
//     @State private var languages: [SupabaseLanguage] = []
//     @State private var errorMessage: String? = nil
    
//     var body: some View {
//         VStack(spacing: 0) {
//             // Language Selector
//             languageSelectorView
            
//             // Segmented Control
//             Picker("Study Mode", selection: $selectedSegment) {
//                 Text("Lessons").tag(0)
//                 Text("Flashcards").tag(1)
//                 Text("Saved").tag(2)
//             }
//             .pickerStyle(SegmentedPickerStyle())
//             .padding()
            
//             // Content based on selected segment
//             contentView
//         }
//         .navigationTitle("Study")
//     }
    
//     // MARK: - Extracted Views
    
//     private var languageSelectorView: some View {
//         ScrollView(.horizontal, showsIndicators: false) {
//             if isLoading {
//                 loadingView
//             } else if errorMessage != nil {
//                 errorView
//             } else {
//                 languageButtons
//             }
//         }
//         .padding(.vertical, 8)
//         .onAppear {
//             loadLanguages()
//         }
//     }
    
//     private var loadingView: some View {
//         HStack {
//             ProgressView()
//                 .padding()
//             Text("Loading languages...")
//                 .font(.subheadline)
//         }
//         .padding(.horizontal)
//     }
    
//     private var errorView: some View {
//         HStack {
//             Image(systemName: "exclamationmark.triangle")
//                 .foregroundColor(.orange)
//             Text(errorMessage ?? "Error loading languages")
//                 .font(.subheadline)
//                 .foregroundColor(.secondary)
//             Button("Retry") {
//                 loadLanguages()
//             }
//             .font(.caption)
//             .padding(.horizontal, 10)
//             .padding(.vertical, 5)
//             .background(Color.blue)
//             .foregroundColor(.white)
//             .cornerRadius(8)
//         }
//         .padding(.horizontal)
//     }
    
//     private var languageButtons: some View {
//         HStack(spacing: 12) {
//             ForEach(languages) { language in
//                 languageButton(for: language)
//             }
//         }
//         .padding(.horizontal)
//     }
    
//     private func languageButton(for language: SupabaseLanguage) -> some View {
//         Button(action: {
//             selectedLanguage = language.code
//         }) {
//             Text(language.name)
//                 .font(.headline)
//                 .padding(.vertical, 8)
//                 .padding(.horizontal, 16)
//                 .background(
//                     Capsule()
//                         .fill(selectedLanguage == language.code ? Color.blue : Color.blue.opacity(0.1))
//                 )
//                 .foregroundColor(selectedLanguage == language.code ? .white : .blue)
//         }
//     }
    
//     private var contentView: some View {
//         ScrollView {
//             if selectedSegment == 0 {
//                 lessonsView
//             } else if selectedSegment == 1 {
//                 flashcardsView
//             } else {
//                 savedView
//             }
//         }
//     }
    
//     private var lessonsView: some View {
//         VStack(spacing: 16) {
//             ForEach(1...5, id: \.self) { num in
//                 StudyLessonCard(
//                     title: "Lesson \(num)",
//                     subtitle: sampleLessonSubtitles[num-1],
//                     progress: Double.random(in: 0...1),
//                     lessonId: "lesson-\(num)"
//                 )
//             }
//         }
//         .padding()
//     }
    
//     private var flashcardsView: some View {
//         VStack(spacing: 16) {
//             NavigationLink(destination: FlashcardReviewView(langCode: selectedLanguage)) {
//                 StudyActionCard(
//                     title: "Start Flashcard Review",
//                     subtitle: "Review today's due cards",
//                     iconName: "rectangle.fill.on.rectangle.fill",
//                     color: Color.blue
//                 )
//             }
            
//             Text("Flashcard Decks")
//                 .font(.headline)
//                 .frame(maxWidth: .infinity, alignment: .leading)
//                 .padding(.horizontal)
            
//             ForEach(sampleFlashcardDecks, id: \.title) { deck in
//                 FlashcardDeckRow(
//                     title: deck.title,
//                     count: deck.count,
//                     mastered: deck.mastered
//                 )
//             }
//         }
//         .padding()
//     }
    
//     private var savedView: some View {
//         VStack(spacing: 20) {
//             Text("You haven't saved any content yet")
//                 .font(.headline)
//                 .foregroundColor(.secondary)
            
//             Image(systemName: "bookmark.slash")
//                 .font(.system(size: 50))
//                 .foregroundColor(.secondary)
//                 .padding()
            
//             Text("Save lessons or flashcards to access them quickly")
//                 .font(.subheadline)
//                 .foregroundColor(.secondary)
//                 .multilineTextAlignment(.center)
//                 .padding(.horizontal)
//         }
//         .frame(maxWidth: .infinity, maxHeight: .infinity)
//         .padding()
//     }
    
//     // MARK: - Data Loading
    
//     private func loadLanguages() {
//         isLoading = true
//         errorMessage = nil
        
//         Task {
//             do {
//                 let fetchedLanguages = try await SupabaseService.shared.getLanguages()
//                 DispatchQueue.main.async {
//                     self.languages = fetchedLanguages
                    
//                     // Select the first language if none is selected
//                     if self.languages.count > 0 && self.selectedLanguage.isEmpty {
//                         self.selectedLanguage = self.languages[0].code
//                     }
                    
//                     self.isLoading = false
//                 }
//             } catch {
//                 DispatchQueue.main.async {
//                     self.errorMessage = "Failed to load languages"
//                     self.isLoading = false
//                 }
//                 print("Error loading languages: \(error)")
//             }
//         }
//     }
    
//     let sampleLessonSubtitles = [
//         "Greetings and Introductions",
//         "Basic Verbs and Questions",
//         "Food and Dining",
//         "Asking for Directions",
//         "Describing Your Family"
//     ]
    
//     let sampleFlashcardDecks = [
//         (title: "Beginner Vocabulary", count: 50, mastered: 10),
//         (title: "Common Phrases", count: 30, mastered: 15),
//         (title: "Travel Words", count: 25, mastered: 5),
//         (title: "Food and Dining", count: 40, mastered: 8)
//     ]
// }

// MARK: - Practice Tab

// MARK: - Compete Tab

// This entire struct definition needs to be removed.

// MARK: - Profile Tab

// This entire struct definition needs to be removed.

// MARK: - Supporting Views

struct PromoCard: View {
    var title: String
    var description: String
    var buttonText: String
    var backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Button(action: {}) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(backgroundColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct FlashcardDeckRow: View {
    var title: String
    var count: Int
    var mastered: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text("\(mastered)/\(count) mastered")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct RecordedClip: Identifiable {
    let id: String
    let duration: Double
    let date: Date
}

struct RecordingRow: View {
    var clip: RecordedClip
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Recording")
                    .font(.headline)
                
                Text("\(timeString(clip.duration)) • \(dateString(clip.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    func timeString(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Supporting Views for StudyView

// Simple placeholder for LessonCard in StudyView
// struct StudyLessonCard: View {
//     var title: String
//     var subtitle: String
//     var progress: Double
//     var lessonId: String
    
//     var body: some View {
//         NavigationLink(destination: Text("Lesson Content: \(title)").navigationTitle(title)) {
//             VStack(alignment: .leading, spacing: 8) {
//                 Text(title)
//                     .font(.headline)
                
//                 Text(subtitle)
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
                
//                 ProgressView(value: progress)
//                     .progressViewStyle(LinearProgressViewStyle())
//                     .accentColor(Color.blue)
                
//                 Text("\(Int(progress * 100))% Complete")
//                     .font(.caption)
//                     .foregroundColor(.secondary)
//             }
//             .padding()
//             .background(Color(.systemBackground))
//             .cornerRadius(12)
//             .shadow(radius: 2)
//         }
//         .buttonStyle(PlainButtonStyle())
//     }
// }

// Simple placeholder for ActionCard in StudyView
// struct StudyActionCard: View {
//     var title: String
//     var subtitle: String
//     var iconName: String
//     var color: Color
    
//     var body: some View {
//         HStack(spacing: 16) {
//             // Icon
//             Image(systemName: iconName)
//                 .font(.system(size: 24))
//                 .foregroundColor(.white)
//                 .frame(width: 48, height: 48)
//                 .background(color)
//                 .cornerRadius(10)
            
//             // Text
//             VStack(alignment: .leading, spacing: 4) {
//                 Text(title)
//                     .font(.headline)
//                     .foregroundColor(.primary)
                
//                 Text(subtitle)
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
//             }
            
//             Spacer()
            
//             Image(systemName: "chevron.right")
//                 .foregroundColor(.secondary)
//         }
//         .padding()
//         .background(Color(.systemBackground))
//         .cornerRadius(12)
//         .shadow(radius: 2)
//     }
// } 