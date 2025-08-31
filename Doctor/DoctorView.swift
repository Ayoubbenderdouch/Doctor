
import SwiftUI
import CoreLocation

struct DoctorView: View {
    @State private var selectedSpecialty = "Tous"
    @State private var selectedDoctor: Doctor?
    @State private var showingBookingSheet = false
    @State private var showingMapView = false
    @State private var animateGradient = false

    let specialties = ["Tous", "Médecine Générale", "Cardiologie", "Dermatologie", "Pédiatrie", "Orthopédie", "Gynécologie", "Ophtalmologie"]

    let specialtyIcons: [String: String] = [
        "Médecine Générale": "stethoscope",
        "Cardiologie": "heart.fill",
        "Dermatologie": "face.smiling",
        "Pédiatrie": "figure.2.and.child.holdinghands",
        "Orthopédie": "figure.walk",
        "Gynécologie": "person.fill",
        "Ophtalmologie": "eye.fill"
    ]

    let specialtyColors: [String: Color] = [
        "Médecine Générale": .appSecondary,
        "Cardiologie": .appPrimary,
        "Dermatologie": .appOrange,
        "Pédiatrie": .appPurple,
        "Orthopédie": .appGreen,
        "Gynécologie": .pink,
        "Ophtalmologie": .cyan
    ]

    @State private var doctors: [Doctor] = []

    var filteredDoctors: [Doctor] {
        if selectedSpecialty == "Tous" {
            return doctors
        } else {
            return doctors.filter { $0.specialty == selectedSpecialty }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.appSecondary.opacity(0.05),
                        Color.appPurple.opacity(0.05)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient = true
                    }
                }

                VStack(spacing: 0) {
                    // Modern Header
                    VStack(spacing: 25) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Trouvez votre")
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                Text("Médecin")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.appSecondary, .appPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Modern Specialty Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(specialties, id: \.self) { specialty in
                                    ModernSpecialtyChip(
                                        specialty: specialty,
                                        isSelected: selectedSpecialty == specialty,
                                        icon: specialtyIcons[specialty] ?? "stethoscope",
                                        color: specialtyColors[specialty] ?? .appSecondary
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedSpecialty = specialty
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea(edges: .top)
                            .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
                    )

                    // Doctor Cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            ForEach(Array(filteredDoctors.enumerated()), id: \.element.id) { index, doctor in
                                ModernDoctorCard(
                                    doctor: doctor,
                                    color: specialtyColors[doctor.specialty] ?? .appSecondary,
                                    delay: Double(index) * 0.1,
                                    onBookTap: {
                                        withAnimation(.spring()) {
                                            selectedDoctor = doctor
                                            showingBookingSheet = true
                                        }
                                    },
                                    onCardTap: {
                                        withAnimation(.spring()) {
                                            selectedDoctor = doctor
                                            showingBookingSheet = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingBookingSheet) {
                if let doctor = selectedDoctor {
                    ModernBookingView(doctor: doctor)
                }
            }
            .onAppear {
                loadMockDoctors()
            }
        }
    }

    private func loadMockDoctors() {
        doctors = [
            Doctor(
                id: "1",
                name: "Dr. Ahmed Benali",
                specialty: "Médecine Générale",
                address: "Centre Medical Bab El Oued",
                city: "Alger",
                phoneNumber: "+213 555 1111",
                latitude: 36.7750,
                longitude: 3.0550,
                availableSlots: generateSampleSlots(),
                rating: 4.5,
                yearsOfExperience: 10
            ),
            Doctor(
                id: "2",
                name: "Dr. Fatima Khelifi",
                specialty: "Cardiologie",
                address: "Hôpital Mustapha Pacha",
                city: "Alger",
                phoneNumber: "+213 555 2222",
                latitude: 36.7700,
                longitude: 3.0600,
                availableSlots: generateSampleSlots(),
                rating: 4.8,
                yearsOfExperience: 15
            ),
            Doctor(
                id: "3",
                name: "Dr. Karim Meziane",
                specialty: "Dermatologie",
                address: "Clinique El Azhar",
                city: "Alger",
                phoneNumber: "+213 555 3333",
                latitude: 36.7650,
                longitude: 3.0650,
                availableSlots: generateSampleSlots(),
                rating: 4.3,
                yearsOfExperience: 8
            ),
            Doctor(
                id: "4",
                name: "Dr. Sara Boumaza",
                specialty: "Pédiatrie",
                address: "Clinique des Enfants",
                city: "Alger",
                phoneNumber: "+213 555 4444",
                latitude: 36.7600,
                longitude: 3.0700,
                availableSlots: generateSampleSlots(),
                rating: 4.9,
                yearsOfExperience: 12
            ),
            Doctor(
                id: "5",
                name: "Dr. Yacine Hamidi",
                specialty: "Orthopédie",
                address: "Centre Orthopédique",
                city: "Alger",
                phoneNumber: "+213 555 5555",
                latitude: 36.7680,
                longitude: 3.0620,
                availableSlots: generateSampleSlots(),
                rating: 4.6,
                yearsOfExperience: 20
            ),
            Doctor(
                id: "6",
                name: "Dr. Amina Benslimane",
                specialty: "Gynécologie",
                address: "Clinique Mère et Enfant",
                city: "Alger",
                phoneNumber: "+213 555 6666",
                latitude: 36.7720,
                longitude: 3.0640,
                availableSlots: generateSampleSlots(),
                rating: 4.7,
                yearsOfExperience: 18
            )
        ]
    }
}

// Hilfsfunktion für Sample Slots
func generateSampleSlots() -> [AppointmentSlot] {
    var slots: [AppointmentSlot] = []
    let times = ["09:00", "09:30", "10:00", "10:30", "11:00", "14:00", "14:30", "15:00", "15:30", "16:00"]

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    for dayOffset in 1...7 {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
        let dateString = dateFormatter.string(from: date)

        for time in times.shuffled().prefix(Int.random(in: 3...6)) {
            slots.append(AppointmentSlot(
                id: UUID().uuidString,
                date: dateString,
                time: time,
                isBooked: Bool.random()
            ))
        }
    }

    return slots
}

struct ModernSpecialtyChip: View {
    let specialty: String
    let isSelected: Bool
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color.gray.opacity(0.1))
                        .frame(width: 55, height: 55)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .gray)
                }

                Text(specialty)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? color : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 80)
        }
    }
}

struct ModernDoctorCard: View {
    let doctor: Doctor
    let color: Color
    let delay: Double
    let onBookTap: () -> Void
    let onCardTap: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 20) {
            // Doctor Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(doctor.name.prefix(2))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(doctor.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text(doctor.specialty)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                    .fontWeight(.medium)

                Text(doctor.address)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 15) {
                    if let slots = doctor.availableSlots {
                        Text("\(slots.filter { !$0.isBooked }.count) créneaux")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appGreen)
                    }

                    Button(action: onBookTap) {
                        Text("Réserver")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(color)
                            .cornerRadius(15)
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .onAppear {
            withAnimation(.spring().delay(delay)) {
                isVisible = true
            }
        }
        .onTapGesture {
            onCardTap()
        }
    }
}

struct ModernBookingView: View {
    let doctor: Doctor
    @State private var selectedSlot: AppointmentSlot?
    @State private var patientName = ""
    @State private var patientPhone = ""
    @State private var showingConfirmation = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Doctor info
                    VStack(spacing: 15) {
                        Text(doctor.name)
                            .font(.system(size: 26, weight: .bold))
                        Text(doctor.specialty)
                            .font(.system(size: 18))
                            .foregroundColor(.appPrimary)
                    }
                    .padding(.top, 30)

                    // Patient form
                    VStack(spacing: 20) {
                        TextField("Nom complet", text: $patientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Téléphone", text: $patientPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    .padding(.horizontal)

                    // Available slots
                    if let slots = doctor.availableSlots {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Créneaux disponibles")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.vertical) {
                                VStack(spacing: 10) {
                                    ForEach(slots.filter { !$0.isBooked }, id: \.id) { slot in
                                        HStack {
                                            Text(slot.date)
                                            Text(slot.time)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedSlot?.id == slot.id ? Color.appPrimary : Color.gray.opacity(0.1))
                                        )
                                        .foregroundColor(selectedSlot?.id == slot.id ? .white : .primary)
                                        .onTapGesture {
                                            selectedSlot = slot
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Book button
                    Button(action: bookAppointment) {
                        Text("Confirmer le rendez-vous")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appPrimary)
                            .cornerRadius(20)
                            .opacity(canBook ? 1 : 0.5)
                    }
                    .disabled(!canBook)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Réservation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert("Rendez-vous confirmé!", isPresented: $showingConfirmation) {
                Button("OK") { dismiss() }
            }
        }
    }

    var canBook: Bool {
        selectedSlot != nil && !patientName.isEmpty && !patientPhone.isEmpty
    }

    private func bookAppointment() {
        showingConfirmation = true
    }
}
