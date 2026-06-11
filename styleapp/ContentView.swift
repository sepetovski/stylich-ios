import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthService()
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some View {
        ZStack(alignment: .top) {
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

            // Notification banner
            if let notification = notificationManager.current {
                NotificationBanner(notification: notification) {
                    notificationManager.dismiss()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
                .padding(.top, 56)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: notificationManager.current?.id)
    }
}

#Preview {
    ContentView()
}
