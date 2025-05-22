import SwiftUI

struct ProgressRingsView: View {
    var currentLevelData: LevelData?
    var completedLevelData: [LevelData]
    
    @State private var animateRing = false
    
    let levelCategories: [(categoryName: String, levels: [LevelData])] = [
        ("Novice", LevelData.allCases.filter { $0.name.starts(with: "Novice") }),
        ("Intermediate", LevelData.allCases.filter { $0.name.starts(with: "Intermediate") }),
        ("Advanced", LevelData.allCases.filter { $0.name.starts(with: "Advanced") }),
        ("Superior", LevelData.allCases.filter { $0.name.starts(with: "Superior") })
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(levelCategories, id: \.categoryName) { categoryGroup in
                    levelClusterView(category: categoryGroup.categoryName, levels: categoryGroup.levels)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateRing = true
            }
        }
    }
    
    private func levelClusterView(category: String, levels: [LevelData]) -> some View {
        VStack(spacing: 12) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(levels, id: \.self) { level in
                    levelRingView(level: level)
                }
            }
        }
    }
    
    private func levelRingView(level: LevelData) -> some View {
        let isCurrent = currentLevelData == level
        let isCompleted = completedLevelData.contains(level)
        let isLocked = !isCompleted && (currentLevelData == nil || level.order > currentLevelData!.order)
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(
                        isLocked ? Color.gray.opacity(0.3) : Color(hex: level.color).opacity(0.3),
                        lineWidth: 4
                    )
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Circle()
                        .fill(Color(hex: level.color))
                        .frame(width: 40, height: 40)
                }
                
                if isCurrent {
                    Circle()
                        .trim(from: 0, to: animateRing ? 1.0 : 0.2)
                        .stroke(
                            Color(hex: level.color),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(hex: level.color).opacity(0.6), radius: animateRing ? 4 : 0)
                }
                
                Text(level.shortName.prefix(1))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isCompleted || isLocked ? .white : Color(hex: level.color))
            }
            
            Text(level.shortName)
                .font(.system(size: 10))
                .foregroundColor(isLocked ? .gray : Color(hex: level.color))
        }
    }
}

#Preview("Progress Rings") {
    VStack {
        ProgressRingsView(
            currentLevelData: LevelData.getLevel(forCode: "IH"),
            completedLevelData: [
                LevelData.getLevel(forCode: "NL"), 
                LevelData.getLevel(forCode: "NM"), 
                LevelData.getLevel(forCode: "NH"), 
                LevelData.getLevel(forCode: "IL"), 
                LevelData.getLevel(forCode: "IM")
            ]
        )
        .frame(height: 120)
        .padding()
        .background(Color(.systemBackground))
        
        ProgressRingsView(
            currentLevelData: LevelData.getLevel(forCode: "NL"),
            completedLevelData: []
        )
        .frame(height: 120)
        .padding()
        .background(Color(.systemBackground))
        
        ProgressRingsView(
            currentLevelData: LevelData.getLevel(forCode: "S"),
            completedLevelData: LevelData.allCases.filter { $0.code != "S" }
        )
        .frame(height: 120)
        .padding()
        .background(Color(.systemBackground))
    }
    .preferredColorScheme(.light)
} 