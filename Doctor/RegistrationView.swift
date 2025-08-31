import SwiftUI

struct RegistrationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) var dismiss

    // Form fields with default values for testing
    @State private var email = "ayoub@myseha.dz"
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = "Ayoub Benderdouch"
    @State private var phone = ""
    @State private var selectedRegion = AlgerianRegion.algiers
    @State private var age = ""
    @State private var selectedBloodType = BloodType.aPositive

    // UI States
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var currentStep = 0
    @State private var animateElements = false
    @State private var agreedToTerms = false
    @State private var showSuccessAnimation = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword, fullName, phone, age
    }

    let registrationSteps = ["Compte", "Informations", "Médical", "Confirmation"]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(0.05),
                        Color.appSecondary.opacity(0.05),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with Progress
                    VStack(spacing: 20) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)

                        // Title
                        VStack(spacing: 8) {
                            Text("Créer un compte")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.appPrimary, .appSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Rejoignez notre communauté médicale")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }

                        // Progress Indicator
                        RegistrationProgressView(
                            steps: registrationSteps,
                            currentStep: currentStep
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(
                        Color.white
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )

                    // Form Content
                    ScrollView {
                        VStack(spacing: 30) {
                            switch currentStep {
                            case 0:
                                AccountStepView(
                                    email: $email,
                                    password: $password,
                                    confirmPassword: $confirmPassword,
                                    showPassword: $showPassword,
                                    showConfirmPassword: $showConfirmPassword,
                                    focusedField: $focusedField,
                                    authManager: authManager
                                )
                            case 1:
                                PersonalInfoStepView(
                                    fullName: $fullName,
                                    phone: $phone,
                                    selectedRegion: $selectedRegion,
                                    age: $age,
                                    focusedField: $focusedField
                                )
                            case 2:
                                MedicalInfoStepView(
                                    selectedBloodType: $selectedBloodType
                                )
                            case 3:
                                ConfirmationStepView(
                                    email: email,
                                    fullName: fullName,
                                    phone: phone,
                                    region: selectedRegion.displayName,
                                    age: age,
                                    bloodType: selectedBloodType.displayName,
                                    agreedToTerms: $agreedToTerms
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }

                    // Navigation Buttons
                    VStack(spacing: 15) {
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            ErrorMessageView(message: errorMessage)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        HStack(spacing: 15) {
                            if currentStep > 0 {
                                Button(action: previousStep) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Précédent")
                                    }
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                }
                            }

                            Button(action: nextStep) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(currentStep == registrationSteps.count - 1 ? "S'inscrire" : "Suivant")
                                            .fontWeight(.semibold)
                                        if currentStep < registrationSteps.count - 1 {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: canProceed() ? [.appPrimary, .appSecondary] : [.gray, .gray.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(
                                    color: canProceed() ? Color.appPrimary.opacity(0.3) : .clear,
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                            }
                            .disabled(!canProceed() || authManager.isLoading)
                        }
                    }
                    .padding()
                    .background(
                        Color.white
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                    )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                animateElements = true
            }

            // Success Overlay
            if showSuccessAnimation {
                SuccessAnimationView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return authManager.isValidEmail(email) &&
                   authManager.isValidPassword(password) &&
                   password == confirmPassword
        case 1:
            return !fullName.isEmpty &&
                   authManager.isValidPhoneNumber(phone) &&
                   !age.isEmpty &&
                   Int(age) != nil &&
                   (Int(age) ?? 0) > 0 &&
                   (Int(age) ?? 0) < 150
        case 2:
            return true // Blood type is always selected
        case 3:
            return agreedToTerms
        default:
            return false
        }
    }

    private func nextStep() {
        if currentStep < registrationSteps.count - 1 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        } else {
            performRegistration()
        }
    }

    private func previousStep() {
        withAnimation(.spring()) {
            currentStep -= 1
        }
    }

    private func performRegistration() {
        Task {
            let success = await authManager.register(
                email: email,
                password: password,
                fullName: fullName,
                phone: phone,
                region: selectedRegion.rawValue,
                age: Int(age) ?? 0,
                bloodType: selectedBloodType.rawValue
            )

            if success {
                withAnimation(.spring()) {
                    showSuccessAnimation = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Step Views

struct AccountStepView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var showPassword: Bool
    @Binding var showConfirmPassword: Bool
    var focusedField: FocusState<RegistrationView.Field?>.Binding
    let authManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 25) {
            // Email Field
            FormField(
                title: "Adresse Email",
                icon: "envelope.fill",
                placeholder: "john.doe@example.com",
                text: $email,
                keyboardType: .emailAddress,
                focused: focusedField,
                field: .email
            )

            if !email.isEmpty && !authManager.isValidEmail(email) {
                ValidationMessage(
                    message: "Format d'email invalide",
                    isValid: false
                )
            }

            // Password Field
            SecureFormField(
                title: "Mot de passe",
                icon: "lock.fill",
                placeholder: "Minimum 8 caractères",
                text: $password,
                showText: $showPassword,
                focused: focusedField,
                field: .password
            )

            if !password.isEmpty {
                PasswordStrengthIndicator(
                    password: password,
                    authManager: authManager
                )
            }

            // Confirm Password Field
            SecureFormField(
                title: "Confirmer le mot de passe",
                icon: "lock.rotation",
                placeholder: "Retapez votre mot de passe",
                text: $confirmPassword,
                showText: $showConfirmPassword,
                focused: focusedField,
                field: .confirmPassword
            )

            if !confirmPassword.isEmpty && password != confirmPassword {
                ValidationMessage(
                    message: "Les mots de passe ne correspondent pas",
                    isValid: false
                )
            }
        }
    }
}

struct PersonalInfoStepView: View {
    @Binding var fullName: String
    @Binding var phone: String
    @Binding var selectedRegion: AlgerianRegion
    @Binding var age: String
    var focusedField: FocusState<RegistrationView.Field?>.Binding

    var body: some View {
        VStack(spacing: 25) {
            // Full Name
            FormField(
                title: "Nom complet",
                icon: "person.fill",
                placeholder: "John Doe",
                text: $fullName,
                keyboardType: .default,
                focused: focusedField,
                field: .fullName
            )

            // Phone Number
            FormField(
                title: "Numéro de téléphone",
                icon: "phone.fill",
                placeholder: "+213 555 123 456",
                text: $phone,
                keyboardType: .phonePad,
                focused: focusedField,
                field: .phone
            )

            // Region Picker
            VStack(alignment: .leading, spacing: 10) {
                Label("Région", systemImage: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(AlgerianRegion.allCases, id: \.self) { region in
                        Button(action: { selectedRegion = region }) {
                            HStack {
                                Text(region.displayName)
                                if selectedRegion == region {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)

                        Text(selectedRegion.displayName)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                            )
                    )
                }
            }

            // Age Field
            FormField(
                title: "Âge",
                icon: "calendar",
                placeholder: "30",
                text: $age,
                keyboardType: .numberPad,
                focused: focusedField,
                field: .age
            )
        }
    }
}

struct MedicalInfoStepView: View {
    @Binding var selectedBloodType: BloodType

    var body: some View {
        VStack(spacing: 25) {
            // Info Card
            HStack(spacing: 15) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Informations médicales")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Ces informations peuvent être utiles en cas d'urgence")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.1))
            )

            // Blood Type Selection
            VStack(alignment: .leading, spacing: 15) {
                Label("Groupe sanguin", systemImage: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                    ForEach(BloodType.allCases, id: \.self) { bloodType in
                        BloodTypeButton(
                            bloodType: bloodType,
                            isSelected: selectedBloodType == bloodType
                        ) {
                            withAnimation(.spring()) {
                                selectedBloodType = bloodType
                            }
                        }
                    }
                }
            }

            // Medical History Note
            VStack(alignment: .leading, spacing: 10) {
                Label("Note", systemImage: "doc.text")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Text("Vous pourrez ajouter plus d'informations médicales dans votre profil après l'inscription")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.05))
                    )
            }
        }
    }
}

struct ConfirmationStepView: View {
    let email: String
    let fullName: String
    let phone: String
    let region: String
    let age: String
    let bloodType: String
    @Binding var agreedToTerms: Bool

    var body: some View {
        VStack(spacing: 25) {
            // Summary Header
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appGreen, Color(red: 0.1, green: 0.8, blue: 0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Vérifiez vos informations")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }

            // Information Summary
            VStack(spacing: 20) {
                SummaryRow(icon: "envelope.fill", label: "Email", value: email)
                SummaryRow(icon: "person.fill", label: "Nom", value: fullName)
                SummaryRow(icon: "phone.fill", label: "Téléphone", value: phone)
                SummaryRow(icon: "location.fill", label: "Région", value: region)
                SummaryRow(icon: "calendar", label: "Âge", value: "\(age) ans")
                SummaryRow(icon: "drop.fill", label: "Groupe sanguin", value: bloodType)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )

            // Terms and Conditions
            VStack(spacing: 15) {
                Toggle(isOn: $agreedToTerms) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("J'accepte les conditions")
                            .font(.system(size: 16, weight: .medium))

                        HStack(spacing: 5) {
                            Text("J'ai lu et j'accepte les")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Button(action: {}) {
                                Text("conditions d'utilisation")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appPrimary)
                                    .underline()
                            }

                            Text("et la")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Button(action: {}) {
                                Text("politique de confidentialité")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appPrimary)
                                    .underline()
                            }
                        }
                    }
                }
                .tint(.appPrimary)
            }
        }
    }
}

// MARK: - Supporting Views

struct RegistrationProgressView: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    index <= currentStep ?
                                    LinearGradient(
                                        colors: [.appPrimary, .appSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 35, height: 35)

                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(index == currentStep ? .white : .gray)
                            }
                        }

                        Text(steps[index])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(index <= currentStep ? .appPrimary : .gray)
                            .lineLimit(1)
                    }

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(
                                index < currentStep ?
                                Color.appPrimary.opacity(0.5) :
                                Color.gray.opacity(0.2)
                            )
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

struct FormField: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    var focused: FocusState<RegistrationView.Field?>.Binding
    let field: RegistrationView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(focused.wrappedValue == field ? .appPrimary : .gray)

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .focused(focused, equals: field)

                if !text.isEmpty {
                    Button(action: { text = "" }) {
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
                                focused.wrappedValue == field ? Color.appPrimary : Color.gray.opacity(0.2),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: focused.wrappedValue == field ? Color.appPrimary.opacity(0.1) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
    }
}

struct SecureFormField: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showText: Bool
    var focused: FocusState<RegistrationView.Field?>.Binding
    let field: RegistrationView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(focused.wrappedValue == field ? .appPrimary : .gray)

                if showText {
                    TextField(placeholder, text: $text)
                        .focused(focused, equals: field)
                } else {
                    SecureField(placeholder, text: $text)
                        .focused(focused, equals: field)
                }

                Button(action: { showText.toggle() }) {
                    Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
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
                                focused.wrappedValue == field ? Color.appPrimary : Color.gray.opacity(0.2),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: focused.wrappedValue == field ? Color.appPrimary.opacity(0.1) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
    }
}

struct PasswordStrengthIndicator: View {
    let password: String
    let authManager: AuthenticationManager

    var body: some View {
        let strength = authManager.getPasswordStrength(password)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Force du mot de passe:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(strength.strength)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(strength.color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.progress, height: 6)
                        .animation(.spring(), value: strength.progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct BloodTypeButton: View {
    let bloodType: BloodType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .red)

                Text(bloodType.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isSelected ? Color.clear : Color.red.opacity(0.3),
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? Color.red.opacity(0.3) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.appPrimary)
                .frame(width: 25)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

struct ValidationMessage: View {
    let message: String
    let isValid: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(isValid ? .green : .red)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(isValid ? .green : .red)

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)

            Text(message)
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
        .padding(.horizontal)
    }
}

struct SuccessAnimationView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .fill(Color.appGreen.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .scaleEffect(animate ? 1.5 : 0.8)
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.appGreen, Color(red: 0.1, green: 0.8, blue: 0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animate ? 1.1 : 0.5)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6),
                            value: animate
                        )
                }

                VStack(spacing: 10) {
                    Text("Inscription réussie!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Bienvenue dans notre communauté")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
            )
            .shadow(radius: 30)
            .scaleEffect(animate ? 1 : 0.8)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    RegistrationView()
}
