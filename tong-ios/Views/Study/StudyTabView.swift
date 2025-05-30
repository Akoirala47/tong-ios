import SwiftUI

struct StudyTabView: View {
    @ObservedObject var drillViewModel: FlashcardDrillViewModel
    let userId: String
    @State private var selectedLanguage: String?
    
    let availableLanguages = [
        ("Spanish", "es", "🇪🇸"),
        ("French", "fr", "🇫🇷"),
        ("Japanese", "jp", "🇯🇵"),
        ("Chinese", "zh", "🇨🇳")
    ]
    
    // Dummy recent activities for prototype
    let recentActivities = [
        RecentActivity(
            languageCode: "es",
            languageName: "Spanish",
            activityType: .learnCompleted,
            topicName: "Greetings",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        RecentActivity(
            languageCode: "fr",
            languageName: "French",
            activityType: .reviewCompleted,
            itemCount: 15,
            timestamp: Date().addingTimeInterval(-86400)
        ),
        RecentActivity(
            languageCode: "es",
            languageName: "Spanish",
            activityType: .bossBattle,
            levelName: "Novice Low",
            timestamp: Date().addingTimeInterval(-172800)
        ),
        RecentActivity(
            languageCode: "jp",
            languageName: "Japanese",
            activityType: .learnCompleted,
            topicName: "Numbers",
            timestamp: Date().addingTimeInterval(-259200)
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedLanguage == nil {
                    // Language selection screen (Study Menu)
                    studyMenuView
                } else {
                    // Content for selected language
                    languageContentView
                }
            }
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedLanguage != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            selectedLanguage = nil
                        }) {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
            }
        }
    }
    
    private var studyMenuView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Language strip at top
                languageStripView
                    .padding(.top)
                
                // Recent Activity feed
                recentActivityFeedView
            }
            .padding(.vertical)
        }
    }
    
    private var languageStripView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Languages")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableLanguages, id: \.0) { language in
                        languagePillView(language)
                    }
                    
                    // Add language button
                    addLanguagePillView
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func languagePillView(_ language: (name: String, code: String, flag: String)) -> some View {
        Button(action: {
            selectedLanguage = language.code
        }) {
            HStack(spacing: 10) {
                // Flag/emoji
                Text(language.flag)
                    .font(.title2)
                
                // Language name
                Text(language.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 20, height: 20)
                    
                    // This would show actual progress - hardcoded for now
                    let progress: Double = language.code == "es" ? 0.65 :
                                          language.code == "fr" ? 0.40 :
                                          language.code == "jp" ? 0.25 : 0.15
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color(hex: "00BFFF"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
    }
    
    private var addLanguagePillView: some View {
        Button(action: {
            // Action to add a new language
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(hex: "00BFFF"))
                
                Text("Add Language")
                    .font(.headline)
                    .foregroundColor(Color(hex: "00BFFF"))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color(hex: "00BFFF").opacity(0.1))
            .cornerRadius(20)
        }
    }
    
    private var recentActivityFeedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(recentActivities) { activity in
                Button(action: {
                    // Navigate to the activity
                    selectedLanguage = activity.languageCode
                }) {
                    HStack(spacing: 16) {
                        // Activity icon
                        ZStack {
                            Circle()
                                .fill(activity.activityType.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: activity.activityType.icon)
                                .foregroundColor(activity.activityType.color)
                                .font(.system(size: 20))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.activityType.title(for: activity))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(activityDescription(for: activity))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Time ago
                        Text(timeAgo(from: activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var languageContentView: some View {
        if let code = selectedLanguage {
            // Avoid nested NavigationStacks which can cause navigation issues
            LanguageDashboardView(languageCode: code, userId: userId)
        } else {
            Text("Please select a language")
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private func activityDescription(for activity: RecentActivity) -> String {
        switch activity.activityType {
        case .learnCompleted:
            return "\(activity.languageName) • Topic: \(activity.topicName ?? "Unknown")"
        case .reviewCompleted:
            return "\(activity.languageName) • \(activity.itemCount ?? 0) cards reviewed"
        case .bossBattle:
            return "\(activity.languageName) • Level: \(activity.levelName ?? "Unknown")"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else {
            return "Just now"
        }
    }
}

// Model for Recent Activity
struct RecentActivity: Identifiable {
    let id = UUID()
    let languageCode: String
    let languageName: String
    let activityType: ActivityType
    var topicName: String?
    var itemCount: Int?
    var levelName: String?
    let timestamp: Date
    
    enum ActivityType {
        case learnCompleted
        case reviewCompleted
        case bossBattle
        
        var icon: String {
            switch self {
            case .learnCompleted: return "book.fill"
            case .reviewCompleted: return "arrow.counterclockwise"
            case .bossBattle: return "crown.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .learnCompleted: return Color(hex: "00BFFF")
            case .reviewCompleted: return Color(hex: "8A2BE2")
            case .bossBattle: return Color(hex: "FF9F1C")
            }
        }
        
        func title(for activity: RecentActivity) -> String {
            switch self {
            case .learnCompleted:
                return "Lesson Completed"
            case .reviewCompleted:
                if let count = activity.itemCount {
                    return "Reviewed \(count) Cards"
                } else {
                    return "Reviewed Cards"
                }
            case .bossBattle:
                return "Boss Battle Completed"
            }
        }
    }
}

#Preview {
    StudyTabView(
        drillViewModel: FlashcardDrillViewModel(),
        userId: "preview-user"
    )
} 