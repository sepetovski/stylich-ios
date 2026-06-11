import SwiftUI

struct MainTabView: View {
    @ObservedObject var auth: AuthService

    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "flame.fill")
                }

            ArenaView()
                .tabItem {
                    Label("Arena", systemImage: "bolt.fill")
                }

            MyBattlesView()
                .tabItem {
                    Label("Battles", systemImage: "shield.fill")
                }

            ProfileView(auth: auth)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color("AccentColor"))
    }
}

#Preview {
    MainTabView(auth: AuthService())
}
