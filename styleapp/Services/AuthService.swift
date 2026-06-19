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
    
    func signUp(email: String, password: String, username: String) async {
        do {
            try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["username": AnyJSON.string(username)]
            )
            
            // Update the profile with the chosen username
            let session = try await supabase.auth.session
            try await supabase
                .from("profiles")
                .update(["username": username])
                .eq("id", value: session.user.id.uuidString)
                .execute()
            
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func signInWithApple() async {
        await MainActor.run {
            self.errorMessage = "Apple Sign In coming soon!"
        }
    }


    

    func signInWithGoogle() async {
        // Coming soon
    }
    
}
