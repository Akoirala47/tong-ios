import SwiftUI

struct ProfileStatsView: View {
    @ObservedObject var viewModel: ProfileStatsViewModel

    var body: some View {
        HStack(spacing: 24) {
            VStack {
                Text("🔥")
                    .font(.largeTitle)
                Text("Streak")
                    .font(.caption)
                Text("\(viewModel.streak)")
                    .font(.title2)
                    .bold()
            }
            VStack(alignment: .leading) {
                Text("XP")
                    .font(.caption)
                ProgressView(value: Double(viewModel.xp % 1000) / 1000.0)
                    .frame(width: 120)
                Text("Level \(viewModel.level)")
                    .font(.caption)
            }
        }
        .padding()
    }
}

#Preview {
    let vm = ProfileStatsViewModel()
    vm.streak = 7
    vm.xp = 450
    vm.level = 3
    return ProfileStatsView(viewModel: vm)
} 