import SwiftUI

struct BattleResultView: View {
    let result: BattleResult
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                if result.status == "queued" {
                    // queued UI
                    VStack(spacing: 16) {
                        Image(systemName: "clock.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(Color("AccentColor"))

                        Text("You're in the queue! ⏳")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("The AI is busy right now. Your fit has been saved and will be judged automatically. We'll let you know when it's done!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                } else if result.status == "waiting" {
                    // waiting UI
                    VStack(spacing: 16) {
                        Image(systemName: "hourglass.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(Color("AccentColor"))

                        Text("Fit dropped! 🔥")
                            .font(.title)
                            .fontWeight(.bold)

                        if let score = result.score {
                            VStack(spacing: 4) {
                                Text("\(score)")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundColor(Color("AccentColor"))
                                Text("your score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let feedback = result.feedback {
                            Text(feedback)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                        }

                        Text("Waiting for an opponent...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                } else {
                    // judged UI — only runs when status == "judged"
                    VStack(spacing: 16) {
                        if let isWinner = result.isWinner {
                            Image(systemName: isWinner ? "crown.fill" : "bolt.fill")
                                .font(.system(size: 72))
                                .foregroundColor(isWinner ? .yellow : Color("AccentColor"))

                            Text(isWinner ? "You won! 👑" : "You lost!")
                                .font(.title)
                                .fontWeight(.bold)
                        }

                        HStack(spacing: 32) {
                            VStack(spacing: 4) {
                                Text("\(result.score ?? 0)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(Color("AccentColor"))
                                Text("your score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("vs")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            VStack(spacing: 4) {
                                Text("\(result.opponentScore ?? 0)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("their score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)

                        if let feedback = result.feedback {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("StyleMogg says:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(feedback)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Back to arena")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
