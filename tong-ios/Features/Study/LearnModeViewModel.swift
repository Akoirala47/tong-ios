import Foundation
import Combine
import SwiftUI

@MainActor
class LearnModeViewModel: ObservableObject {
    // Current lesson and flashcards
    @Published var currentLesson: SupabaseLesson?
    @Published var currentTopic: SupabaseTopic?
    @Published var flashcards: [SupabaseFlashcard] = []
    @Published var vocabItems: [LearnModeVocabItemData] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // User progress tracking
    @Published var completedLessons: [String] = [] // Store lesson IDs
    @Published var unitProgress: Int = 0
    @Published var unitsRequired: Int = 5 // Default until loaded from DB
    
    private let userId: String
    private let languageCode: String
    
    init(userId: String, languageCode: String) {
        self.userId = userId
        self.languageCode = languageCode
    }
    
    func loadUserData() async {
        isLoading = true
        
        do {
            // 1. First determine the user's current level
            let userLevel = try await getUserLevel()
            
            // 2. Get the user's completed lessons
            let completedLessonIds = try await SupabaseService.shared.getUserCompletedLessons(userId: userId, langCode: languageCode)
            await MainActor.run {
                self.completedLessons = completedLessonIds
            }
            
            // 3. Load the topics for this level
            let levelTopics = try await getTopicsForLevel(levelCode: userLevel.code)
            
            // 4. Find the next available topic and lesson based on user progress
            if let nextTopic = await findNextTopic(from: levelTopics) {
                self.currentTopic = nextTopic
                
                // 5. Load lessons for this topic
                let topicLessons = try await getLessonsForTopic(topicId: nextTopic.id)
                
                // 6. Find the next unfinished lesson
                if let nextLesson = findNextLesson(from: topicLessons) {
                    self.currentLesson = nextLesson
                    
                    // 7. Load flashcards for this lesson
                    let lessonFlashcards = try await getFlashcardsForLesson(lessonId: nextLesson.id)
                    self.flashcards = lessonFlashcards
                    
                    // 8. Convert flashcards to vocab items for the UI
                    self.vocabItems = convertFlashcardsToVocabItems(lessonFlashcards)
                } else {
                    throw LoadError.noLessonsAvailable
                }
            } else {
                throw LoadError.noTopicsAvailable
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load lesson data: \(error.localizedDescription)"
            hasError = true
            print("[ERROR] LearnModeViewModel.loadUserData: \(error.localizedDescription)")
        }
    }
    
    private func getUserLevel() async throws -> SupabaseLanguageLevel {
        do {
            // First check if user has a level set
            if let record = try await SupabaseService.shared.getUserLanguageLevel(userId: userId, langCode: languageCode) {
                let languages = try await SupabaseService.shared.getLanguages()
                if let language = languages.first(where: { $0.code == languageCode }) {
                    let languageLevels: [SupabaseLanguageLevel] = try await SupabaseService.shared.client
                        .from("language_levels")
                        .select()
                        .eq("language_id", value: language.id)
                        .order("ordinal", ascending: true)
                        .execute()
                        .value
                    
                    if let matchingLevel = languageLevels.first(where: { $0.code == record.levelCode }) {
                        return matchingLevel
                    }
                }
            }
            
            // If no level found, check for placement test results
            let response = try await SupabaseService.shared.client
                .from("user_placement_tests")
                .select("level_code")
                .eq("user_id", value: userId)
                .eq("lang_code", value: languageCode)
                .limit(1)
                .execute()
            
            let testResponseArray = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]] ?? []
            if let testRecord = testResponseArray.first, 
               let levelCodeStr = testRecord["level_code"] as? String {
                
                let languages = try await SupabaseService.shared.getLanguages()
                if let language = languages.first(where: { $0.code == languageCode }) {
                    let languageLevels: [SupabaseLanguageLevel] = try await SupabaseService.shared.client
                        .from("language_levels")
                        .select()
                        .eq("language_id", value: language.id)
                        .order("ordinal", ascending: true)
                        .execute()
                        .value
                    
                    if let matchingLevel = languageLevels.first(where: { $0.code == levelCodeStr }) {
                        return matchingLevel
                    }
                }
            }
            
            // If still no level, default to the first level
            let languages = try await SupabaseService.shared.getLanguages()
            if let language = languages.first(where: { $0.code == languageCode }) {
                let languageLevels: [SupabaseLanguageLevel] = try await SupabaseService.shared.client
                    .from("language_levels")
                    .select()
                    .eq("language_id", value: language.id)
                    .order("ordinal", ascending: true)
                    .execute()
                    .value
                
                if let firstLevel = languageLevels.first {
                    return firstLevel
                }
            }
            
            throw LoadError.userLevelNotFound
        } catch {
            print("[ERROR] getUserLevel: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func getTopicsForLevel(levelCode: String) async throws -> [SupabaseTopic] {
        do {
            let topics: [SupabaseTopic] = try await SupabaseService.shared.client
                .from("topics")
                .select()
                .eq("level_code", value: levelCode)
                .order("order_in_level", ascending: true)
                .execute()
                .value
            
            return topics
        } catch {
            print("[ERROR] getTopicsForLevel: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func getLessonsForTopic(topicId: String) async throws -> [SupabaseLesson] {
        do {
            let lessons: [SupabaseLesson] = try await SupabaseService.shared.client
                .from("lessons")
                .select()
                .eq("topic_id", value: topicId)
                .order("order_in_topic", ascending: true)
                .execute()
                .value
            
            return lessons
        } catch {
            print("[ERROR] getLessonsForTopic: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func getFlashcardsForLesson(lessonId: String) async throws -> [SupabaseFlashcard] {
        do {
            let flashcards: [SupabaseFlashcard] = try await SupabaseService.shared.client
                .from("flashcards")
                .select()
                .eq("lesson_id", value: lessonId)
                .order("order_in_lesson", ascending: true)
                .execute()
                .value
            
            return flashcards
        } catch {
            print("[ERROR] getFlashcardsForLesson: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func findNextTopic(from topics: [SupabaseTopic]) async -> SupabaseTopic? {
        // First check if there's any topic with incomplete lessons
        for topic in topics {
            do {
                // Get lessons for this topic
                let topicLessons = try await getLessonsForTopic(topicId: topic.id)
                
                // Check if any lesson in this topic is not completed
                for lesson in topicLessons {
                    if !completedLessons.contains(lesson.id) {
                        return topic
                    }
                }
            } catch {
                print("[ERROR] findNextTopic checking lessons: \(error.localizedDescription)")
            }
        }
        
        // If all topics have all lessons completed, return the first topic
        return topics.first
    }
    
    private func findNextLesson(from lessons: [SupabaseLesson]) -> SupabaseLesson? {
        // Check completion status to find the first uncompleted lesson
        for lesson in lessons {
            if !completedLessons.contains(lesson.id) {
                return lesson
            }
        }
        
        // If all lessons are completed, return the first one to review
        return lessons.first
    }
    
    func getUserCompletedLessons() async {
        do {
            let completedLessonIds = try await SupabaseService.shared.getUserCompletedLessons(userId: userId, langCode: languageCode)
            await MainActor.run {
                self.completedLessons = completedLessonIds
            }
        } catch {
            print("[ERROR] getUserCompletedLessons: \(error.localizedDescription)")
        }
    }
    
    private func convertFlashcardsToVocabItems(_ flashcards: [SupabaseFlashcard]) -> [LearnModeVocabItemData] {
        return flashcards.map { flashcard in
            // Generate multiple choice options with the correct translation and three wrong ones
            let correctOption = flashcard.translation
            
            // Use other flashcards' translations as wrong options (avoiding duplicates)
            var wrongOptions = flashcards
                .filter { $0.id != flashcard.id }
                .map { $0.translation }
                .shuffled()
                .prefix(3)
            
            // If we don't have enough options, add some generic ones
            let genericOptions = ["Option A", "Option B", "Option C", "Option D"]
            while wrongOptions.count < 3 {
                if let option = genericOptions.randomElement(), !wrongOptions.contains(option) && option != correctOption {
                    wrongOptions.append(option)
                }
            }
            
            // Combine correct option with wrong ones and shuffle
            var options = Array(wrongOptions)
            options.append(correctOption)
            options.shuffle()
            
            // Find the index of the correct option
            let correctIndex = options.firstIndex(of: correctOption) ?? 0
            
            return LearnModeVocabItemData(
                word: flashcard.word,
                translation: flashcard.translation,
                pronunciation: flashcard.ipa ?? flashcard.word.lowercased(),
                options: options,
                correctOptionIndex: correctIndex
            )
        }
    }
    
    func recordLessonCompletion() async {
        guard let lesson = currentLesson, let topic = currentTopic else { return }
        
        do {
            // Record completion in user_lesson_progress
            try await SupabaseService.shared.saveLessonProgress(
                userId: userId, 
                lessonId: lesson.id, 
                completed: true, 
                progressPercent: 100
            )
            
            // Update user's XP (in a real app, you would get xp_value from the lesson)
            let xpGained = 15 // Default XP for a lesson
            try await updateUserXP(xpGained: xpGained)
            
            // Update user's band progress (track completion of units/lessons within a proficiency band)
            try await updateBandProgress(levelCode: topic.levelCode)
            
            // Refresh completed lessons list
            await getUserCompletedLessons()
            
        } catch {
            print("[ERROR] recordLessonCompletion: \(error.localizedDescription)")
        }
    }
    
    private func updateUserXP(xpGained: Int) async throws {
        // In a real app, you would update the user's XP in the profiles table
        print("[DEBUG] User \(userId) gained \(xpGained) XP")
    }
    
    private func updateBandProgress(levelCode: String) async throws {
        // In a real app, you would increment the units_completed field in user_band_progress
        print("[DEBUG] Updated band progress for user \(userId) in level \(levelCode)")
    }
    
    enum LoadError: Error {
        case userLevelNotFound
        case noTopicsAvailable
        case noLessonsAvailable
    }
} 
