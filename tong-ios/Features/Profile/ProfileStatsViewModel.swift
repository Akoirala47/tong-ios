import Foundation
import Supabase

@MainActor
final class ProfileStatsViewModel: ObservableObject {
    @Published var streak: Int = 0
    @Published var xp: Int = 0
    @Published var level: Int = 1
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client

    func fetchProfileStats(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let profiles: [ProfileStats] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            if let profile = profiles.first {
                self.streak = profile.streak
                self.xp = profile.xp
                self.level = profile.level
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ProfileStats: Decodable {
    let id: String
    let streak: Int
    let xp: Int
    let level: Int
} 