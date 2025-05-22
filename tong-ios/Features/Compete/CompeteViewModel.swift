import Foundation
import Combine
import SwiftUI

// MARK: - Models

enum GameResult {
    case win, loss, tie
}

struct CompeteGame: Identifiable {
    let id: String
    let opponentName: String
    let opponentLevel: Int
    let language: String
    let prompt: String
    let isWaitingForOpponent: Bool
    let completedDate: Date
    let userScore: Int
    let opponentScore: Int
    let xpGained: Int
    let result: GameResult
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let level: Int
    let xp: Int
    let elo: Int
    let winStreak: Int
}

struct Badge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let isUnlocked: Bool
}

// MARK: - View Model

class CompeteViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isSearchingMatch = false
    @Published var activeGames: [CompeteGame] = []
    @Published var gameHistory: [CompeteGame] = []
    
    @Published var selectedLeaderboardType = 0 // 0 = XP, 1 = Elo
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var userRank = 5
    @Published var userLevel = 8
    @Published var userXP = 2750
    @Published var userElo = 1280
    
    @Published var streakBadges: [Badge] = []
    @Published var studyBadges: [Badge] = []
    @Published var competitionBadges: [Badge] = []
    
    // MARK: - Initialization
    
    init() {
        loadMockData()
    }
    
    // MARK: - Public Methods
    
    func findMatch() {
        isSearchingMatch = true
        
        // Simulate finding a match
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isSearchingMatch = false
            
            // Create a mock game
            let newGame = CompeteGame(
                id: UUID().uuidString,
                opponentName: self?.randomOpponentName() ?? "User",
                opponentLevel: Int.random(in: 3...15),
                language: ["English", "Spanish", "French", "Japanese"].randomElement() ?? "English",
                prompt: self?.randomPrompt() ?? "Introduce yourself and talk about your hobbies.",
                isWaitingForOpponent: false,
                completedDate: Date(),
                userScore: 0,
                opponentScore: 0,
                xpGained: 0,
                result: .tie
            )
            
            self?.activeGames.insert(newGame, at: 0)
        }
    }
    
    func viewGame(_ game: CompeteGame) {
        // In a real app, this would navigate to a game detail view
        print("Viewing game: \(game.id)")
    }
    
    func respondToGame(_ game: CompeteGame) {
        // In a real app, this would open the recording interface
        // and let the user respond to the challenge
        print("Responding to game: \(game.id)")
        
        // For demo purposes, simulate completing the game
        if let index = activeGames.firstIndex(where: { $0.id == game.id }) {
            let updatedGame = CompeteGame(
                id: game.id,
                opponentName: game.opponentName,
                opponentLevel: game.opponentLevel,
                language: game.language,
                prompt: game.prompt,
                isWaitingForOpponent: true, // Now waiting for opponent
                completedDate: Date(),
                userScore: 0,
                opponentScore: 0,
                xpGained: 0,
                result: .tie
            )
            
            activeGames[index] = updatedGame
            
            // Simulate the game completing after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.completeGame(gameId: game.id)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func completeGame(gameId: String) {
        // Remove from active games
        if let index = activeGames.firstIndex(where: { $0.id == gameId }),
           let game = activeGames.first(where: { $0.id == gameId }) {
            activeGames.remove(at: index)
            
            // Create a completed game with random scores
            let userScore = Int.random(in: 70...95)
            let opponentScore = Int.random(in: 60...98)
            let xpGained = Int.random(in: 10...30)
            
            let result: GameResult
            if userScore > opponentScore {
                result = .win
            } else if userScore < opponentScore {
                result = .loss
            } else {
                result = .tie
            }
            
            let completedGame = CompeteGame(
                id: game.id,
                opponentName: game.opponentName,
                opponentLevel: game.opponentLevel,
                language: game.language,
                prompt: game.prompt,
                isWaitingForOpponent: false,
                completedDate: Date(),
                userScore: userScore,
                opponentScore: opponentScore,
                xpGained: xpGained,
                result: result
            )
            
            // Add to history
            gameHistory.insert(completedGame, at: 0)
            
            // Update user stats
            userXP += xpGained
            if result == .win {
                userElo += Int.random(in: 8...15)
            } else if result == .loss {
                userElo -= Int.random(in: 5...12)
            }
            
            // Update leaderboard
            updateLeaderboard()
        }
    }
    
    private func loadMockData() {
        // Load mock active games
        activeGames = [
            CompeteGame(
                id: "game1",
                opponentName: "Maria",
                opponentLevel: 12,
                language: "Spanish",
                prompt: "Describe your favorite vacation destination and why you like it.",
                isWaitingForOpponent: true,
                completedDate: Date(),
                userScore: 0,
                opponentScore: 0,
                xpGained: 0,
                result: .tie
            ),
            CompeteGame(
                id: "game2",
                opponentName: "Takeshi",
                opponentLevel: 9,
                language: "Japanese",
                prompt: "Talk about your daily routine and what you do on weekends.",
                isWaitingForOpponent: false,
                completedDate: Date(),
                userScore: 0,
                opponentScore: 0,
                xpGained: 0,
                result: .tie
            )
        ]
        
        // Load mock game history
        let calendar = Calendar.current
        
        gameHistory = [
            CompeteGame(
                id: "history1",
                opponentName: "Carlos",
                opponentLevel: 7,
                language: "Spanish",
                prompt: "Introduce yourself and your hobbies.",
                isWaitingForOpponent: false,
                completedDate: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                userScore: 89,
                opponentScore: 82,
                xpGained: 25,
                result: .win
            ),
            CompeteGame(
                id: "history2",
                opponentName: "Sophie",
                opponentLevel: 10,
                language: "French",
                prompt: "Describe your hometown and what you like about it.",
                isWaitingForOpponent: false,
                completedDate: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                userScore: 76,
                opponentScore: 91,
                xpGained: 10,
                result: .loss
            ),
            CompeteGame(
                id: "history3",
                opponentName: "Kenji",
                opponentLevel: 5,
                language: "Japanese",
                prompt: "Talk about your favorite foods and restaurants.",
                isWaitingForOpponent: false,
                completedDate: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                userScore: 85,
                opponentScore: 85,
                xpGained: 15,
                result: .tie
            )
        ]
        
        // Load mock leaderboard
        updateLeaderboard()
        
        // Load mock badges
        streakBadges = [
            Badge(
                id: "streak1",
                name: "First Steps",
                description: "Complete a 3-day streak",
                icon: "flame.fill",
                color: "FF9F1C",
                isUnlocked: true
            ),
            Badge(
                id: "streak2",
                name: "Consistent Learner",
                description: "Complete a 7-day streak",
                icon: "flame.fill",
                color: "FF9F1C",
                isUnlocked: true
            ),
            Badge(
                id: "streak3",
                name: "Dedicated Student",
                description: "Complete a 30-day streak",
                icon: "flame.fill",
                color: "FF9F1C",
                isUnlocked: false
            )
        ]
        
        studyBadges = [
            Badge(
                id: "study1",
                name: "First Flashcards",
                description: "Review 50 flashcards",
                icon: "rectangle.stack.fill",
                color: "00BFFF",
                isUnlocked: true
            ),
            Badge(
                id: "study2",
                name: "Word Collector",
                description: "Learn 100 new words",
                icon: "character.book.closed.fill",
                color: "00BFFF",
                isUnlocked: true
            ),
            Badge(
                id: "study3",
                name: "Grammar Expert",
                description: "Complete all grammar lessons",
                icon: "textformat.abc",
                color: "00BFFF",
                isUnlocked: false
            )
        ]
        
        competitionBadges = [
            Badge(
                id: "compete1",
                name: "First Win",
                description: "Win your first Quick Talk game",
                icon: "trophy.fill",
                color: "FF9F1C",
                isUnlocked: true
            ),
            Badge(
                id: "compete2",
                name: "Winning Streak",
                description: "Win 3 Quick Talk games in a row",
                icon: "medal.fill",
                color: "FF9F1C",
                isUnlocked: false
            ),
            Badge(
                id: "compete3",
                name: "Top Talker",
                description: "Reach Top 10 in leaderboard",
                icon: "crown.fill",
                color: "FF9F1C",
                isUnlocked: false
            )
        ]
    }
    
    private func updateLeaderboard() {
        // Generate mock leaderboard
        leaderboardEntries = [
            LeaderboardEntry(
                id: "user1",
                username: "LinguaKing",
                level: 15,
                xp: 4250,
                elo: 1520,
                winStreak: 5
            ),
            LeaderboardEntry(
                id: "user2",
                username: "PolyglotMaster",
                level: 12,
                xp: 3800,
                elo: 1490,
                winStreak: 3
            ),
            LeaderboardEntry(
                id: "user3",
                username: "WordWizard",
                level: 11,
                xp: 3200,
                elo: 1380,
                winStreak: 0
            ),
            LeaderboardEntry(
                id: "user4",
                username: "LinguaLearner",
                level: 9,
                xp: 2900,
                elo: 1320,
                winStreak: 2
            )
        ]
        
        // Sort the leaderboard based on the selected type
        if selectedLeaderboardType == 0 {
            // Sort by XP
            leaderboardEntries.sort { $0.xp > $1.xp }
        } else {
            // Sort by Elo
            leaderboardEntries.sort { $0.elo > $1.elo }
        }
    }
    
    private func randomOpponentName() -> String {
        let names = [
            "Emma", "Oliver", "Sophia", "Liam", "Ava", "Noah", 
            "Isabella", "Lucas", "Mia", "Ethan", "Yuki", "Chen", 
            "Maria", "Carlos", "Sophie", "Jean", "Hiroshi"
        ]
        return names.randomElement() ?? "User"
    }
    
    private func randomPrompt() -> String {
        let prompts = [
            "Describe your favorite hobby and why you enjoy it.",
            "Talk about a trip you would like to take in the future.",
            "Describe your morning routine from when you wake up.",
            "What's your favorite season and why do you like it?",
            "Describe a typical weekend day for you.",
            "Talk about your favorite foods and restaurants.",
            "If you could live anywhere in the world, where would it be and why?",
            "Describe your ideal job or career path."
        ]
        return prompts.randomElement() ?? "Introduce yourself and talk about your hobbies."
    }
} 