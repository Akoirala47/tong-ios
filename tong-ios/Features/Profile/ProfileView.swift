import SwiftUI

struct ProfileView: View {
    @ObservedObject var statsViewModel: ProfileStatsViewModel
    let userId: String
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingSignOutConfirmation = false
    @State private var selectedLanguage = "Japanese"
    private let availableLanguages = ["Japanese", "Spanish", "French", "German", "Korean"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Panel with XP Level Ring
                        VStack(spacing: 16) {
                            ZStack {
                                // XP Level Ring
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 10)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(statsViewModel.xp % 1000) / 1000.0)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "00BFFF"), Color(hex: "FF9F1C")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                // User avatar
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                    .shadow(radius: 5)
                            }
                            .padding(.top, 20)
                            
                            Text(getUserEmail())
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Level \(statsViewModel.level)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(Color(hex: "00BFFF"))
                            
                            Text("Started learning on \(formatDate())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 30)
                        
                        // Stats Overview
                        VStack(spacing: 16) {
                            HStack {
                                Text("Your Progress")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Stats cards
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(title: "Flashcards Reviewed", value: "237", icon: "flashcard", color: Color(hex: "00BFFF"))
                                StatCard(title: "Current Streak", value: "\(statsViewModel.streak)", icon: "flame.fill", color: Color(hex: "FF9F1C"))
                                StatCard(title: "Total XP", value: "\(statsViewModel.xp)", icon: "star.fill", color: Color(hex: "00BFFF"))
                                StatCard(title: "Lessons Completed", value: "5", icon: "book.closed.fill", color: Color(hex: "FF9F1C"))
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Pro Subscription Status Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.yellow)
                                    .cornerRadius(8)
                                
                                Text("Tong Pro")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("Free Trial")
                                    .font(.callout)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(10)
                            }
                            
                            Text("Unlock unlimited lessons, AI voice analysis, and advanced progress tracking.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                // Upgrade action
                            }) {
                                Text("Upgrade to Pro")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Settings Drawer
                        VStack(spacing: 0) {
                            // Language preference
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(availableLanguages, id: \.self) { language in
                                        Button(action: {
                                            selectedLanguage = language
                                        }) {
                                            HStack {
                                                Text(language)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                                
                                                if selectedLanguage == language {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(Color(hex: "00BFFF"))
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            } label: {
                                SettingsRow(icon: "globe", title: "Learning Language", color: Color(hex: "00BFFF"), showChevron: false)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().padding(.leading, 56)
                            
                            // Notifications
                            NavigationLink(destination: Text("Notifications Settings").navigationTitle("Notifications")) {
                                SettingsRow(icon: "bell.fill", title: "Notifications", color: .purple)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().padding(.leading, 56)
                            
                            // Privacy Settings
                            NavigationLink(destination: Text("Privacy Settings").navigationTitle("Privacy")) {
                                SettingsRow(icon: "lock.fill", title: "Privacy Settings", color: .blue)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().padding(.leading, 56)
                            
                            // Support & Feedback
                            NavigationLink(destination: Text("Support & Feedback").navigationTitle("Support")) {
                                SettingsRow(icon: "questionmark.circle.fill", title: "Support & Feedback", color: .green)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().padding(.leading, 56)
                            
                            // Sign Out
                            Button(action: {
                                showingSignOutConfirmation = true
                            }) {
                                SettingsRow(icon: "arrow.right.square", title: "Sign Out", color: .red)
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                Task { await statsViewModel.fetchProfileStats(userId: userId) }
            }
        }
    }
    
    private func getUserEmail() -> String {
        return SupabaseManager.shared.client.auth.currentUser?.email ?? "User"
    }
    
    private func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // Normally would use user creation date, using current date as placeholder
        return formatter.string(from: Date())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18))
                }
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    var color: Color
    var showChevron: Bool = true
    var trailingText: String? = nil
    var trailingColor: Color? = nil
    var isToggle: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
                .padding(.leading)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let text = trailingText {
                Text(text)
                    .font(.callout)
                    .foregroundColor(trailingColor ?? .secondary)
            }
            
            if isToggle {
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    let vm = ProfileStatsViewModel()
    vm.streak = 7
    vm.xp = 450
    vm.level = 3
    return ProfileView(statsViewModel: vm, userId: "preview-user", authViewModel: AuthViewModel())
}

 