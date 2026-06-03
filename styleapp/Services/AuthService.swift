import Foundation
import Combine
import Supabase

class AuthService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage = ""

    func login(email: String, password: String) async {
        do {
            try await supabase.auth.signIn(
                email: email,
                password: password
            )
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func checkSession() async {
        do {
            _ = try await supabase.auth.session
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            await MainActor.run {
                self.isLoggedIn = false
            }
        }
    }
    
    func logout() async {
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                self.isLoggedIn = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
