import SwiftUI

struct SignUpView: View {
    @ObservedObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 8) {
                        Text("stylich")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(Color("AccentColor"))
                        Text("create your account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // Email fields
                    VStack(spacing: 12) {
                        TextField("Username", text: $username)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .autocapitalization(.none)

                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)

                    // Error
                    if !auth.errorMessage.isEmpty {
                        Text(auth.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 32)
                    }

                    // Sign up button
                    Button {
                        isLoading = true
                        Task {
                            await auth.signUp(email: email, password: password, username: username)
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .cornerRadius(14)
                        } else {
                            Text("Create account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.black)
                                .cornerRadius(14)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || username.isEmpty || isLoading)
                    .padding(.horizontal, 32)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("or").foregroundColor(.secondary).font(.caption)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // Social buttons
                    VStack(spacing: 12) {
                        // Apple
                        Button {
                            Task { await auth.signInWithApple() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Continue with Apple")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(Color("Background"))
                            .cornerRadius(14)
                        }

                        // Google
                        Button {
                            Task { await auth.signInWithGoogle() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Continue with Google")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 32)

                    // Back to login
                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? Log in")
                            .font(.subheadline)
                            .foregroundColor(Color("AccentColor"))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    SignUpView(auth: AuthService())
}
