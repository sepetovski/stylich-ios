import SwiftUI
import Combine

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let color: Color
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var current: AppNotification? = nil
    private var hideTask: Task<Void, Never>?

    func show(title: String, message: String, icon: String = "bell.fill", color: Color = Color("AccentColor")) {
        hideTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            current = AppNotification(title: title, message: message, icon: icon, color: color)
        }
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    self.current = nil
                }
            }
        }
    }

    func dismiss() {
        hideTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            current = nil
        }
    }
}
