import Foundation
import Supabase
import Combine

// Supabase models (e.g., SupabaseLanguage, SupabaseFlashcard) are imported
// implicitly from Models/Study/SupabaseModels.swift if that file is part of the target.
// No local definitions or typealiases for these models should be present here.

class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    // Supabase URL and anon key should be stored in a more secure way in a real app
    private let supabaseUrl = URL(string: "https://eexuddpbzkqtvwfeurml.supabase.co")!
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVleHVkZHBiemtxdHZ3ZmV1cm1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4MTcxMTYsImV4cCI6MjA2MjM5MzExNn0.HdkzTzN5t_y7LFhWrdefNagaFPDihvmB42rIRscFapo"
    
    private init() {
        self.client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseAnonKey)
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User? {
        let authResponse = try await client.auth.signIn(email: email, password: password)
        return authResponse.user
    }
    
    func signUp(email: String, password: String) async throws -> User? {
        let authResponse = try await client.auth.signUp(email: email, password: password)
        return authResponse.user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Languages
    
    func getLanguages() async throws -> [SupabaseLanguage] {
        try await client
            .from("languages")
            .select()
            .execute()
            .value
    }
    
    func getLanguageLevels(for languageId: Int) async throws -> [SupabaseLanguageLevel] {
        try await client
            .from("language_levels")
            .select()
            .eq("language_id", value: languageId)
            .order("ordinal", ascending: true)
            .execute()
            .value
    }
    
    // MARK: - Topics
    
    func getTopics(for levelId: Int) async throws -> [SupabaseTopic] {
        try await client
            .from("topics")
            .select()
            .eq("language_level_id", value: levelId)
            .order("order_in_level", ascending: true)
            .execute()
            .value
    }
    
    // MARK: - Lessons
    
    func getLessons(for topicId: String) async throws -> [SupabaseLesson] {
        try await client
            .from("lessons")
            .select()
            .eq("topic_id", value: topicId)
            .order("order_in_topic", ascending: true)
            .execute()
            .value
    }
    
    func getLessonById(_ lessonId: String) async throws -> [SupabaseLesson] {
        try await client
            .from("lessons")
            .select()
            .eq("id", value: lessonId)
            .limit(1)
            .execute()
            .value
    }
    
    // MARK: - Flashcards
    
    func getFlashcards(for lessonId: String) async throws -> [SupabaseFlashcard] {
        try await client
            .from("flashcards")
            .select()
            .eq("lesson_id", value: lessonId)
            .order("order_in_lesson", ascending: true)
            .execute()
            .value
    }
    
    func getDueFlashcards(for userId: String, langCode: String, limit: Int = 20) async throws -> [SupabaseFlashcard] {
        let now = ISO8601DateFormatter().string(from: Date())
        
        let progress: [SupabaseUserFlashcardProgress] = try await client
            .from("user_flashcard_progress")
            .select()
            .eq("user_id", value: userId)
            .eq("lang_code", value: langCode)
            .lte("due_date", value: now)
            .limit(limit)
            .execute()
            .value
        
        if progress.isEmpty {
            return []
        }
        
        let flashcardIds = progress.map { $0.flashcardId }
        
        return try await client
            .from("flashcards")
            .select()
            .in("id", values: flashcardIds)
            .execute()
            .value
    }
    
    // MARK: - User Progress

    struct UpdateFlashcardProgressPayload: Encodable {
        // Ensure snake_case for Supabase table columns if not handled by client automatically
        let user_id: String
        let flashcard_id: String
        let lang_code: String
        let interval: Int
        let due_date: String
        let review_count: Int
        let last_review_date: String
        let last_difficulty: Int
    }
    
    func getFlashcardProgress(userId: String, flashcardId: String) async throws -> SupabaseUserFlashcardProgress? {
        let progress: [SupabaseUserFlashcardProgress] = try await client
            .from("user_flashcard_progress")
            .select()
            .eq("user_id", value: userId)
            .eq("flashcard_id", value: flashcardId)
            .limit(1)
            .execute()
            .value
        
        return progress.first
    }
    
    func updateFlashcardProgress(userId: String, flashcardId: String, langCode: String,
                                 interval: Int, dueDate: Date, reviewCount: Int,
                                 lastDifficulty: Int) async throws {
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Ensure correct format
        let dueDateString = dateFormatter.string(from: dueDate)
        let nowString = dateFormatter.string(from: Date())
        
        let existingProgress = try await getFlashcardProgress(userId: userId, flashcardId: flashcardId)
        
        let payload = UpdateFlashcardProgressPayload(
            user_id: userId,
            flashcard_id: flashcardId,
            lang_code: langCode,
            interval: interval,
            due_date: dueDateString,
            review_count: reviewCount,
            last_review_date: nowString,
            last_difficulty: lastDifficulty
        )

        if existingProgress == nil {
            try await client
                .from("user_flashcard_progress")
                .insert(payload)
                .execute()
        } else {
            try await client
                .from("user_flashcard_progress")
                .update(payload)
                .eq("user_id", value: userId)
                .eq("flashcard_id", value: flashcardId)
                .execute()
        }
    }
    
    func getUserLanguageLevels(userId: String) async throws -> [SupabaseUserLanguageLevel] {
        try await client
            .from("user_language_levels")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
    }
    
    func getUserLanguageLevel(userId: String, langCode: String) async throws -> SupabaseUserLanguageLevel? {
        let result: [SupabaseUserLanguageLevel] = try await client
            .from("user_language_levels")
            .select()
            .eq("user_id", value: userId)
            .eq("lang_code", value: langCode)
            .limit(1)
            .execute()
            .value
        
        return result.first
    }
    
    // MARK: - Quiz Results

    struct SaveQuizResultPayload: Encodable {
        // Ensure snake_case for Supabase table columns
        let user_id: String
        let lang_code: String
        let level_code: String
        let quiz_type: String
        let score: Int
        let max_score: Int
        let questions_total: Int
        let questions_correct: Int
        let completed_at: String
        let time_taken: Int?
    }
    
    func saveQuizResult(userId: String, langCode: String, levelCode: String,
                       quizType: String, score: Int, maxScore: Int,
                       questionsTotal: Int, questionsCorrect: Int,
                       timeTaken: Int? = nil) async throws {
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let completedAtString = dateFormatter.string(from: Date())
        
        let record = SaveQuizResultPayload(
            user_id: userId,
            lang_code: langCode,
            level_code: levelCode,
            quiz_type: quizType,
            score: score,
            max_score: maxScore,
            questions_total: questionsTotal,
            questions_correct: questionsCorrect,
            completed_at: completedAtString,
            time_taken: timeTaken
        )
        
        try await client
            .from("user_quiz_results")
            .insert(record)
            .execute()
    }

    struct UpdateUserLanguageLevelPayload: Encodable {
        let user_id: String
        let lang_code: String
        let level_code: String
    }

    struct UpdateUserLanguageLevelExistingPayload: Encodable {
        let level_code: String
    }
    
    func updateUserLanguageLevel(userId: String, langCode: String, levelCode: String) async throws {
        let existing = try await getUserLanguageLevel(userId: userId, langCode: langCode)
        
        if existing == nil {
            let payload = UpdateUserLanguageLevelPayload(user_id: userId, lang_code: langCode, level_code: levelCode)
            try await client
                .from("user_language_levels")
                .insert(payload)
                .execute()
        } else {
            let payload = UpdateUserLanguageLevelExistingPayload(level_code: levelCode)
            try await client
                .from("user_language_levels")
                .update(payload)
                .eq("user_id", value: userId)
                .eq("lang_code", value: langCode)
                .execute()
        }
    }
    
    // MARK: - User Lesson Progress
    
    struct SaveLessonProgressPayload: Encodable {
        let user_id: String
        let lesson_id: String
        let completed: Bool
        let completed_at: String?
        let progress_percent: Int?
    }
    
    func saveLessonProgress(userId: String, lessonId: String, completed: Bool, progressPercent: Int? = nil) async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let completedAtString = completed ? dateFormatter.string(from: Date()) : nil
        
        let payload = SaveLessonProgressPayload(
            user_id: userId,
            lesson_id: lessonId,
            completed: completed,
            completed_at: completedAtString,
            progress_percent: progressPercent
        )
        
        try await client
            .from("user_lesson_progress")
            .upsert(payload, onConflict: "user_id,lesson_id")
            .execute()
    }
    
    func getUserLessonProgress(userId: String, lessonId: String) async throws -> Bool {
        struct LessonProgress: Decodable {
            let completed: Bool
        }
        
        let result: [LessonProgress] = try await client
            .from("user_lesson_progress")
            .select("completed")
            .eq("user_id", value: userId)
            .eq("lesson_id", value: lessonId)
            .limit(1)
            .execute()
            .value
        
        return result.first?.completed ?? false
    }
    
    func getUserCompletedLessons(userId: String, langCode: String) async throws -> [String] {
        struct CompletedLesson: Decodable {
            let lesson_id: String
        }
        
        // This assumes there's a way to filter by language code in the progress table
        // If not, you may need to join tables or implement different logic
        let result: [CompletedLesson] = try await client
            .from("user_lesson_progress")
            .select("lesson_id")
            .eq("user_id", value: userId)
            .eq("completed", value: true)
            .execute()
            .value
        
        return result.map { $0.lesson_id }
    }
}