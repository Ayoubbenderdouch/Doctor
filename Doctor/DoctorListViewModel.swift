import SwiftUI
import MapKit

struct DoctorDetailView: View {
    let doctor: Doctor
    @State private var selectedSlot: AppointmentSlot?
    @State private var notes = ""
    @State private var showingBookingConfirmation = false
    @State private var isBooking = false
    @StateObject private var viewModel = BookingViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Doctor Header
                DoctorHeaderView(doctor: doctor)

                // Contact Info
                ContactInfoCard(doctor: doctor)

                // Map
                MapSnapshotView(coordinate: doctor.coordinate)
                    .frame(height: 200)
                    .cornerRadius(15)
                    .padding(.horizontal)

                // Available Slots
                if let slots = doctor.availableSlots {
                    AvailableSlotsView(
                        slots: slots,
                        selectedSlot: $selectedSlot
                    )
                }

                // Notes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes (optionnel)")
                        .font(.headline)
                        .padding(.horizontal)

                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                // Book Button
                Button(action: bookAppointment) {
                    if isBooking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Réserver")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: selectedSlot != nil ? [.appPrimary, .appSecondary] : [.gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .padding(.horizontal)
                .disabled(selectedSlot == nil || isBooking)

                Spacer(minLength: 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Réservation confirmée", isPresented: $showingBookingConfirmation) {
            Button("OK") { }
        } message: {
            Text("Votre rendez-vous a été confirmé. Vous recevrez un SMS de confirmation.")
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private func bookAppointment() {
        guard let slot = selectedSlot else { return }

        Task {
            isBooking = true
            let success = await viewModel.bookAppointment(
                doctorId: doctor.id,
                date: slot.date,
                time: slot.time,
                notes: notes
            )
            isBooking = false

            if success {
                showingBookingConfirmation = true
                selectedSlot = nil
                notes = ""
            }
        }
    }
}

struct DoctorHeaderView: View {
    let doctor: Doctor

    var body: some View {
        VStack(spacing: 15) {
            Circle()
                .fill(LinearGradient(
                    colors: [.appPrimary, .appSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(doctor.name.prefix(2).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(doctor.name)
                .font(.system(size: 24, weight: .bold))

            Text(doctor.specialty)
                .font(.system(size: 18))
                .foregroundColor(.appPrimary)

            if let rating = doctor.rating {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(rating) ? "star.fill" : "star")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }

            if let years = doctor.yearsOfExperience {
                Text("\(years) ans d'expérience")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

struct ContactInfoCard: View {
    let doctor: Doctor

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.appPrimary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Téléphone")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(doctor.phoneNumber)
                        .font(.system(size: 16))
                }

                Spacer()

                Button(action: { callDoctor() }) {
                    Text("Appeler")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.appGreen)
                        .cornerRadius(20)
                }
            }

            Divider()

            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.appPrimary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Adresse")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(doctor.address)
                        .font(.system(size: 16))
                    Text(doctor.city)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func callDoctor() {
        if let url = URL(string: "tel://\(doctor.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
}

struct AvailableSlotsView: View {
    let slots: [AppointmentSlot]
    @Binding var selectedSlot: AppointmentSlot?

    var availableSlots: [AppointmentSlot] {
        slots.filter { !$0.isBooked }
    }

    var slotsByDate: [String: [AppointmentSlot]] {
        Dictionary(grouping: availableSlots, by: { $0.date })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Créneaux disponibles")
                .font(.headline)
                .padding(.horizontal)

            if availableSlots.isEmpty {
                Text("Aucun créneau disponible")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 15) {
                        ForEach(slotsByDate.keys.sorted(), id: \.self) { date in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(formatDate(date))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(slotsByDate[date] ?? []) { slot in
                                            TimeSlotButton(
                                                slot: slot,
                                                isSelected: selectedSlot?.id == slot.id
                                            ) {
                                                selectedSlot = slot
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }
}

struct TimeSlotButton: View {
    let slot: AppointmentSlot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(slot.time)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.gray.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct MapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self._region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: coordinate)]) { pin in
            MapMarker(coordinate: pin.coordinate, tint: .appPrimary)
        }
        .disabled(true)
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Booking ViewModel
class BookingViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var showError = false

    private let apiService = APIService.shared

    @MainActor
    func bookAppointment(doctorId: String, date: String, time: String, notes: String) async -> Bool {
        do {
            let request = ReservationRequest(
                doctorId: doctorId,
                appointmentDate: date,  // date ist bereits ein String
                appointmentTime: time,
                serviceType: "consultation",
                notes: notes.isEmpty ? "Pas de notes" : notes
            )

            _ = try await apiService.createReservation(request)
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
}
