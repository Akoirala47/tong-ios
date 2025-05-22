import Foundation
import Combine
import SwiftUI

// Model for upcoming content items - moved to top level
struct LanguageDashboardContentItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let cardCount: Int
}

@MainActor
class LanguageDashboardViewModel: ObservableObject {
    @Published var currentLanguage: SupabaseLanguage
    @Published var languageLevels: [SupabaseLanguageLevel] = []
    @Published var selectedLevel: SupabaseLanguageLevel? = nil
    @Published var topicsByLevel: [String: [SupabaseTopic]] = [:]
    @Published var lessonsByTopic: [String: [SupabaseLesson]] = [:]
    @Published var needsPlacementTest = false
    @Published var currentLevel: SupabaseLanguageLevel?
    @Published var completedLevels: [SupabaseLanguageLevel] = []
    @Published var upcomingContent: [LanguageDashboardContentItem] = []
    @Published var cardsStudied: Int = 0
    @Published var daysStreak: Int = 0
    @Published var estimatedHours: Int = 0
    @Published var dueCardCount: Int = 0
    @Published var globalProgress: Double = 0.0
    
    // Track which languages have already been tested 
    private var testedLanguages: Set<String> = []
    private var userId: String
    
    init(language: SupabaseLanguage, userId: String) {
        self.currentLanguage = language
        self.userId = userId
        Task {
            await loadLanguageLevels()
            // If there are levels, select the first one by default or the user's current one
            if let firstLevel = languageLevels.first {
                await selectLevel(firstLevel)
            }
        }
    }

    func loadLanguageLevels() async {
        // ... implementation to load levels for currentLanguage.id ...
        // Example: self.languageLevels = try await SupabaseService.shared.getLanguageLevels(for: currentLanguage.id)
        // For now, using mock data:
        self.languageLevels = [
            SupabaseLanguageLevel(id: 1, code: "NL", name: "Novice Low", ordinal: 1, languageId: currentLanguage.id),
            SupabaseLanguageLevel(id: 2, code: "NM", name: "Novice Mid", ordinal: 2, languageId: currentLanguage.id)
        ]
    }

    func selectLevel(_ level: SupabaseLanguageLevel) async {
        self.selectedLevel = level
        // ... implementation to load topics for this level.code ...
        // Example: self.topicsByLevel[level.code] = try await SupabaseService.shared.getTopics(for: level.id)
        // For now, using mock data:
        self.topicsByLevel[level.code] = [
            SupabaseTopic(id: "topic1", title: "Greetings", slug: "greetings", canDoStatement: nil, languageLevelId: level.id, levelCode: level.code, orderInLevel: 1)
        ]
        // If topics are loaded, load lessons for the first topic
        if let firstTopic = self.topicsByLevel[level.code]?.first {
            await loadLessons(for: firstTopic)
        }
    }

    func loadLessons(for topic: SupabaseTopic) async {
        // ... implementation to load lessons for topic.id ...
        // Example: self.lessonsByTopic[topic.id] = try await SupabaseService.shared.getLessons(for: topic.id)
        // For now, using mock data:
        self.lessonsByTopic[topic.id] = [
            SupabaseLesson(id: "lesson1", title: "Basic Hellos", content: "...", topicId: topic.id, orderInTopic: 1)
        ]
    }

    // Placeholder for progress data structure
    struct LevelProgress {
        let level: SupabaseLanguageLevel
        let progress: Double
        let isUnlocked: Bool
    }

    // Mock progress data
    var levelProgressData: [LevelProgress] {
        languageLevels.map { level in
            LevelProgress(level: level, progress: Double.random(in: 0...1), isUnlocked: true)
        }
    }

    func loadUserLanguageLevel(userId: String, languageCode: String) async {
        // First check our in-memory cache to avoid repeated database lookups
        if testedLanguages.contains(languageCode) {
            print("[DEBUG] Skipping placement test check - already know \(languageCode) has been tested")
            await MainActor.run {
                self.needsPlacementTest = false
            }
            
            // Still need to load the level data
            await loadLanguageLevelData(userId: userId, languageCode: languageCode)
            return
        }
        
        // Next check UserDefaults which is persistent across app launches
        let testCompletionKey = "placement_test_completed_\(languageCode)_\(userId)"
        if UserDefaults.standard.bool(forKey: testCompletionKey) {
            print("[DEBUG] Found completed test in UserDefaults for \(languageCode)")
            testedLanguages.insert(languageCode)
            await MainActor.run {
                self.needsPlacementTest = false
            }
            
            // Still need to load the level data
            await loadLanguageLevelData(userId: userId, languageCode: languageCode)
            return
        }
        
        var hasTakenTest = false
        
        do {
            print("[DEBUG] Checking if user \(userId) has taken placement test for \(languageCode)")
            
            // First check if user has already taken the placement test
            let testResponse = try await SupabaseService.shared.client
                .from("user_placement_tests")
                .select("has_taken_test, level_code, completed_at")
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .execute()
            
            print("[DEBUG] Test response: \(String(data: testResponse.data, encoding: .utf8) ?? "no data")")
            
            if let jsonString = String(data: testResponse.data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
               !jsonArray.isEmpty {
                
                print("[DEBUG] Found placement test record: \(jsonArray)")
                
                // Check if the has_taken_test value is present
                let hasCompletedTest: Bool
                
                if let hasTakenTestBool = jsonArray[0]["has_taken_test"] as? Bool {
                    // Handle boolean value
                    hasCompletedTest = hasTakenTestBool
                    print("[DEBUG] has_taken_test as Bool: \(hasCompletedTest)")
                } else if let hasTakenTestString = jsonArray[0]["has_taken_test"] as? String {
                    // Handle string value ("true" or "false")
                    hasCompletedTest = hasTakenTestString == "true"
                    print("[DEBUG] has_taken_test as String: \(hasTakenTestString) -> \(hasCompletedTest)")
                } else if let completedAt = jsonArray[0]["completed_at"] as? String, !completedAt.isEmpty {
                    // If completed_at is present and not empty, the test was completed
                    hasCompletedTest = true
                    print("[DEBUG] has_taken_test derived from completed_at: \(hasCompletedTest)")
                } else {
                    hasCompletedTest = false
                    print("[DEBUG] has_taken_test not found or invalid format")
                }
                
                if hasCompletedTest {
                    // User has already taken the test - add to our cache
                    testedLanguages.insert(languageCode)
                    
                    await MainActor.run {
                        self.needsPlacementTest = false
                    }
                    
                    // If we have a level from the test, use it
                    if let levelString = jsonArray[0]["level_code"] as? String,
                       let levelEnum = LanguageLevel(rawValue: levelString) {
                        await MainActor.run {
                            if let matchingSupabaseLevel = self.languageLevels.first(where: { $0.code == levelEnum.rawValue }) {
                                self.currentLevel = matchingSupabaseLevel
                                self.completedLevels = self.languageLevels.filter { sl -> Bool in
                                    return sl.ordinal < matchingSupabaseLevel.ordinal
                                }
                            } else {
                                print("[WARNING] Could not find matching SupabaseLanguageLevel for code: \(levelEnum.rawValue)")
                            }
                            calculateGlobalProgress()
                        }
                        print("[DEBUG] Set level from placement test: \(levelEnum.rawValue)")
                    }
                    
                    // Set hasTakenTest after using it in MainActor
                    hasTakenTest = true
                }
            }
            
            await loadLanguageLevelData(userId: userId, languageCode: languageCode)
            
        } catch {
            print("[ERROR] Error loading user language level: \(error)")
            let testCompleted = hasTakenTest // Create local copy
            await MainActor.run {
                // Only set needs placement test to true if they haven't taken it already
                if !testCompleted {
                    self.needsPlacementTest = true
                }
                if self.currentLevel == nil {
                    self.completedLevels = []
                }
            }
        }
    }
    
    func saveUserLanguageLevel(userId: String, languageCode: String, level: LanguageLevel) async {
        do {
            // Find the corresponding SupabaseLanguageLevel to save its ID or code
            guard let supabaseLevelToSave = languageLevels.first(where: { $0.code == level.rawValue }) else {
                print("[ERROR] Could not find SupabaseLanguageLevel for code: \(level.rawValue) to save.")
                return
            }

            // Insert or update user's language level in Supabase
            let _ = try await SupabaseService.shared.client
                .from("user_language_levels")
                .upsert([
                    "user_id": userId,
                    "lang_code": languageCode,
                    "level_code": supabaseLevelToSave.code,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            // Load content for the new level
            await loadUpcomingContent(languageCode: languageCode, level: supabaseLevelToSave)
            
            // Update our local properties
            await MainActor.run {
                self.currentLevel = supabaseLevelToSave
                self.completedLevels = self.languageLevels.filter { sl -> Bool in
                    return sl.ordinal < supabaseLevelToSave.ordinal
                }
                calculateGlobalProgress()
            }
            
        } catch {
            print("Error saving user language level: \(error)")
        }
    }
    
    private func loadUpcomingContent(languageCode: String, level: SupabaseLanguageLevel) async {
        // Query topics from content repository based on level
        let topics = ContentRepository.shared.getTopics(langCode: languageCode, levelCode: level.code)
        
        await MainActor.run {
            self.upcomingContent = topics.prefix(5).map { topic in
                let _ = topic.lessons.count
                let cardCount = topic.lessons.reduce(0) { $0 + $1.cards.count }
                
                return LanguageDashboardContentItem(
                    title: topic.title,
                    subtitle: topic.canDoStatement,
                    cardCount: cardCount
                )
            }
        }
    }
    
    private func loadCardStats(userId: String, languageCode: String) async {
        do {
            let response = try await SupabaseService.shared.client
                .from("user_flashcard_progress")
                .select("status, count")
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .execute()
            
            if let jsonString = String(data: response.data, encoding: .utf8) {
                // Process jsonString
                print("[DEBUG] Card stats response: \(jsonString)")
                // Assuming jsonString is an array of dictionaries like:
                // [{"status":"learned","count":10}, {"status":"due","count":5}]
                if let jsonData = jsonString.data(using: .utf8),
                   let statsArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                    var totalStudied = 0
                    var dueCount = 0
                    for statEntry in statsArray {
                        if let count = statEntry["count"] as? Int {
                            totalStudied += count // Assuming all entries contribute to "studied" for simplicity
                            if let status = statEntry["status"] as? String, status == "due" {
                                dueCount = count
                            }
                        }
                    }
                    await MainActor.run {
                        self.cardsStudied = totalStudied
                        self.dueCardCount = dueCount
                    }
                }
            }
        } catch {
            print("Error loading card stats: \(error)")
            await MainActor.run {
                self.cardsStudied = 0
                self.dueCardCount = 0
            }
        }
    }
    
    private func loadUserStats(userId: String) async {
        do {
            // Query user streak from profile
            let response = try await SupabaseService.shared.client
                .from("profiles")
                .select("streak")
                .eq("id", value: userId)
                .single()
                .execute()
            
            if let jsonString = String(data: response.data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let streak = jsonObject["streak"] as? Int {
                
                await MainActor.run {
                    self.daysStreak = streak
                }
            } else {
                await MainActor.run {
                    self.daysStreak = 0
                }
            }
        } catch {
            print("Error loading user stats: \(error)")
            await MainActor.run {
                self.daysStreak = 0
            }
        }
    }
    
    private func loadDueCardCount(userId: String, languageCode: String) async {
        do {
            // Get the current date in ISO format
            let now = ISO8601DateFormatter().string(from: Date())
            
            // Query due cards count
            let response = try await SupabaseService.shared.client
                .from("user_flashcard_progress")
                .select("count(*)")
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .lte("due_date", value: now)
                .execute()
            
            if let jsonString = String(data: response.data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
               !jsonArray.isEmpty,
               let count = jsonArray[0]["count"] as? Int {
                
                await MainActor.run {
                    self.dueCardCount = count
                }
            } else {
                await MainActor.run {
                    self.dueCardCount = 0
                }
            }
        } catch {
            print("Error loading due card count: \(error)")
            await MainActor.run {
                self.dueCardCount = 0
            }
        }
    }
    
    private func calculateGlobalProgress() {
        guard let currentSupabaseLevel = currentLevel,
              let currentLevelEnum = LanguageLevel(rawValue: currentSupabaseLevel.code) else {
            self.globalProgress = 0
            return
        }
        
        let allLevels = LanguageLevel.allCases // Use LanguageLevel enum
        guard let currentIndex = allLevels.firstIndex(of: currentLevelEnum) else {
            self.globalProgress = 0
            return
        }
        
        self.globalProgress = Double(currentIndex + 1) / Double(allLevels.count)
    }
    
    // Extract common code for loading level data to a separate method
    private func loadLanguageLevelData(userId: String, languageCode: String) async {
        do {
            let userLevelsResponse = try await SupabaseService.shared.client
                .from("user_language_levels")
                .select("level_code, completed_at") // Assuming completed_at helps determine completed levels
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .execute()

            if let dataString = String(data: userLevelsResponse.data, encoding: .utf8),
               let userLevelJsonData = dataString.data(using: .utf8),
               let userLevelsArray = try? JSONSerialization.jsonObject(with: userLevelJsonData) as? [[String: Any]] {

                var loadedCompletedLevels: [SupabaseLanguageLevel] = []
                var currentSupabaseLevel: SupabaseLanguageLevel?

                // Assuming languageLevels (all possible SupabaseLanguageLevel for the current language) is already loaded
                // Iterate through the levels the user has interacted with
                for userLevelEntry in userLevelsArray {
                    if let levelCode = userLevelEntry["level_code"] as? String {
                        if let matchingSupabaseLevel = self.languageLevels.first(where: { $0.code == levelCode }) {
                            // If 'completed_at' exists and is not null, or some other logic determines completion
                            if userLevelEntry["completed_at"] as? String != nil { // Example: check if completed_at is non-nil
                                loadedCompletedLevels.append(matchingSupabaseLevel)
                            } else {
                                // This could be the current, non-completed level
                                // Or determine "current" based on highest ordinal without completed_at
                                // For simplicity, let's assume the last one encountered without 'completed_at' is current
                                currentSupabaseLevel = matchingSupabaseLevel
                            }
                        }
                    }
                }
                
                // A more robust way to find the current level:
                // The one with the highest ordinal that isn't in loadedCompletedLevels.
                // Or, if user_language_levels has a specific 'is_current' flag, that's better.
                // For now, if not directly set from placement, we try to infer it or set to first if empty.

                await MainActor.run {
                    self.completedLevels = loadedCompletedLevels
                    if let foundCurrentLevel = currentSupabaseLevel {
                         self.currentLevel = foundCurrentLevel
                    } else if !loadedCompletedLevels.isEmpty {
                        // If no explicit current, but there are completed, maybe current is next one?
                        // This logic needs to be well-defined by the app's progression rules.
                        // For now, we'll leave it potentially nil if not directly found.
                    } else if self.currentLevel == nil, let firstLevel = self.languageLevels.first {
                        // If no levels completed and current not set, default to first level of the language
                        self.currentLevel = firstLevel
                    }
                    calculateGlobalProgress()
                }
            }
        } catch {
            print("[ERROR] Failed to load language level data: \(error.localizedDescription)")
        }
    }
}

extension SupabaseLanguageLevel {
    // Add a property to get a sample word for flashcard preview
    var flashcardPreviewWord: String {
        switch code {
        case "NL": return "Hola"
        case "NM": return "Buenos días"
        case "NH": return "¿Cómo estás?"
        case "IL": return "Necesito ayuda"
        case "IM": return "Me gustaría"
        case "IH": return "Estoy aprendiendo"
        case "AL": return "Considerando"
        case "AM": return "Sin embargo"
        case "AH": return "A pesar de"
        case "S": return "En mi opinión"
        default: return "Palabra"
        }
    }
}

extension LanguageDashboardViewModel {
    static var mockLevels: [SupabaseLanguageLevel] = [
        // These should be instances of SupabaseLanguageLevel, using LanguageLevel.rawValue for their 'code'
        SupabaseLanguageLevel(id: 1, code: LanguageLevel.noviceLow.rawValue, name: "Novice Low", ordinal: 1, languageId: 1),
        SupabaseLanguageLevel(id: 2, code: LanguageLevel.noviceMid.rawValue, name: "Novice Mid", ordinal: 2, languageId: 1),
        SupabaseLanguageLevel(id: 3, code: LanguageLevel.noviceHigh.rawValue, name: "Novice High", ordinal: 3, languageId: 1),
        SupabaseLanguageLevel(id: 4, code: LanguageLevel.intermediateLow.rawValue, name: "Intermediate Low", ordinal: 4, languageId: 1),
        SupabaseLanguageLevel(id: 5, code: LanguageLevel.intermediateMid.rawValue, name: "Intermediate Mid", ordinal: 5, languageId: 1),
        SupabaseLanguageLevel(id: 6, code: LanguageLevel.intermediateHigh.rawValue, name: "Intermediate High", ordinal: 6, languageId: 1),
        SupabaseLanguageLevel(id: 7, code: LanguageLevel.advancedLow.rawValue, name: "Advanced Low", ordinal: 7, languageId: 1),
        SupabaseLanguageLevel(id: 8, code: LanguageLevel.advancedMid.rawValue, name: "Advanced Mid", ordinal: 8, languageId: 1),
        SupabaseLanguageLevel(id: 9, code: LanguageLevel.advancedHigh.rawValue, name: "Advanced High", ordinal: 9, languageId: 1),
        SupabaseLanguageLevel(id: 10, code: LanguageLevel.superior.rawValue, name: "Superior", ordinal: 10, languageId: 1)
    ]
} 