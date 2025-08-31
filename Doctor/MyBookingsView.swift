import SwiftUI

struct MyBookingsView: View {
    @StateObject private var viewModel = BookingsViewModel()
    @State private var selectedTab = 0

    var upcomingBookings: [Reservation] {
        viewModel.bookings.filter { $0.status != "completed" && $0.status != "cancelled" }
    }

    var pastBookings: [Reservation] {
        viewModel.bookings.filter { $0.status == "completed" || $0.status == "cancelled" }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("", selection: $selectedTab) {
                    Text("À venir").tag(0)
                    Text("Passées").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                    Spacer()
                } else {
                    List {
                        if selectedTab == 0 {
                            if upcomingBookings.isEmpty {
                                EmptyBookingsView(isUpcoming: true)
                                    .listRowSeparator(.hidden)
                            } else {
                                ForEach(upcomingBookings) { booking in
                                    BookingRowView(booking: booking)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        } else {
                            if pastBookings.isEmpty {
                                EmptyBookingsView(isUpcoming: false)
                                    .listRowSeparator(.hidden)
                            } else {
                                ForEach(pastBookings) { booking in
                                    BookingRowView(booking: booking)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Mes Réservations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.loadBookings() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadBookings()
                }
            }
        }
    }
}

struct BookingRowView: View {
    let booking: Reservation
    @State private var showingQRCode = false

    var statusColor: Color {
        switch booking.status {
        case "confirmed":
            return .appGreen
        case "pending":
            return .orange
        case "cancelled":
            return .red
        case "completed":
            return .gray
        default:
            return .gray
        }
    }

    var statusText: String {
        switch booking.status {
        case "confirmed":
            return "Confirmé"
        case "pending":
            return "En attente"
        case "cancelled":
            return "Annulé"
        case "completed":
            return "Terminé"
        default:
            return booking.status ?? "Inconnu"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Dr. [Nom du médecin]") // Would need doctor info from API
                        .font(.system(size: 16, weight: .semibold))

                    Text(booking.serviceType.capitalized)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(15)
            }

            Divider()

            HStack(spacing: 20) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(formatDate(booking.appointmentDate))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(booking.appointmentTime)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            if let confirmationCode = booking.confirmationCode {
                Button(action: { showingQRCode = true }) {
                    HStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: 14))
                        Text("Voir QR Code")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.appPrimary)
                }
                .sheet(isPresented: $showingQRCode) {
                    QRCodeView(booking: booking, confirmationCode: confirmationCode)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 5)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct EmptyBookingsView: View {
    let isUpcoming: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isUpcoming ? "calendar.badge.exclamationmark" : "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(isUpcoming ? "Aucune réservation à venir" : "Aucune réservation passée")
                .font(.headline)
                .foregroundColor(.gray)

            if isUpcoming {
                Text("Vos prochaines réservations apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

struct QRCodeView: View {
    let booking: Reservation
    let confirmationCode: String
    @Environment(\.dismiss) var dismiss

    var qrCodeData: String {
        let data = QRCodeData(
            doctorId: booking.doctorId,
            appointmentDate: booking.appointmentDate,
            appointmentTime: booking.appointmentTime,
            code: confirmationCode
        )

        if let jsonData = try? JSONEncoder().encode(data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return ""
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Code QR de Réservation")
                    .font(.title2)
                    .fontWeight(.bold)

                // QR Code would be generated here
                Image(systemName: "qrcode")
                    .font(.system(size: 200))
                    .foregroundColor(.black)

                VStack(spacing: 10) {
                    Text("Code de confirmation:")
                        .font(.headline)
                    Text(confirmationCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.appPrimary)
                }

                Text("Présentez ce code lors de votre arrivée")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
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

class BookingsViewModel: ObservableObject {
    @Published var bookings: [Reservation] = []
    @Published var isLoading = false

    private let apiService = APIService.shared

    @MainActor
    func loadBookings() async {
        isLoading = true

        do {
            bookings = try await apiService.getMyReservations()
        } catch {
            // Load mock data as fallback
            loadMockBookings()
        }

        isLoading = false
    }

    private func loadMockBookings() {
        bookings = [
            Reservation(
                id: "1",
                doctorId: "doc1",
                appointmentDate: "2024-01-25",
                appointmentTime: "10:00",
                serviceType: "consultation",
                notes: nil,
                status: "confirmed",
                confirmationCode: "ABC123"
            ),
            Reservation(
                id: "2",
                doctorId: "doc2",
                appointmentDate: "2024-01-20",
                appointmentTime: "14:30",
                serviceType: "consultation",
                notes: nil,
                status: "completed",
                confirmationCode: "XYZ789"
            )
        ]
    }
}
