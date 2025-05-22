import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            // Study Tab
            NavigationView {
                StudyView()
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
                ProfileView()
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
    @State private var streakDays = 5
    @State private var dailyXP = 30
    @State private var dailyXPGoal = 50
    @State private var isLoading = false
    @State private var languages: [SupabaseLanguage] = []
    @State private var userLanguages: [SupabaseUserLanguageLevel] = []
    @State private var dueCardCounts: [String: Int] = [:]
    
    private let userId = "temp-user-id" // Should come from auth service
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak and XP Section
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
                
                // Language cards
                if !languages.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Languages")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(languages) { language in
                                    let dueCount = dueCardCounts[language.code] ?? 0
                                    let level = userLanguages.first { $0.langCode == language.code }?.levelCode ?? "NL"
                                    
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
                
                // Quick Actions
                VStack(spacing: 16) {
                    if let primaryLanguage = languages.first {
                        NavigationLink(destination: FlashcardReviewView(langCode: primaryLanguage.code)) {
                            ActionCard(
                                title: "Resume \(primaryLanguage.name) Flashcards",
                                subtitle: "\(dueCardCounts[primaryLanguage.code] ?? 0) cards due today",
                                iconName: "doc.text",
                                color: .blue
                            )
                        }
                    } else {
                        NavigationLink(destination: FlashcardReviewView()) {
                            ActionCard(
                                title: "Resume Flashcard Review",
                                subtitle: "5 cards due today",
                                iconName: "doc.text",
                                color: .blue
                            )
                        }
                    }
                    
                    ActionCard(
                        title: "Quick Talk Practice",
                        subtitle: "Practice with AI tutor",
                        iconName: "mic.fill",
                        color: .green
                    )
                    
                    ActionCard(
                        title: "Daily Quiz",
                        subtitle: "Test your knowledge",
                        iconName: "checkmark.circle",
                        color: .purple
                    )
                }
                
                // Tip of the Day
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

struct StudyView: View {
    @State private var selectedSegment = 0
    @State private var selectedLanguage = "es" // Default to Spanish
    @State private var isLoading = false
    @State private var languages: [SupabaseLanguage] = []
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Language Selector
            ScrollView(.horizontal, showsIndicators: false) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading languages...")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                } else if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            loadLanguages()
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                } else {
                    HStack(spacing: 12) {
                        ForEach(languages) { language in
                            Button(action: {
                                selectedLanguage = language.code
                            }) {
                                Text(language.name)
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Capsule()
                                            .fill(selectedLanguage == language.code ? Color.blue : Color.blue.opacity(0.1))
                                    )
                                    .foregroundColor(selectedLanguage == language.code ? .white : .blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            .onAppear {
                loadLanguages()
            }
            
            // Segmented Control
            Picker("Study Mode", selection: $selectedSegment) {
                Text("Lessons").tag(0)
                Text("Flashcards").tag(1)
                Text("Saved").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected segment
            ScrollView {
                if selectedSegment == 0 {
                    // Lessons View
                    VStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { num in
                            LessonCard(
                                title: "Lesson \(num)",
                                subtitle: sampleLessonSubtitles[num-1],
                                progress: Double.random(in: 0...1),
                                lessonId: "lesson-\(num)"
                            )
                        }
                    }
                    .padding()
                } else if selectedSegment == 1 {
                    // Flashcards View
                    VStack(spacing: 16) {
                        NavigationLink(destination: FlashcardReviewView(langCode: selectedLanguage)) {
                            ActionCard(
                                title: "Start Flashcard Review",
                                subtitle: "Review today's due cards",
                                iconName: "rectangle.fill.on.rectangle.fill",
                                color: .blue
                            )
                        }
                        
                        Text("Flashcard Decks")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ForEach(sampleFlashcardDecks, id: \.title) { deck in
                            FlashcardDeckRow(
                                title: deck.title,
                                count: deck.count,
                                mastered: deck.mastered
                            )
                        }
                    }
                    .padding()
                } else {
                    // Saved View
                    VStack(spacing: 20) {
                        Text("You haven't saved any content yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Text("Save lessons or flashcards to access them quickly")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle("Study")
    }
    
    // MARK: - Data Loading
    
    private func loadLanguages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedLanguages = try await SupabaseService.shared.getLanguages()
                DispatchQueue.main.async {
                    self.languages = fetchedLanguages
                    
                    // Select the first language if none is selected
                    if self.languages.count > 0 && self.selectedLanguage.isEmpty {
                        self.selectedLanguage = self.languages[0].code
                    }
                    
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load languages"
                    self.isLoading = false
                }
                print("Error loading languages: \(error)")
            }
        }
    }
    
    let sampleLessonSubtitles = [
        "Greetings and Introductions",
        "Basic Verbs and Questions",
        "Food and Dining",
        "Asking for Directions",
        "Describing Your Family"
    ]
    
    let sampleFlashcardDecks = [
        (title: "Beginner Vocabulary", count: 50, mastered: 10),
        (title: "Common Phrases", count: 30, mastered: 15),
        (title: "Travel Words", count: 25, mastered: 5),
        (title: "Food and Dining", count: 40, mastered: 8)
    ]
}

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