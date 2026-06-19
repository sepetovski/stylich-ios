import SwiftUI
import Supabase

struct MyBattlesView: View {
    @StateObject private var service = BattlesHistoryService()
    @State private var userId = ""
    @State private var selectedBattle: Battle? = nil

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
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            selectedBattle = battle
                                        }
                                    }
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
                    userId = session.user.id.uuidString.lowercased()
                    await service.fetchBattles(userId: userId)
                }
            }
        }
        .overlay {
            if let battle = selectedBattle {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                selectedBattle = nil
                            }
                        }

                    BattleDetailCard(battle: battle, userId: userId)
                        .padding(.horizontal, 20)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .scale(scale: 0.85).combined(with: .opacity)
                        ))
                        .contentShape(Rectangle())
                        .onTapGesture { }
                }
            }
        }
    }
}

// MARK: - Battle Card

struct BattleCard: View {
    let battle: Battle
    let userId: String

    var isP1: Bool { battle.p1User.lowercased() == userId.lowercased() }
    var myScore: Int? { isP1 ? battle.p1Score : battle.p2Score }
    var opponentScore: Int? { isP1 ? battle.p2Score : battle.p1Score }
    var myImage: String { isP1 ? battle.p1Image : (battle.p2Image ?? "") }
    var myFeedback: String? { isP1 ? battle.p1Feedback : battle.p2Feedback }
    var opponentUsername: String { battle.opponentUsername }

    var result: String {
        guard battle.status == "judged" else { return battle.status }
        if let winner = battle.winner {
            return winner.lowercased() == userId.lowercased() ? "win" : "loss"
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
            AsyncImage(url: URL(string: myImage)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            }
            .frame(width: 80, height: 100)
            .clipped()
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                Text(resultLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(resultColor)

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

                if battle.status == "judged" {
                    Text("vs @\(opponentUsername)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let category = battle.category {
                    Text(category.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }

                if let feedback = myFeedback {
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.07))
        .cornerRadius(16)
    }
}

// MARK: - Battle Detail Card

struct BattleDetailCard: View {
    let battle: Battle
    let userId: String
    @State private var showingOpponent = false

    var isP1: Bool { battle.p1User.lowercased() == userId.lowercased() }
    var myImage: String { isP1 ? battle.p1Image : (battle.p2Image ?? "") }
    var opponentImage: String { isP1 ? (battle.p2Image ?? "") : battle.p1Image }
    var myScore: Int? { isP1 ? battle.p1Score : battle.p2Score }
    var opponentScore: Int? { isP1 ? battle.p2Score : battle.p1Score }
    var myFeedback: String? { isP1 ? battle.p1Feedback : battle.p2Feedback }
    var opponentFeedback: String? { isP1 ? battle.p2Feedback : battle.p1Feedback }
    var opponentUsername: String { battle.opponentUsername }

    var result: String {
        guard battle.status == "judged" else { return battle.status }
        if let winner = battle.winner {
            return winner.lowercased() == userId.lowercased() ? "win" : "loss"
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

    var activeFeedback: String? { showingOpponent ? opponentFeedback : myFeedback }
    var activeFeedbackLabel: String {
        showingOpponent ? "StyleMogg on @\(opponentUsername)'s fit" : "StyleMogg on your fit"
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: — Side by side photos
            HStack(spacing: 3) {

                // My photo
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: myImage)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()

                    if !showingOpponent {
                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingOpponent = false
                    }
                }
                .overlay(
                    VStack {
                        HStack {
                            Text("You")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.45))
                                .cornerRadius(6)
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                )

                // Opponent photo
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: opponentImage)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                battle.status == "waiting"
                                ? AnyView(VStack(spacing: 6) {
                                    Image(systemName: "hourglass")
                                        .foregroundColor(.secondary)
                                    Text("Waiting...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                })
                                : AnyView(ProgressView())
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()

                    if showingOpponent {
                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    if battle.status == "judged" {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingOpponent = true
                        }
                    }
                }
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Text("@\(opponentUsername)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.45))
                                .cornerRadius(6)
                                .padding(8)
                        }
                        Spacer()
                    }
                )
            }

            // MARK: — Info section
            VStack(alignment: .leading, spacing: 14) {

                // Result + category
                HStack {
                    if battle.status == "waiting" {
                        Label("Waiting for opponent", systemImage: "hourglass")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(result == "win" ? "You won! 👑" : result == "loss" ? "You lost" : "Draw 🤝")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(resultColor)
                    }
                    Spacer()
                    if let category = battle.category {
                        Text(category.replacingOccurrences(of: "_", with: " "))
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(8)
                    }
                }

                // Scores
                if battle.status == "judged" {
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text("\(myScore ?? 0)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(!showingOpponent ? Color("AccentColor") : .primary)
                            Text("you")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Text("vs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 2) {
                            Text("\(opponentScore ?? 0)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(showingOpponent ? Color("AccentColor") : .primary)
                            Text("them")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                }

                // Feedback
                if let feedback = activeFeedback {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(activeFeedbackLabel, systemImage: "sparkles")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text(feedback)
                            .font(.subheadline)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(showingOpponent)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                    .animation(.easeInOut(duration: 0.2), value: showingOpponent)
                }
            }
            .padding(16)
            .background(Color("Background"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    MyBattlesView()
}
