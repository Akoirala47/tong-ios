import SwiftUI

struct PlacementTestView: View {
    let languageCode: String
    let userId: String
    let onComplete: (LevelData) -> Void
    
    @StateObject private var viewModel = PlacementTestViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Content view
            if viewModel.isLoading {
                loadingView
            } else if showResults {
                resultsView
            } else {
                VStack(spacing: 16) {
                    // Header with important note
                    placementTestHeaderView
                    
                    // Questions
                    if viewModel.hasStarted && viewModel.currentQuestion != nil {
                        questionView(viewModel.currentQuestion!)
                    } else {
                        startView
                    }
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !viewModel.hasStarted {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadQuestions(for: languageCode)
            }
        }
    }
    
    private var placementTestHeaderView: some View {
        VStack(spacing: 8) {
            Text("Placement Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Note: You can only take this test once to determine your starting level")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
                
            if viewModel.hasStarted && !showResults {
                // Progress indicator
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color(hex: "00BFFF"))
                            .frame(
                                width: geo.size.width * (Double(viewModel.currentIndex) / Double(max(1, viewModel.questions.count))),
                                height: 6
                            )
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                .padding(.bottom, 16)
                
                Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading placement test...")
                .font(.headline)
        }
    }
    
    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "ruler")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "00BFFF"))
                .padding()
            
            Text("Find your proficiency level")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("This test will help determine your current \(languageName) level. It will only take about 5 minutes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Your result will customize your learning path.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
            
            Spacer()
            
            // Start button
            Button(action: {
                viewModel.startTest()
            }) {
                Text("Start Test")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "00BFFF"))
                    .cornerRadius(10)
            }
        }
    }
    
    private func questionView(_ question: PlacementQuestion) -> some View {
        VStack(spacing: 24) {
            // Question text
            Text(question.text)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            
            // Options
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    Button(action: {
                        viewModel.selectAnswer(at: index)
                    }) {
                        HStack {
                            Text(question.options[index])
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .padding()
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    viewModel.selectedOptionIndex == index
                                        ? Color(hex: "00BFFF")
                                        : Color.gray.opacity(0.3),
                                    lineWidth: 2
                                )
                                .background(
                                    viewModel.selectedOptionIndex == index
                                        ? Color(hex: "00BFFF").opacity(0.1)
                                        : Color.clear
                                )
                        )
                        .cornerRadius(10)
                    }
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                // Back button
                if viewModel.currentIndex > 0 {
                    Button(action: {
                        viewModel.previousQuestion()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(Color(hex: "00BFFF"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "00BFFF"), lineWidth: 2)
                        )
                    }
                    .padding(.trailing, 8)
                } else {
                    Spacer()
                }
                
                // Continue or Submit button
                Button(action: {
                    if viewModel.isLastQuestion {
                        // Complete the test and calculate results
                        viewModel.finishTest()
                        showResults = true
                    } else {
                        viewModel.nextQuestion()
                    }
                }) {
                    Text(viewModel.isLastQuestion ? "Submit" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            viewModel.selectedOptionIndex != nil
                                ? Color(hex: "00BFFF")
                                : Color.gray
                        )
                        .cornerRadius(10)
                }
                .disabled(viewModel.selectedOptionIndex == nil)
            }
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(Color(hex: "42B883"))
                .padding()
            
            Text("Test Completed!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let level = viewModel.determinedLevel {
                VStack(spacing: 16) {
                    Text("Your \(languageName) level is:")
                        .font(.title3)
                    
                    Text(level.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "00BFFF"))
                        .padding()
                    
                    levelDescriptionView(level)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            
            Spacer()
            
            // Continue button
            Button(action: {
                if let level = viewModel.determinedLevel {
                    // Important: Save results to Supabase to mark test as taken
                    Task {
                        await saveTestResults(level: level)
                        onComplete(level)
                        dismiss()
                    }
                }
            }) {
                Text("Start Learning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "00BFFF"))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private func saveTestResults(level: LevelData) async {
        do {
            print("[DEBUG] Saving placement test results for \(languageCode), level: \(level.code)")
            
            // Save both the language level and a record of test completion
            let response = try await SupabaseService.shared.client
                .from("user_placement_tests")
                .upsert([
                    "user_id": userId,
                    "lang_code": languageCode,
                    "level_code": level.code,
                    "completed_at": ISO8601DateFormatter().string(from: Date()),
                    "has_taken_test": "true"  // Keep as string "true" as this is what the DB expects
                ])
                .execute()
            
            print("[DEBUG] Successfully saved test results: \(String(data: response.data, encoding: .utf8) ?? "no data")")
            
            // Also ensure the user_language_levels record exists - this is the primary record used for level tracking
            let levelResponse = try await SupabaseService.shared.client
                .from("user_language_levels")
                .upsert([
                    "user_id": userId,
                    "lang_code": languageCode,
                    "level_code": level.code,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            print("[DEBUG] User language level saved: \(String(data: levelResponse.data, encoding: .utf8) ?? "no data")")
            
            // Create a key that will be used for UserDefaults to ensure persistence between app launches
            let testCompletionKey = "placement_test_completed_\(languageCode)_\(userId)"
            UserDefaults.standard.set(true, forKey: testCompletionKey)
            
            print("[DEBUG] Also saved completion status to UserDefaults with key: \(testCompletionKey)")
            
        } catch {
            print("[ERROR] Error saving test results: \(error)")
        }
    }
    
    private func levelDescriptionView(_ level: LevelData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What this means:")
                .font(.headline)
                .padding(.bottom, 4)
            
            Text(getLevelDescription(level))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getLevelDescription(_ level: LevelData) -> String {
        switch level.code {
        case "NL":
            return "You can communicate minimally with memorized words and phrases for basic needs."
        case "NM":
            return "You can handle simple exchanges using memorized phrases in familiar contexts."
        case "NH":
            return "You can handle uncomplicated tasks and social situations with limited vocabulary."
        case "IL":
            return "You can create with language to talk about familiar topics related to everyday life."
        case "IM":
            return "You can handle successfully a variety of uncomplicated communicative tasks in informal settings."
        case "IH":
            return "You can narrate and describe in all major time frames, though with some inaccuracies."
        case "AL":
            return "You can narrate and describe in all time frames and handle a complicated situation with some complications."
        case "AM":
            return "You can communicate on a wide variety of topics with clarity and precision."
        case "AH":
            return "You can handle extended discourse on abstract topics with good control of language structures."
        case "S":
            return "You can communicate with accuracy and fluency on all topics and handle unpredictable complications."
        default:
            return "You are at the beginning of your language learning journey."
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
}

struct PlacementQuestion: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]
    let correctIndex: Int
    let level: LevelData
    let difficulty: Int // 1-10
}

#Preview {
    PlacementTestView(
        languageCode: "es",
        userId: "preview-user",
        onComplete: { _ in }
    )
} 