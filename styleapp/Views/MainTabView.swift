import SwiftUI

struct MainTabView: View {
    @ObservedObject var auth: AuthService

    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "flame.fill")
                }

            Text("Arena")
                .tabItem {
                    Label("Arena", systemImage: "bolt.fill")
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
