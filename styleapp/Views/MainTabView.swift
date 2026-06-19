import SwiftUI

struct MainTabView: View {
    @ObservedObject var auth: AuthService
    @StateObject private var battleManager = BattleManager()

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $battleManager.selectedTab) {
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "flame.fill")
                    }
                    .tag(0)

                ArenaView(battleManager: battleManager)
                    .tabItem {
                        Label("Arena", systemImage: "bolt.fill")
                    }
                    .tag(1)

                MyBattlesView()
                    .tabItem {
                        Label("Battles", systemImage: "shield.fill")
                    }
                    .tag(2)

                ProfileView(auth: auth)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .tint(Color("AccentColor"))

            // Progress bar — sits at very top, visible across all tabs
            if battleManager.isUploading {
                VStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 3)

                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(width: UIScreen.main.bounds.width * battleManager.progress, height: 3)
                            .animation(.easeInOut(duration: 0.4), value: battleManager.progress)
                    }

                    if !battleManager.statusMessage.isEmpty {
                        Text(battleManager.statusMessage)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color("Background").opacity(0.95))
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(99)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: battleManager.isUploading)
    }
}

#Preview {
    MainTabView(auth: AuthService())
}
