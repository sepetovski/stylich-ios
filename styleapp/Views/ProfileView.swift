import SwiftUI
import Supabase

struct ProfileView: View {
    @ObservedObject var auth: AuthService
    @StateObject private var profileService = ProfileService()

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if profileService.isLoading {
                ProgressView()
            } else if let profile = profileService.profile {
                ScrollView {
                    VStack(spacing: 24) {

                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color("AccentColor").opacity(0.2))
                                .frame(width: 90, height: 90)
                            Text(String(profile.username.prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color("AccentColor"))
                        }
                        .padding(.top, 48)

                        // Username
                        Text("@\(profile.username)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        // Stats grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatCard(value: "\(profile.battles)", label: "Battles")
                            StatCard(value: "\(profile.wins)", label: "Wins")
                            StatCard(value: "\(winRate(profile))%", label: "Win Rate")
                            StatCard(value: "\(profile.totalScore)", label: "Total Score")
                            StatCard(value: "\(profile.currentStreak)🔥", label: "Streak")
                            StatCard(value: "\(profile.bestStreak)", label: "Best Streak")
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 32)

                        // Logout
                        Button {
                            Task { await auth.logout() }
                        } label: {
                            Text("Log out")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 48))
                        .foregroundColor(Color("AccentColor"))
                    Text("Could not load profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !profileService.errorMessage.isEmpty {
                        Text(profileService.errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .task {
            if let userId = try? await supabase.auth.session.user.id.uuidString {
                await profileService.fetchProfile(userId: userId)
            }
        }
    }

    func winRate(_ profile: Profile) -> Int {
        guard profile.battles > 0 else { return 0 }
        return Int((Double(profile.wins) / Double(profile.battles)) * 100)
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(14)
    }
}

#Preview {
    ProfileView(auth: AuthService())
}
