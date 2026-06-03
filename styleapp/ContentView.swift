import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthService()

    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView(auth: auth)
            } else {
                LoginView(auth: auth)
            }
        }
        .task {
            await auth.checkSession()
        }
    }
}

#Preview {
    ContentView()
}
