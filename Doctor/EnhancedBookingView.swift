import SwiftUI
import Combine

struct EnhancedBookingView: View {
    let doctor: Doctor
    @Environment(\.dismiss) var dismiss

    @State private var currentStep = 0
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: String?
    @State private var patientInfo = PatientInfo()
    @State private var selectedReason = ""
    @State private var additionalNotes = ""
    @State private var agreedToTerms = false
    @State private var showingConfirmation = false
    @State private var bookingReference = ""

    let bookingSteps = ["Date & Heure", "Informations", "Motif", "Confirmation"]
    let consultationReasons = [
        "Consultation générale",
        "Suivi médical",
        "Urgence non vitale",
        "Renouvellement d'ordonnance",
        "Bilan de santé",
        "Vaccination",
        "Certificat médical",
        "Autre"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        getSpecialtyColor().opacity(0.05),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with progress
                    VStack(spacing: 20) {
                        // Doctor info
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [getSpecialtyColor(), getSpecialtyColor().opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)

                                Text(doctor.name.prefix(2))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(doctor.name)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text(doctor.specialty)
                                    .font(.system(size: 16))
                                    .foregroundColor(getSpecialtyColor())
                            }

                            Spacer()
                        }
                        .padding(.horizontal)

                        // Progress Stepper
                        BookingProgressView(
                            steps: bookingSteps,
                            currentStep: currentStep,
                            color: getSpecialtyColor()
                        )
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea(edges: .top)
                    )

                    // Content based on step
                    ScrollView {
                        VStack(spacing: 30) {
                            switch currentStep {
                            case 0:
                                DateTimeSelectionView(
                                    doctor: doctor,
                                    selectedDate: $selectedDate,
                                    selectedTimeSlot: $selectedTimeSlot,
                                    color: getSpecialtyColor()
                                )
                            case 1:
                                PatientInfoView(
                                    patientInfo: $patientInfo,
                                    color: getSpecialtyColor()
                                )
                            case 2:
                                ConsultationReasonView(
                                    reasons: consultationReasons,
                                    selectedReason: $selectedReason,
                                    additionalNotes: $additionalNotes,
                                    color: getSpecialtyColor()
                                )
                            case 3:
                                BookingSummaryView(
                                    doctor: doctor,
                                    date: selectedDate,
                                    timeSlot: selectedTimeSlot ?? "",
                                    patientInfo: patientInfo,
                                    reason: selectedReason,
                                    notes: additionalNotes,
                                    agreedToTerms: $agreedToTerms,
                                    color: getSpecialtyColor()
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }

                    // Bottom Navigation
                    HStack(spacing: 20) {
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
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                )
                            }
                        }

                        Button(action: nextStep) {
                            HStack {
                                Text(currentStep == bookingSteps.count - 1 ? "Confirmer" : "Suivant")
                                    .fontWeight(.semibold)
                                if currentStep < bookingSteps.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [getSpecialtyColor(), getSpecialtyColor().opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .opacity(canProceed() ? 1 : 0.5)
                            )
                            .cornerRadius(20)
                            .shadow(
                                color: getSpecialtyColor().opacity(0.3),
                                radius: canProceed() ? 10 : 0,
                                x: 0,
                                y: 5
                            )
                        }
                        .disabled(!canProceed())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(
                        Color.white
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Réservation en ligne")
                        .font(.system(size: 18, weight: .semibold))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            BookingConfirmationView(
                doctor: doctor,
                date: selectedDate,
                timeSlot: selectedTimeSlot ?? "",
                bookingReference: bookingReference,
                color: getSpecialtyColor()
            )
        }
    }

    private func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return selectedTimeSlot != nil
        case 1:
            return patientInfo.isValid()
        case 2:
            return !selectedReason.isEmpty
        case 3:
            return agreedToTerms
        default:
            return false
        }
    }

    private func nextStep() {
        if currentStep < bookingSteps.count - 1 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        } else {
            confirmBooking()
        }
    }

    private func previousStep() {
        withAnimation(.spring()) {
            currentStep -= 1
        }
    }

    private func confirmBooking() {
        // Generate booking reference
        bookingReference = "RDV-\(Int.random(in: 100000...999999))"
        showingConfirmation = true
    }

    func getSpecialtyColor() -> Color {
        let colors: [String: Color] = [
            "Médecine Générale": .appSecondary,
            "Cardiologie": .appPrimary,
            "Dermatologie": .appOrange,
            "Pédiatrie": .appPurple,
            "Orthopédie": .appGreen,
            "Gynécologie": .pink,
            "Ophtalmologie": .cyan
        ]
        return colors[doctor.specialty] ?? .appSecondary
    }
}

struct ModernFloatingTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 12))
                    .foregroundColor(.appPrimary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isFocused || !text.isEmpty ? .appPrimary : .gray)

                TextField(placeholder, text: $text, onEditingChanged: { focused in
                    withAnimation(.spring()) {
                        isFocused = focused
                    }
                })
                .font(.system(size: 16))
                .keyboardType(keyboardType)
            }
            .padding(.vertical, text.isEmpty ? 18 : 10)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isFocused || !text.isEmpty ?
                                Color.appPrimary.opacity(0.5) :
                                Color.gray.opacity(0.2),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: isFocused ? Color.appPrimary.opacity(0.1) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .animation(.spring(), value: text)
    }
}

// Patient Info Model
struct PatientInfo {
    var firstName = ""
    var lastName = ""
    var birthDate = Date()
    var gender = "Non spécifié"
    var phone = ""
    var email = ""
    var socialSecurityNumber = ""
    var hasInsurance = true
    var insuranceName = ""

    func isValid() -> Bool {
        return !firstName.isEmpty && !lastName.isEmpty && !phone.isEmpty && !email.isEmpty
    }
}

// Progress View
struct BookingProgressView: View {
    let steps: [String]
    let currentStep: Int
    let color: Color

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
                                        colors: [color, color.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(index == currentStep ? .white : .gray)
                            }
                        }

                        Text(steps[index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(index <= currentStep ? color : .gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(
                                index < currentStep ?
                                color.opacity(0.5) :
                                Color.gray.opacity(0.2)
                            )
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// Date & Time Selection View
struct DateTimeSelectionView: View {
    let doctor: Doctor
    @Binding var selectedDate: Date
    @Binding var selectedTimeSlot: String?
    let color: Color

    @State private var availableSlots: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Calendar
            VStack(alignment: .leading, spacing: 15) {
                Label("Sélectionnez une date", systemImage: "calendar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .accentColor(color)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .onChange(of: selectedDate) { _ in
                    updateAvailableSlots()
                }
            }

            // Time slots
            VStack(alignment: .leading, spacing: 15) {
                Label("Créneaux disponibles", systemImage: "clock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                if availableSlots.isEmpty {
                    Text("Aucun créneau disponible pour cette date")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                        )
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(availableSlots, id: \.self) { slot in
                            TimeSlotButton(
                                time: slot,
                                isSelected: selectedTimeSlot == slot,
                                color: color
                            ) {
                                withAnimation(.spring()) {
                                    selectedTimeSlot = slot
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            updateAvailableSlots()
        }
    }

    private func updateAvailableSlots() {
        // Simuler la récupération des créneaux disponibles
        let baseSlots = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
                        "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"]
        availableSlots = baseSlots.shuffled().prefix(Int.random(in: 4...8)).sorted()
    }
}

struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.white, Color.gray.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color.clear : color.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
    }
}

// Patient Info View
struct PatientInfoView: View {
    @Binding var patientInfo: PatientInfo
    let color: Color

    let genderOptions = ["Homme", "Femme", "Non spécifié"]

    var body: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Informations personnelles", systemImage: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Ces informations sont nécessaires pour votre dossier médical")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    ModernFloatingTextField(
                        placeholder: "Prénom",
                        text: $patientInfo.firstName,
                        icon: "person.fill"
                    )

                    ModernFloatingTextField(
                        placeholder: "Nom",
                        text: $patientInfo.lastName,
                        icon: "person.fill"
                    )
                }

                // Date de naissance
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date de naissance")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    DatePicker(
                        "",
                        selection: $patientInfo.birthDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .accentColor(color)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                            )
                    )
                }

                // Genre
                VStack(alignment: .leading, spacing: 8) {
                    Text("Genre")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        ForEach(genderOptions, id: \.self) { option in
                            GenderOption(
                                title: option,
                                isSelected: patientInfo.gender == option,
                                color: color
                            ) {
                                patientInfo.gender = option
                            }
                        }
                    }
                }

                ModernFloatingTextField(
                    placeholder: "Téléphone",
                    text: $patientInfo.phone,
                    icon: "phone.fill",
                    keyboardType: .phonePad
                )

                ModernFloatingTextField(
                    placeholder: "Email",
                    text: $patientInfo.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )

                ModernFloatingTextField(
                    placeholder: "Numéro de sécurité sociale",
                    text: $patientInfo.socialSecurityNumber,
                    icon: "creditcard.fill",
                    keyboardType: .numberPad
                )

                // Assurance
                VStack(alignment: .leading, spacing: 15) {
                    Toggle(isOn: $patientInfo.hasInsurance) {
                        Label("J'ai une assurance maladie", systemImage: "shield.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .tint(color)

                    if patientInfo.hasInsurance {
                        ModernFloatingTextField(
                            placeholder: "Nom de l'assurance",
                            text: $patientInfo.insuranceName,
                            icon: "building.2.fill"
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.05))
                )
            }
        }
    }
}

struct GenderOption: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isSelected ?
                            color :
                            Color.gray.opacity(0.1)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
    }
}

// Consultation Reason View
struct ConsultationReasonView: View {
    let reasons: [String]
    @Binding var selectedReason: String
    @Binding var additionalNotes: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Motif de consultation", systemImage: "text.bubble.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Sélectionnez le motif principal de votre visite")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // Reasons grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(reasons, id: \.self) { reason in
                    ReasonButton(
                        title: reason,
                        icon: getReasonIcon(for: reason),
                        isSelected: selectedReason == reason,
                        color: color
                    ) {
                        withAnimation(.spring()) {
                            selectedReason = reason
                        }
                    }
                }
            }

            // Additional notes
            VStack(alignment: .leading, spacing: 10) {
                Label("Informations complémentaires", systemImage: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text("Décrivez vos symptômes ou ajoutez des précisions")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                TextEditor(text: $additionalNotes)
                    .font(.system(size: 15))
                    .padding(12)
                    .frame(minHeight: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private func getReasonIcon(for reason: String) -> String {
        let icons: [String: String] = [
            "Consultation générale": "stethoscope",
            "Suivi médical": "chart.line.uptrend.xyaxis",
            "Urgence non vitale": "exclamationmark.triangle",
            "Renouvellement d'ordonnance": "pills.fill",
            "Bilan de santé": "heart.text.square",
            "Vaccination": "syringe.fill",
            "Certificat médical": "doc.text.fill",
            "Autre": "ellipsis.circle"
        ]
        return icons[reason] ?? "questionmark.circle"
    }
}

struct ReasonButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : color)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
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
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.clear : color.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
    }
}

// Booking Summary View
struct BookingSummaryView: View {
    let doctor: Doctor
    let date: Date
    let timeSlot: String
    let patientInfo: PatientInfo
    let reason: String
    let notes: String
    @Binding var agreedToTerms: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 25) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appGreen, Color(red: 0.1, green: 0.7, blue: 0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Récapitulatif de votre rendez-vous")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }

            // Summary cards
            VStack(spacing: 20) {
                // Doctor info
                SummaryCard(
                    icon: "person.crop.circle.fill",
                    title: "Médecin",
                    content: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctor.name)
                                .font(.system(size: 16, weight: .semibold))
                            Text(doctor.specialty)
                                .font(.system(size: 14))
                                .foregroundColor(color)
                            Text(doctor.address)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                )

                // Date & Time
                SummaryCard(
                    icon: "calendar.badge.clock",
                    title: "Date et heure",
                    content: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(Locale(identifier: "fr_FR"))))
                                .font(.system(size: 16, weight: .semibold))
                            Text("à \(timeSlot)")
                                .font(.system(size: 16))
                                .foregroundColor(color)
                        }
                    }
                )

                // Patient
                SummaryCard(
                    icon: "person.fill",
                    title: "Patient",
                    content: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(patientInfo.firstName) \(patientInfo.lastName)")
                                .font(.system(size: 16, weight: .semibold))
                            Text(patientInfo.phone)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text(patientInfo.email)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                )

                // Reason
                SummaryCard(
                    icon: "text.bubble.fill",
                    title: "Motif",
                    content: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(reason)
                                .font(.system(size: 16, weight: .semibold))
                            if !notes.isEmpty {
                                Text(notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                )
            }

            // Terms and conditions
            VStack(spacing: 15) {
                Toggle(isOn: $agreedToTerms) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("J'accepte les conditions")
                            .font(.system(size: 16, weight: .medium))
                        Text("En confirmant, vous acceptez notre politique d'annulation (24h à l'avance)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(color)

                // Important note
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)

                    Text("Vous recevrez un SMS et un email de confirmation avec toutes les informations")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
}

struct SummaryCard<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.appSecondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                content()
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// Booking Confirmation View
struct BookingConfirmationView: View {
    let doctor: Doctor
    let date: Date
    let timeSlot: String
    let bookingReference: String
    let color: Color
    @Environment(\.dismiss) var dismiss

    @State private var animateSuccess = false
    @State private var showCalendarAction = false

    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                ConfettiBackground(color: color)

                VStack(spacing: 30) {
                    // Success animation
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 150, height: 150)
                            .scaleEffect(animateSuccess ? 1.5 : 0.8)
                            .opacity(animateSuccess ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1)
                                .repeatForever(autoreverses: false),
                                value: animateSuccess
                            )

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.appGreen, Color(red: 0.1, green: 0.7, blue: 0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateSuccess ? 1.1 : 0.5)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6),
                                value: animateSuccess
                            )
                    }

                    VStack(spacing: 20) {
                        Text("Rendez-vous confirmé! 🎉")
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Votre réservation a été enregistrée avec succès")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Booking details card
                    VStack(spacing: 20) {
                        // Reference number
                        VStack(spacing: 10) {
                            Text("Numéro de référence")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text(bookingReference)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(color)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(color.opacity(0.1))
                        )

                        // Details
                        VStack(spacing: 15) {
                            DetailRow(icon: "person.crop.circle.fill", text: doctor.name, color: color)
                            DetailRow(icon: "calendar", text: date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "fr_FR"))), color: color)
                            DetailRow(icon: "clock.fill", text: timeSlot, color: color)
                            DetailRow(icon: "location.fill", text: doctor.address, color: color)
                        }
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)

                    // Action buttons
                    VStack(spacing: 15) {
                        Button(action: addToCalendar) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 18))
                                Text("Ajouter au calendrier")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                        }

                        Button(action: { dismiss() }) {
                            Text("Fermer")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(color, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear {
                animateSuccess = true
            }
        }
    }

    private func addToCalendar() {
        // Ici, vous pourriez implémenter l'ajout au calendrier
        showCalendarAction = true
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 25)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

struct ConfettiBackground: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [color.opacity(0.05), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated circles
            ForEach(0..<30) { index in
                Circle()
                    .fill(
                        [color, .appGreen, .orange, .blue, .purple]
                            .randomElement()!
                            .opacity(0.7)
                    )
                    .frame(
                        width: CGFloat.random(in: 10...30),
                        height: CGFloat.random(in: 10...30)
                    )
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? UIScreen.main.bounds.height + 100 : -100
                    )
                    .animation(
                        .linear(duration: Double.random(in: 5...10))
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
