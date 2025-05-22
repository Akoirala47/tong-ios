import SwiftUI
import Foundation

struct CompeteView: View {
    @StateObject private var viewModel = CompeteViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Tab selector
                    Picker("Competition Mode", selection: $selectedTab) {
                        Text("Quick Talk").tag(0)
                        Text("Leaderboard").tag(1)
                        Text("Badges").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case 0:
                        quickTalkView
                    case 1:
                        leaderboardView
                    case 2:
                        badgesView
                    default:
                        EmptyView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Compete")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Quick Talk Game
    
    private var quickTalkView: some View {
        VStack(spacing: 24) {
            // Find a match card
            findMatchCard
            
            // Active games
            if !viewModel.activeGames.isEmpty {
                activeGamesSection
            }
            
            // Game history
            if !viewModel.gameHistory.isEmpty {
                gameHistorySection
            } else {
                // If no games yet
                noGamesView
            }
        }
        .padding(.horizontal)
    }
    
    private var findMatchCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "FF9F1C"))
                .padding(.top, 8)
            
            Text("Quick Talk Challenge")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Compete with other learners in short speaking challenges")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.findMatch()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text(viewModel.isSearchingMatch ? "Finding a challenger..." : "Find a Match")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "00BFFF"))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isSearchingMatch)
            .overlay(
                Group {
                    if viewModel.isSearchingMatch {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                },
                alignment: .trailing
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var activeGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Challenges")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 4)
            
            ForEach(viewModel.activeGames) { game in
                activeGameRow(game)
            }
        }
    }
    
    private func activeGameRow(_ game: CompeteGame) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // User avatar
                Circle()
                    .fill(Color(hex: "00BFFF").opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(game.opponentName.prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "00BFFF"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.opponentName)
                        .font(.headline)
                    
                    Text("Level \(game.opponentLevel) • \(game.language)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                VStack {
                    if game.isWaitingForOpponent {
                        Text("Waiting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                    } else {
                        Text("Your turn")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FF9F1C"))
                        
                        Circle()
                            .fill(Color(hex: "FF9F1C"))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            // Prompt
            Text("\"\(game.prompt)\"")
                .font(.subheadline)
                .italic()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(6)
            
            // Action button
            Button(action: {
                if game.isWaitingForOpponent {
                    // Just view the game
                    viewModel.viewGame(game)
                } else {
                    // Record your response
                    viewModel.respondToGame(game)
                }
            }) {
                Text(game.isWaitingForOpponent ? "View Challenge" : "Record Response")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(game.isWaitingForOpponent ? Color.gray.opacity(0.3) : Color(hex: "00BFFF"))
                    .foregroundColor(game.isWaitingForOpponent ? .primary : .white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var gameHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Challenges")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 4)
            
            ForEach(viewModel.gameHistory) { game in
                historyGameRow(game)
            }
        }
    }
    
    private func historyGameRow(_ game: CompeteGame) -> some View {
        HStack(spacing: 16) {
            // Result indicator
            ZStack {
                Circle()
                    .fill(resultColor(for: game.result))
                    .frame(width: 40, height: 40)
                
                Image(systemName: resultIcon(for: game.result))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Game details
            VStack(alignment: .leading, spacing: 4) {
                Text(game.opponentName)
                    .font(.headline)
                
                Text("\(game.language) • \(formattedDate(game.completedDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // XP gained
            VStack {
                Text("+\(game.xpGained) XP")
                    .font(.headline)
                    .foregroundColor(Color(hex: "00BFFF"))
                
                Text("\(game.opponentScore) - \(game.userScore)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var noGamesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.secondary.opacity(0.5))
                .padding()
            
            Text("No games yet")
                .font(.headline)
            
            Text("Find a match to start competing with other learners")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Leaderboard
    
    private var leaderboardView: some View {
        VStack(spacing: 20) {
            // Tab selector for leaderboard type
            Picker("Leaderboard Type", selection: $viewModel.selectedLeaderboardType) {
                Text("XP Rank").tag(0)
                Text("Elo Rank").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // User's rank card
            userRankCard
            
            // Leaderboard list
            ForEach(viewModel.leaderboardEntries.indices, id: \.self) { index in
                leaderboardRow(entry: viewModel.leaderboardEntries[index], rank: index + 1)
            }
        }
        .padding(.horizontal)
    }
    
    private var userRankCard: some View {
        HStack(spacing: 16) {
            // Rank number
            Text("#\(viewModel.userRank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "FF9F1C"))
                .frame(width: 50)
            
            // User avatar
            Circle()
                .fill(Color(hex: "00BFFF").opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("Y") // First letter of user's name
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "00BFFF"))
                )
            
            // User details
            VStack(alignment: .leading, spacing: 4) {
                Text("You")
                    .font(.headline)
                
                Text("Level \(viewModel.userLevel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // XP or Elo score
            VStack {
                if viewModel.selectedLeaderboardType == 0 {
                    Text("\(viewModel.userXP) XP")
                        .font(.headline)
                        .foregroundColor(Color(hex: "00BFFF"))
                } else {
                    Text("\(viewModel.userElo) Elo")
                        .font(.headline)
                        .foregroundColor(Color(hex: "00BFFF"))
                }
            }
        }
        .padding()
        .background(Color(hex: "00BFFF").opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "00BFFF"), lineWidth: 2)
        )
    }
    
    private func leaderboardRow(entry: LeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 16) {
            // Rank number
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(rank <= 3 ? Color(hex: "FF9F1C") : .primary)
                .fontWeight(rank <= 3 ? .bold : .regular)
                .frame(width: 50)
            
            // User avatar
            Circle()
                .fill(rank <= 3 ? Color(hex: "FF9F1C").opacity(0.2) : Color.secondary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(entry.username.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(rank <= 3 ? Color(hex: "FF9F1C") : .secondary)
                )
            
            // User details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.username)
                    .font(.headline)
                
                Text("Level \(entry.level)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // XP or Elo score
            if viewModel.selectedLeaderboardType == 0 {
                Text("\(entry.xp) XP")
                    .font(.headline)
                    .foregroundColor(.primary)
            } else {
                Text("\(entry.elo) Elo")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            Group {
                if rank <= 3 {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "FF9F1C"), lineWidth: 1)
                }
            }
        )
    }
    
    // MARK: - Badges
    
    private var badgesView: some View {
        VStack(spacing: 24) {
            // Section headers for different badge categories
            Text("Your Achievement Badges")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            
            // Streak badges
            badgeSection(title: "Learning Streaks", badges: viewModel.streakBadges)
            
            // Study badges
            badgeSection(title: "Study Achievements", badges: viewModel.studyBadges)
            
            // Competition badges
            badgeSection(title: "Competition Achievements", badges: viewModel.competitionBadges)
        }
        .padding(.horizontal)
    }
    
    private func badgeSection(title: String, badges: [Badge]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(badges) { badge in
                    badgeItem(badge)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private func badgeItem(_ badge: Badge) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Color(hex: badge.color).opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 32))
                    .foregroundColor(badge.isUnlocked ? Color(hex: badge.color) : Color.gray.opacity(0.5))
                
                if !badge.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .offset(x: 24, y: 24)
                }
            }
            
            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(badge.isUnlocked ? .primary : .secondary)
            
            Text(badge.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)
        }
        .frame(width: 100)
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Functions
    
    private func resultColor(for result: GameResult) -> Color {
        switch result {
        case .win:
            return Color.green
        case .loss:
            return Color.red
        case .tie:
            return Color.orange
        }
    }
    
    private func resultIcon(for result: GameResult) -> String {
        switch result {
        case .win:
            return "trophy.fill"
        case .loss:
            return "xmark"
        case .tie:
            return "equal"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct CompeteView_Previews: PreviewProvider {
    static var previews: some View {
        CompeteView()
    }
} 