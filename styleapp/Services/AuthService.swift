import Foundation
import Combine
import Supabase
import AuthenticationServices
import CryptoKit

class AuthService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var errorMessage = ""
    private var appleSignInDelegate: AppleSignInDelegate?

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
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let nonce = randomNonceString()
            request.nonce = sha256(nonce)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(nonce: nonce) { result in
                Task {
                    switch result {
                    case .success(let credential):
                        do {
                            try await supabase.auth.signInWithIdToken(
                                credentials: .init(
                                    provider: .apple,
                                    idToken: credential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                                )
                            )
                            await MainActor.run { self.isLoggedIn = true }
                        } catch {
                            await MainActor.run { self.errorMessage = error.localizedDescription }
                        }
                    case .failure(let error):
                        await MainActor.run { self.errorMessage = error.localizedDescription }
                    }
                }
            }
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            self.appleSignInDelegate = delegate
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess { fatalError("Unable to generate nonce.") }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    func signInWithGoogle() async {
        // Coming soon
    }
    
}
