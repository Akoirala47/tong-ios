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
    
    private var testedLanguages: Set<String> = []
    private var userId: String
    
    init(language: SupabaseLanguage, userId: String) {
        self.currentLanguage = language
        self.userId = userId
        Task {
            await self.fetchAllLanguageLevels()
            await self.determineAndSetUserCurrentLevel()
            
            if let userLevelToSelect = self.currentLevel {
                print("[DEBUG] Init: Selecting user's current level: \(userLevelToSelect.code)")
                await self.selectLevel(userLevelToSelect)
            } else if let firstLevel = self.languageLevels.first {
                print("[DEBUG] Init: User's current level not determined, defaulting to first available level: \(firstLevel.code)")
                await self.selectLevel(firstLevel)
            } else {
                print("[WARNING] Init: No language levels available to select after loading.")
            }
        }
    }

    func fetchAllLanguageLevels() async {
        do {
            let langId = currentLanguage.id 
            let fetchedLevels: [SupabaseLanguageLevel] = try await SupabaseService.shared.client
                .from("language_levels")
                .select()
                .eq("language_id", value: langId)
                .order("ordinal", ascending: true)
                .execute()
                .value
            self.languageLevels = fetchedLevels
            print("[DEBUG] fetchAllLanguageLevels: Loaded \(self.languageLevels.count) language levels. Codes: \(self.languageLevels.map { $0.code })")
        } catch {
            print("[ERROR] fetchAllLanguageLevels: Failed to load: \(error.localizedDescription)")
            self.languageLevels = []
        }
    }
    
    func determineAndSetUserCurrentLevel() async {
        if self.languageLevels.isEmpty {
            await self.fetchAllLanguageLevels()
            if self.languageLevels.isEmpty {
                print("[WARNING] determineAndSetUserCurrentLevel: Still no language levels after fetch.")
                return
            }
        }

        do {
            let response = try await SupabaseService.shared.client
                .from("user_placement_tests")
                .select("level_code")
                .eq("user_id", value: userId)
                .eq("lang_code", value: currentLanguage.code)
                .limit(1)
                .execute()

            // Handle the data conversion properly - data is never nil
            let testResponseArray = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]] ?? []
            if let testRecord = testResponseArray.first, 
               let levelCodeStr = testRecord["level_code"] as? String {
                if let matchingLevel = self.languageLevels.first(where: { $0.code == levelCodeStr }) {
                    self.currentLevel = matchingLevel
                    self.completedLevels = self.languageLevels.filter { $0.ordinal < matchingLevel.ordinal }
                    calculateGlobalProgress()
                    self.needsPlacementTest = false
                    print("[DEBUG] determineAndSetUserCurrentLevel: Set currentLevel from user_placement_tests: \(levelCodeStr)")
                    return
                } else {
                    print("[WARNING] determineAndSetUserCurrentLevel: Found level_code '\(levelCodeStr)' in user_placement_tests, but no matching SupabaseLanguageLevel. Available: \(self.languageLevels.map{$0.code})")
                }
            }
        } catch {
            // This catch block handles errors from execute() or JSONSerialization if data is empty/invalid
            print("[ERROR] determineAndSetUserCurrentLevel: Failed to query or parse user_placement_tests: \(error.localizedDescription)")
        }

        do {
            if let record = try await SupabaseService.shared.getUserLanguageLevel(userId: userId, langCode: currentLanguage.code) {
                if let matchingLevel = self.languageLevels.first(where: { $0.code == record.levelCode }) {
                    self.currentLevel = matchingLevel
                    self.completedLevels = self.languageLevels.filter { $0.ordinal < matchingLevel.ordinal }
                    calculateGlobalProgress()
                    self.needsPlacementTest = false
                    print("[DEBUG] determineAndSetUserCurrentLevel: Set currentLevel from user_language_levels: \(record.levelCode)")
                    return
                } else {
                     print("[WARNING] determineAndSetUserCurrentLevel: Found level_code '\(record.levelCode)' in user_language_levels, but no matching SupabaseLanguageLevel. Available: \(self.languageLevels.map{$0.code})")
                }
            } else {
                print("[DEBUG] determineAndSetUserCurrentLevel: No record in user_language_levels for \(currentLanguage.code).")
            }
        } catch {
            print("[ERROR] determineAndSetUserCurrentLevel: Failed to query user_language_levels: \(error.localizedDescription)")
        }
        
        if self.currentLevel == nil {
            print("[DEBUG] determineAndSetUserCurrentLevel: currentLevel remains nil after checking DB.")
        }
    }

    func selectLevel(_ level: SupabaseLanguageLevel) async {
        self.selectedLevel = level 
        do {
            let levelId = level.id 
            let fetchedTopics: [SupabaseTopic] = try await SupabaseService.shared.client
                .from("topics")
                .select()
                .eq("language_level_id", value: levelId) 
                .order("order_in_level", ascending: true)
                .execute()
                .value
            self.topicsByLevel[level.code] = fetchedTopics.sorted { ($0.orderInLevel ?? Int.max) < ($1.orderInLevel ?? Int.max) }
            print("[DEBUG] selectLevel: Loaded \(fetchedTopics.count) topics for level \(level.code) (ID: \(levelId)).")
            
            if let firstTopic = self.topicsByLevel[level.code]?.first {
                await loadLessons(for: firstTopic)
            }
        } catch {
            print("[ERROR] selectLevel: Failed to load topics for level \(level.code) (ID: \(level.id)): \(error.localizedDescription)") 
            self.topicsByLevel[level.code] = []
        }
    }

    func loadLessons(for topic: SupabaseTopic) async {
        do {
            let topicIdString = topic.id 
            let fetchedLessons: [SupabaseLesson] = try await SupabaseService.shared.client
                .from("lessons")
                .select()
                .eq("topic_id", value: topicIdString)
                .order("order_in_topic", ascending: true)
                .execute()
                .value
            self.lessonsByTopic[topicIdString] = fetchedLessons.sorted { ($0.orderInTopic ?? Int.max) < ($1.orderInTopic ?? Int.max) }
            print("[DEBUG] loadLessons: Loaded \(fetchedLessons.count) lessons for topic \(topic.title).")
        } catch {
            print("[ERROR] loadLessons: Failed to load lessons for topic \(topic.title): \(error.localizedDescription)")
            self.lessonsByTopic[topic.id] = [] 
        }
    }

    struct LevelProgress {
        let level: SupabaseLanguageLevel
        let progress: Double
        let isUnlocked: Bool
    }

    var levelProgressData: [LevelProgress] {
        languageLevels.map { level in
            LevelProgress(level: level, progress: Double.random(in: 0...1), isUnlocked: true)
        }
    }
    
    func saveUserLanguageLevel(userId: String, languageCode: String, level: LanguageLevel) async { 
        do {
            if self.languageLevels.isEmpty {
                await fetchAllLanguageLevels()
                if self.languageLevels.isEmpty {
                    print("[ERROR] saveUserLanguageLevel: Cannot save level. No SupabaseLanguageLevels loaded.")
                    return
                }
            }
            guard let supabaseLevelToSave = languageLevels.first(where: { $0.code == level.rawValue }) else {
                print("[ERROR] saveUserLanguageLevel: Could not find SupabaseLanguageLevel for code: \(level.rawValue). Available: \(self.languageLevels.map { $0.code })")
                return
            }
            try await SupabaseService.shared.client
                .from("user_language_levels")
                .upsert([
                    "user_id": userId,
                    "lang_code": languageCode,
                    "level_code": supabaseLevelToSave.code, 
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ], onConflict: "user_id,lang_code")
                .execute() 
            print("[DEBUG] saveUserLanguageLevel: Upserted to user_language_levels: \(languageCode), level \(supabaseLevelToSave.code).")
            self.currentLevel = supabaseLevelToSave
            self.completedLevels = self.languageLevels.filter { $0.ordinal < supabaseLevelToSave.ordinal }
            calculateGlobalProgress()
            self.needsPlacementTest = false 
            await loadUpcomingContent(languageCode: languageCode, level: supabaseLevelToSave)
        } catch {
            print("[ERROR] saveUserLanguageLevel: \(error.localizedDescription)")
        }
    }
    
    private func loadUpcomingContent(languageCode: String, level: SupabaseLanguageLevel) async {
        let topics = ContentRepository.shared.getTopics(langCode: languageCode, levelCode: level.code)
        var contentItems: [LanguageDashboardContentItem] = []
        for topic in topics.prefix(5) {
            let cardCount = topic.lessons.reduce(0) { $0 + $1.cards.count }
            // topic.canDoStatement is non-optional String in ContentModels.Topic
            contentItems.append(LanguageDashboardContentItem(
                title: topic.title,
                subtitle: topic.canDoStatement,
                cardCount: cardCount
            ))
        }
        self.upcomingContent = contentItems
        print("[DEBUG] loadUpcomingContent: Loaded \(contentItems.count) for level \(level.code).")
    }
    
    private func loadCardStats(userId: String, languageCode: String) async {
        do {
            let response = try await SupabaseService.shared.client
                .from("user_flashcard_progress") 
                .select("status, count")
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .execute()
            
            // Handle the data directly
            let statsArray = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]] ?? []
            var totalStudied = 0
            var dueCount = 0
            for statEntry in statsArray {
                if let count = statEntry["count"] as? Int {
                    totalStudied += count 
                    if let status = statEntry["status"] as? String, status.lowercased() == "due" {
                        dueCount = count
                    }
                }
            }
            self.cardsStudied = totalStudied
            self.dueCardCount = dueCount
        } catch {
            print("[ERROR] loadCardStats: \(error.localizedDescription)")
            self.cardsStudied = 0; self.dueCardCount = 0
        }
    }
    
    private func loadUserStats(userId: String) async {
        do {
            let response = try await SupabaseService.shared.client
                .from("profiles") 
                .select("streak")
                .eq("id", value: userId)
                .single()
                .execute()
            
            // Handle the JSON conversion directly
            let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any] ?? [:]
            self.daysStreak = jsonObject["streak"] as? Int ?? 0
        } catch {
            print("[ERROR] loadUserStats: \(error.localizedDescription)")
            self.daysStreak = 0
        }
    }
    
    private func loadDueCardCount(userId: String, languageCode: String) async {
        do {
            let now = ISO8601DateFormatter().string(from: Date())
            let response = try await SupabaseService.shared.client
                .from("user_flashcard_progress") 
                .select("id", head: true) 
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .lte("due_date", value: now)
                .execute()
            
            self.dueCardCount = response.count ?? 0 
            print("[DEBUG] loadDueCardCount: Due card count set to \(self.dueCardCount)")
        } catch {
            print("[ERROR] loadDueCardCount: \(error.localizedDescription)")
            self.dueCardCount = 0
        }
    }
    
    func calculateGlobalProgress() {
        guard let currentSupabaseLevel = currentLevel else {
            self.globalProgress = 0
            return
        }
        if let currentLevelEnum = LanguageLevel(rawValue: currentSupabaseLevel.code) { 
            let allLocalLevels = LanguageLevel.allCases
            if let currentIndex = allLocalLevels.firstIndex(of: currentLevelEnum) {
                self.globalProgress = Double(currentIndex + 1) / Double(allLocalLevels.count)
                print("[DEBUG] calculateGlobalProgress based on enum: \(self.globalProgress)")
                return
            } else {
                 print("[WARNING] calculateGlobalProgress: code '\(currentSupabaseLevel.code)' not in LanguageLevel enum.")
            }
        } else {
            print("[WARNING] calculateGlobalProgress: Failed to init LanguageLevel with '\(currentSupabaseLevel.code)'.")
        }
        if !languageLevels.isEmpty {
            let maxOrdinal = languageLevels.map { $0.ordinal }.max() ?? 0
            let minOrdinal = languageLevels.map { $0.ordinal }.min() ?? 0
            if maxOrdinal > minOrdinal { 
                self.globalProgress = Double(currentSupabaseLevel.ordinal - minOrdinal) / Double(maxOrdinal - minOrdinal)
            } else if maxOrdinal == minOrdinal && !languageLevels.isEmpty { 
                self.globalProgress = 1.0 
            } else { self.globalProgress = 0 }
        } else { self.globalProgress = 0 }
        print("[DEBUG] calculateGlobalProgress based on ordinals: \(self.globalProgress)")
    }
}

extension SupabaseLanguageLevel {
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
// Removed LanguageDashboardViewModel extension containing mockLevels