import SwiftUI

struct ProfileView: View {
    @ObservedObject var auth: AuthService

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color("AccentColor").opacity(0.2))
                        .frame(width: 90, height: 90)

                    Text("S")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("AccentColor"))
                }

                // Username
                Text("stylich user")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Stats row
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("0")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Battles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 4) {
                        Text("0")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Wins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 4) {
                        Text("0")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Rating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 32)

                Spacer()

                // Logout button
                Button {
                    Task {
                        await auth.logout()
                    }
                } label: {
                    Text("Log out")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .padding(.top, 48)
        }
    }
}

#Preview {
    ProfileView(auth: AuthService())
}
