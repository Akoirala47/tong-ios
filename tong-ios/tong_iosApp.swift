//
//  tong_iosApp.swift
//  tong-ios
//
//  Created by Aayush Koirala on 5/9/25.
//

import SwiftUI
import AVFoundation
import Supabase

struct AppRootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var statsViewModel = ProfileStatsViewModel()
    @StateObject private var drillViewModel = FlashcardDrillViewModel()
    @State private var showSplash = true
    
    #if DEBUG
    // For previews
    @Environment(\.isPreview) private var isPreview
    #endif

    var body: some View {
        #if DEBUG
        if isPreview {
            // Show a simplified version for previews
            MainContentView(
                statsViewModel: statsViewModel,
                drillViewModel: FlashcardDrillViewModel.mockForPreview(),
                userId: "preview-user",
                authViewModel: authViewModel
            )
        } else {
            if showSplash {
                SplashView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        // Automatically transition after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                mainContent
            }
        }
        #else
        if showSplash {
            SplashView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Automatically transition after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
        } else {
            mainContent
        }
        #endif
    }
    
    var mainContent: some View {
        NavigationView {
            Group {
                if authViewModel.isAuthenticated {
                    if let userId = SupabaseService.shared.client.auth.currentUser?.id.uuidString {
                        MainContentView(
                            statsViewModel: statsViewModel,
                            drillViewModel: drillViewModel,
                            userId: userId,
                            authViewModel: authViewModel
                        )
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading user…")
                        }
                        .onAppear {
                            print("[DEBUG] User authenticated but ID not found – waiting for session")
                        }
                    }
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            print("[DEBUG] Showing auth view, isAuthenticated: \(authViewModel.isAuthenticated)")
                        }
                }
            }
            .animation(.default, value: authViewModel.isAuthenticated)
        }
    }
}

struct MainContentView: View {
    @ObservedObject var statsViewModel: ProfileStatsViewModel
    @ObservedObject var drillViewModel: FlashcardDrillViewModel
    let userId: String
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            FlashcardHomeView(
                drillViewModel: drillViewModel,
                statsViewModel: statsViewModel,
                userId: userId
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            StudyTabView(drillViewModel: drillViewModel, userId: userId)
                .tabItem {
                    Label("Study", systemImage: "book.closed.fill")
                }
            
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "mic.fill")
                }
            
            CompeteTabView(userId: userId)
                .tabItem {
                    Label("Compete", systemImage: "trophy.fill")
                }
            
            ProfileView(
                statsViewModel: statsViewModel,
                userId: userId,
                authViewModel: authViewModel
            )
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .accentColor(Color(red: 0, green: 191/255, blue: 255/255)) // Arctic Blue
        .onAppear {
            // Fetch stats data when the main content loads
            Task { await statsViewModel.fetchProfileStats(userId: userId) }
            // Fetch flashcards
            Task { await drillViewModel.fetchDueFlashcards(for: userId) }
        }
    }
}

// Helper for preview detection
#if DEBUG
private struct IsPreviewKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isPreview: Bool {
        get { self[IsPreviewKey.self] }
        set { self[IsPreviewKey.self] = newValue }
    }
}

// Helper function to check if we're in a preview
private func isRunningInPreview() -> Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

// Mark previews with the isPreview flag
extension View {
    func previewEnvironment() -> some View {
        environment(\.isPreview, isRunningInPreview())
    }
}
#endif

@main
struct tong_iosApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var studyViewModel = StudyViewModel()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            // Show splash for 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    if authViewModel.isAuthenticated {
                        ContentView()
                            .environmentObject(authViewModel)
                            .environmentObject(studyViewModel)
                            .environment(\.colorScheme, ColorScheme.light) // Explicitly use ColorScheme.light
                            .onAppear {
                                setupUserData()
                            }
                    } else {
                        OnboardingView()
                            .environmentObject(authViewModel)
                            .environment(\.colorScheme, ColorScheme.light) // Explicitly use ColorScheme.light
                    }
                }
            }
        }
    }
    
    private func setupUserData() {
        Task {
            // Fetch user data if authenticated
            if let userId = SupabaseService.shared.client.auth.currentUser?.id.uuidString {
                print("Setting up user data for: \(userId)")
                
                // Load user study data
                try? await studyViewModel.loadUserData(userId: userId)
            }
        }
    }
}

struct CompeteTabView: View {
    let userId: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "trophy.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 255/255, green: 159/255, blue: 28/255))
                    .padding()
                
                Text("Compete & Challenge")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Challenge friends or join leaderboards to test your language skills")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer().frame(height: 40)
                
                Button {
                    // In a real app, start a game
                } label: {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                        Text("Find a Match")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 255/255, green: 159/255, blue: 28/255))
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Leaderboard preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Leaderboard")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(1...3, id: \.self) { rank in
                        HStack(spacing: 12) {
                            Text("\(rank)")
                                .font(.headline)
                                .frame(width: 30, height: 30)
                                .background(
                                    rank == 1 ? Color.yellow :
                                        rank == 2 ? Color.gray :
                                        rank == 3 ? Color(red: 205/255, green: 127/255, blue: 50/255) : Color.clear
                                )
                                .foregroundColor(rank <= 3 ? .white : .primary)
                                .cornerRadius(15)
                            
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String("User\(rank)".prefix(1)))
                                        .foregroundColor(.primary)
                                )
                            
                            Text("User\(rank)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(1000 - rank * 100) XP")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .navigationTitle("Compete")
        }
    }
}

// MARK: - View Models

@MainActor
class StudyViewModel: ObservableObject {
    @Published var userLanguages: [SupabaseUserLanguageLevel] = []
    @Published var currentLanguage: SupabaseLanguage?
    @Published var currentLevel: String = "NL" // Default to Novice Low
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadUserData(userId: String) async throws {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Fetch user's language levels
            let fetchedLevels = try await SupabaseService.shared.getUserLanguageLevels(userId: userId)
            
            if let primaryLanguageLevel = fetchedLevels.first {
                // Fetch the language details
                let languages = try await SupabaseService.shared.getLanguages()
                let primaryLanguage = languages.first { $0.code == primaryLanguageLevel.langCode }
                
                DispatchQueue.main.async {
                    self.userLanguages = fetchedLevels
                    self.currentLanguage = primaryLanguage
                    self.currentLevel = primaryLanguageLevel.levelCode
                    self.isLoading = false
                }
            } else {
                // User doesn't have any language levels yet
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func setCurrentLanguage(_ language: SupabaseLanguage) {
        self.currentLanguage = language
    }
    
    func setCurrentLevel(_ level: String) {
        self.currentLevel = level
    }
}
