import Foundation
import Supabase
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    
    // Add computed property to access the current user ID
    var currentUserId: String? {
        client.auth.currentUser?.id.uuidString
    }
    
    private let client = SupabaseService.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check current session status when initializing
        Task {
            await checkSession()
            // Start listening for auth changes
            await subscribeToAuthChanges()
        }
    }
    
    func checkSession() async {
        // Check if there's a session by looking for the current user
        isAuthenticated = client.auth.currentUser != nil
        print("[DEBUG] Session check: User is \(isAuthenticated ? "authenticated" : "not authenticated")")
    }
    
    private func subscribeToAuthChanges() async {
        // Create a Task to handle the AsyncStream
        Task { [weak self] in
            guard let self = self else { return }
            
            for await authState in client.auth.authStateChanges {
                print("[DEBUG] Auth state change: \(authState.event)")
                
                // Update the authentication state on the main actor
                await MainActor.run {
                    switch authState.event {
                    case .initialSession:
                        // Only mark as authenticated if a valid session exists
                        let hasSession = authState.session != nil
                        self.isAuthenticated = hasSession
                        print("[DEBUG] initialSession event – hasSession: \(hasSession)")
                    case .signedIn:
                        self.isAuthenticated = true
                    case .signedOut, .userDeleted:
                        self.isAuthenticated = false
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func signInWithPassword() async {
        do {
            print("[DEBUG] Attempting sign in for \(email)")
            try await client.auth.signIn(email: email, password: password)
            print("[DEBUG] Sign in successful for \(email)")
            isAuthenticated = true
            do {
                try await onboardUser()
                print("[DEBUG] Onboarding complete for \(email)")
            } catch {
                print("[DEBUG] Onboarding error: \(error)")
            }
        } catch {
            print("[DEBUG] Sign in error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func signUpWithEmail() async {
        do {
            try await client.auth.signUp(email: email, password: password)
            isAuthenticated = true
            try await onboardUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signInWithMagicLink() async {
        do {
            try await client.auth.signInWithOTP(email: email)
            // User must check their email for the magic link
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            print("[DEBUG] User signed out successfully")
        } catch {
            print("[DEBUG] Error signing out: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func onboardUser() async throws {
        guard let user = client.auth.currentUser else { return }
        let userIdString = user.id.uuidString // Convert UUID to String
        // Check if profile exists
        let profiles: [Profile] = try await client.from("profiles").select().eq("id", value: userIdString).execute().value
        if profiles.isEmpty {
            // Create profile
            let email = user.email ?? ""
            let username = email.components(separatedBy: "@").first ?? "user"
            let profileInsert = ProfileInsert(id: userIdString, email: email, username: username)
            _ = try await client.from("profiles").insert(profileInsert).execute()
            // Create default daily_streaks row
            let today = ISO8601DateFormatter().string(from: Date())
            let streakInsert = DailyStreakInsert(user_id: userIdString, date: today, streak: 0)
            _ = try await client.from("daily_streaks").insert(streakInsert).execute()
        }
    }
}

// MARK: - Profile Model
struct Profile: Decodable {
    let id: String
    let email: String?
    let username: String?
}

struct ProfileInsert: Encodable {
    let id: String
    let email: String
    let username: String
}

struct DailyStreakInsert: Encodable {
    let user_id: String
    let date: String
    let streak: Int
} 
 
