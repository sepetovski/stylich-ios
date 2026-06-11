import SwiftUI
import Supabase

struct MyBattlesView: View {
    @StateObject private var service = BattlesHistoryService()
    @State private var userId = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                if service.isLoading {
                    ProgressView()
                } else if service.battles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.slash")
                            .font(.system(size: 48))
                            .foregroundColor(Color("AccentColor"))
                        Text("No battles yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Enter the arena to start battling")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(service.battles) { battle in
                                BattleCard(battle: battle, userId: userId)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("My Battles")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if let session = try? await supabase.auth.session {
                    userId = session.user.id.uuidString
                    await service.fetchBattles(userId: userId)
                }
            }
        }
    }
}

struct BattleCard: View {
    let battle: Battle
    let userId: String

    var isP1: Bool { battle.p1User == userId }
    var myScore: Int? { isP1 ? battle.p1Score : battle.p2Score }
    var opponentScore: Int? { isP1 ? battle.p2Score : battle.p1Score }
    var myImage: String { isP1 ? battle.p1Image : (battle.p2Image ?? "") }
    var myFeedback: String? { isP1 ? battle.p1Feedback : battle.p2Feedback }

    var result: String {
        guard battle.status == "judged" else { return battle.status }
        if let winner = battle.winner {
            return winner == userId ? "win" : "loss"
        }
        return "draw"
    }

    var resultColor: Color {
        switch result {
        case "win": return .green
        case "loss": return .red
        case "draw": return Color("AccentColor")
        default: return .secondary
        }
    }

    var resultLabel: String {
        switch result {
        case "win": return "WIN 👑"
        case "loss": return "LOSS"
        case "draw": return "DRAW"
        case "waiting": return "WAITING..."
        default: return result.uppercased()
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // My outfit photo
            AsyncImage(url: URL(string: myImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            }
            .frame(width: 80, height: 100)
            .clipped()
            .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Result badge
                Text(resultLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(resultColor)

                // Score
                if let myScore = myScore {
                    HStack(spacing: 4) {
                        Text("You:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(myScore)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AccentColor"))

                        if let opponentScore = opponentScore {
                            Text("vs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(opponentScore)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }

                // Category
                if let category = battle.category {
                    Text(category.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }

                // Feedback
                if let feedback = myFeedback {
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.07))
        .cornerRadius(16)
    }
}

#Preview {
    MyBattlesView()
}
