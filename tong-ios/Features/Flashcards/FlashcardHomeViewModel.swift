import Foundation
import Combine

// MARK: - Imports
// Add CoreModels for database models
import SwiftUI

@MainActor
class FlashcardHomeViewModel: ObservableObject, @unchecked Sendable {
    // Current selected language and level
    @Published var selectedLanguage: SupabaseLanguage?
    @Published var selectedLevel: SupabaseLanguageLevel?
    
    // Content loaded from Supabase
    @Published var languages: [SupabaseLanguage] = []
    @Published var levels: [SupabaseLanguageLevel] = []
    @Published var topics: [ContentModels.Topic] = []
    @Published var currentLessons: [ContentModels.Lesson] = []
    
    // Current progress
    @Published var lastStudiedLesson: ContentModels.Lesson?
    @Published var lastStudiedTopic: ContentModels.Topic?
    @Published var lessonProgress: Double = 0.0
    
    // Loading states
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var currentStreak: Int = 0
    @Published var dailyXP: Int = 0
    @Published var dailyXPGoal: Int = 50
    @Published var userLanguages: [SupabaseUserLanguageLevel] = []
    @Published var dueFlashcardCounts: [String: Int] = [:]
    @Published var lastLesson: SupabaseLesson? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Default language will be Spanish (es) for now
        // In a real app, you might determine this from user preferences or device locale
    }
    
    func loadInitialContent() async {
        await loadLanguages()
        
        if let firstLanguage = languages.first {
            await selectLanguage(firstLanguage)
        }
    }
    
    func loadLanguages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let getLanguages = try await SupabaseService.shared.getLanguages()
            
            DispatchQueue.main.async {
                self.languages = getLanguages
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load languages: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func selectLanguage(_ language: SupabaseLanguage) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let getLanguageLevels = try await SupabaseService.shared.getLanguageLevels(for: language.id)
            
            DispatchQueue.main.async {
                self.selectedLanguage = language
                self.levels = getLanguageLevels
                self.isLoading = false
                
                // Select first level by default
                if let firstLevel = getLanguageLevels.first {
                    Task { await self.selectLevel(firstLevel) }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load levels: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Helper function to map between different LanguageLevel types
    func mapDBLevelToLanguageLevel(_ dbLevel: SupabaseLanguageLevel) -> LanguageLevel? {
        // This is a simple mapping based on the level code
        // In a real app, you'd probably want a more robust mapping
        return LanguageLevel(rawValue: dbLevel.code)
    }
    
    func selectLevel(_ level: SupabaseLanguageLevel) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let getTopics = try await SupabaseService.shared.getTopics(for: level.id)
            
            // Convert DBTopic to ContentModels.Topic
            let contentTopics = getTopics.map { dbTopic -> ContentModels.Topic in
                return ContentModels.Topic(
                    id: UUID(),
                    slug: dbTopic.slug,
                    title: dbTopic.title,
                    canDoStatement: dbTopic.canDoStatement!,
                    levelCode: level.code,
                    langCode: selectedLanguage!.code,
                    lessons: []
                )
            }
            
            DispatchQueue.main.async {
                self.selectedLevel = level
                self.topics = contentTopics
                self.isLoading = false
                
                // Load lessons for first topic by default
                if let firstTopic = contentTopics.first {
                    Task { await self.loadLessonsForTopic(firstTopic) }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load topics: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func loadLessonsForTopic(_ topic: ContentModels.Topic) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // We need to find the corresponding DBTopic first
            // This is a temporary solution - ideally we'd store the original ID
            let dbTopics = try await SupabaseService.shared.getTopics(for: selectedLevel?.id ?? 0)
            let dbTopic = dbTopics.first { $0.title == topic.title && $0.slug == topic.slug }
            
            guard let dbTopic = dbTopic else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to find topic in database"
                    self.isLoading = false
                }
                return
            }
            
            let getLessons = try await SupabaseService.shared.getLessons(for: dbTopic.id)
            
            // Convert DBLesson to ContentModels.Lesson
            let contentLessons = getLessons.map { dbLesson -> ContentModels.Lesson in
                return ContentModels.Lesson(
                    id: UUID(),
                    slug: dbLesson.id,
                    title: dbLesson.title,
                    objective: "Learn " + dbLesson.title,
                    orderInTopic: dbLesson.orderInTopic ?? 1,
                    content: dbLesson.content,
                    cards: []
                )
            }
            
            DispatchQueue.main.async {
                self.currentLessons = contentLessons
                self.lastStudiedTopic = topic
                self.isLoading = false
                
                // Cache the first lesson as the "current" one
                if let firstLesson = contentLessons.first {
                    self.lastStudiedLesson = firstLesson
                    // In a real app, you would track actual lesson progress
                    self.lessonProgress = 0.0
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load lessons: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Returns the number of cards due for review
    func getDueCardCount(for userId: String) async -> Int {
        do {
            let dueCards = try await SupabaseService.shared.getDueFlashcards(for: userId, langCode: "es")
            return dueCards.count
        } catch {
            print("Error fetching due cards: \(error.localizedDescription)")
            return 0
        }
    }
    
    // Load a specific lesson and its flashcards
    func loadLesson(_ lesson: ContentModels.Lesson) async -> [SupabaseFlashcard] {
        do {
            // Find the corresponding DBLesson by title and slug
            let dbLessons = try await SupabaseService.shared.getLessons(for: "0")
            let dbLesson = dbLessons.first { $0.title == lesson.title }
            
            guard let dbLesson = dbLesson else {
                print("Error: Could not find corresponding database lesson")
                return []
            }
            
            let flashcards = try await SupabaseService.shared.getFlashcards(for: dbLesson.id)
            return flashcards
        } catch {
            print("Error loading flashcards: \(error.localizedDescription)")
            return []
        }
    }
    
    // Add a computed property for the selected language code
    var selectedLanguageCode: String? {
        return selectedLanguage?.code
    }
    
    func fetchInitialData(userId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            // Fetch user's selected languages
            let fetchedUserLanguages = try await SupabaseService.shared.getUserLanguageLevels(userId: userId)
            self.userLanguages = fetchedUserLanguages
            
            if let firstLang = fetchedUserLanguages.first {
                // Fetch all languages to get the name for the first one
                let allLanguages = try await SupabaseService.shared.getLanguages()
                self.selectedLanguage = allLanguages.first(where: { $0.code == firstLang.langCode })
            }
            
            // Fetch due flashcard counts for each language
            // ... existing code ...
        } catch {
            // ... existing code ...
        }
    }
    
    // Function to get current language level for a given language
    func getCurrentLanguageLevel(for language: SupabaseLanguage) -> String? {
        guard let userLang = userLanguages.first(where: { $0.langCode == language.code }) else {
            return nil
        }
        // This needs to be mapped from levelCode (e.g., "NL") to a SupabaseLanguageLevel struct or similar
        // For now, returning the code. You might need to fetch SupabaseLanguageLevel details.
        return userLang.levelCode // Or map to a full SupabaseLanguageLevel object if needed
    }

    // Mock data for language levels - replace with actual data fetching
    private func getMockLanguageLevels() -> [SupabaseLanguageLevel] {
        return [
            SupabaseLanguageLevel(id: 1, code: "A1", name: "Beginner", ordinal: 1, languageId: 1),
            SupabaseLanguageLevel(id: 2, code: "A2", name: "Elementary", ordinal: 2, languageId: 1),
            SupabaseLanguageLevel(id: 3, code: "B1", name: "Intermediate", ordinal: 3, languageId: 1)
        ]
    }
} 
