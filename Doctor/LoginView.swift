import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showRegistration = false
    @State private var animateGradient = false
    @State private var showForgotPassword = false
    @State private var rememberMe = false
    @State private var showError = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                AnimatedLoginBackground(animate: $animateGradient)

                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and Welcome
                        VStack(spacing: 25) {
                            // Animated Logo
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.appPrimary, .appSecondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .appPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                                    .scaleEffect(animateGradient ? 1.05 : 0.95)
                                    .animation(
                                        .easeInOut(duration: 2)
                                        .repeatForever(autoreverses: true),
                                        value: animateGradient
                                    )

                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(animateGradient ? 5 : -5))
                                    .animation(
                                        .easeInOut(duration: 3)
                                        .repeatForever(autoreverses: true),
                                        value: animateGradient
                                    )
                            }

                            VStack(spacing: 10) {
                                Text("Bon retour!")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.appPrimary, .appSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Connectez-vous à votre compte")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 60)

                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email", systemImage: "envelope.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                HStack(spacing: 15) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(focusedField == .email ? .appPrimary : .gray)

                                    TextField("john.doe@example.com", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .textContentType(.emailAddress)
                                        .focused($focusedField, equals: .email)

                                    if !email.isEmpty {
                                        Button(action: { email = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(
                                                    focusedField == .email ? Color.appPrimary : Color.gray.opacity(0.2),
                                                    lineWidth: 2
                                                )
                                        )
                                )
                                .shadow(
                                    color: focusedField == .email ? Color.appPrimary.opacity(0.1) : .clear,
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Mot de passe", systemImage: "lock.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)

                                HStack(spacing: 15) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(focusedField == .password ? .appPrimary : .gray)

                                    if showPassword {
                                        TextField("••••••••", text: $password)
                                            .textContentType(.password)
                                            .focused($focusedField, equals: .password)
                                    } else {
                                        SecureField("••••••••", text: $password)
                                            .textContentType(.password)
                                            .focused($focusedField, equals: .password)
                                    }

                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(
                                                    focusedField == .password ? Color.appPrimary : Color.gray.opacity(0.2),
                                                    lineWidth: 2
                                                )
                                        )
                                )
                                .shadow(
                                    color: focusedField == .password ? Color.appPrimary.opacity(0.1) : .clear,
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                            }

                            // Remember Me & Forgot Password
                            HStack {
                                Toggle(isOn: $rememberMe) {
                                    Text("Se souvenir de moi")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .toggleStyle(CheckboxToggleStyle())

                                Spacer()

                                Button(action: { showForgotPassword = true }) {
                                    Text("Mot de passe oublié?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.appPrimary)
                                }
                            }

                            // Error Message
                            if let errorMessage = authManager.errorMessage {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)

                                    Text(errorMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.leading)

                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Login Button
                            Button(action: performLogin) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 20))
                                        Text("Se connecter")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: canLogin ? [.appPrimary, .appSecondary] : [.gray, .gray.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(
                                    color: canLogin ? Color.appPrimary.opacity(0.3) : .clear,
                                    radius: 15,
                                    x: 0,
                                    y: 8
                                )
                                .scaleEffect(authManager.isLoading ? 0.95 : 1.0)
                            }
                            .disabled(!canLogin || authManager.isLoading)

                            // Divider
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                                .padding(.vertical, 20)

                            // Sign Up Link
                            HStack {
                                Text("Pas encore de compte?")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)

                                Button(action: { showRegistration = true }) {
                                    Text("S'inscrire")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.appPrimary, .appSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                animateGradient = true
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && authManager.isValidEmail(email)
    }

    private func performLogin() {
        Task {
            let success = await authManager.login(email: email, password: password)
            if success {
                print("LoginView: Login successful, isAuthenticated = \(authManager.isAuthenticated)")
                // Force UI update if needed
                await MainActor.run {
                    // This will trigger ContentView to re-evaluate
                    authManager.objectWillChange.send()
                }
            }
        }
    }
}

struct AnimatedLoginBackground: View {
    @Binding var animate: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 1.0),
                    Color(red: 1.0, green: 0.95, blue: 0.98)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()

            // Floating circles
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appPrimary.opacity(0.3),
                                Color.appSecondary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : CGFloat.random(in: -200...200),
                        y: animate ? CGFloat.random(in: -400...400) : CGFloat.random(in: -400...400)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animate
                    )
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5)
                .fill(configuration.isOn ? Color.appPrimary : Color.clear)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(configuration.isOn ? Color.appPrimary : Color.gray.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(configuration.isOn ? 1 : 0)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 50)

                VStack(spacing: 10) {
                    Text("Mot de passe oublié?")
                        .font(.system(size: 28, weight: .bold))

                    Text("Entrez votre email pour réinitialiser votre mot de passe")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.1))
                        )

                    Button(action: {
                        // TODO: Implement password reset
                        dismiss()
                    }) {
                        Text("Réinitialiser")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.appPrimary, .appSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}
