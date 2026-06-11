import SwiftUI

struct LoginView: View {
    @ObservedObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showSignUp = false
    

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Text("stylich")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color("AccentColor"))
                    Text("drop a fit. mog the queue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .sheet(isPresented: $showSignUp) {
                            SignUpView(auth: auth)
                        }
                }

                // Fields
                VStack(spacing: 12) {
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

                // Error message
                if !auth.errorMessage.isEmpty {
                    Text(auth.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 32)
                }

                // Button
                Button {
                    isLoading = true
                    Task {
                        await auth.login(email: email, password: password)
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
                        Text("Enter the arena")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(.black)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 32)
                .disabled(isLoading)

                Spacer()
                
                Button {
                    showSignUp = true
                } label: {
                    Text("New here? Create an account")
                        .font(.subheadline)
                        .foregroundColor(Color("AccentColor"))
                }
            }
        }
    }
}

#Preview {
    LoginView(auth: AuthService())
}
