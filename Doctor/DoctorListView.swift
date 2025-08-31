import SwiftUI
import MapKit

struct DoctorListView: View {
    @StateObject private var viewModel = DoctorViewModel() // Name geändert
    @EnvironmentObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var selectedSpecialty = "Tous"
    @State private var showingMap = false

    let specialties = ["Tous", "Médecine Générale", "Cardiologie", "Dermatologie",
                      "Pédiatrie", "Orthopédie", "Gynécologie", "Ophtalmologie"]

    var filteredDoctors: [Doctor] {
        var doctors = viewModel.doctors

        if selectedSpecialty != "Tous" {
            doctors = doctors.filter { $0.specialty == selectedSpecialty }
        }

        if !searchText.isEmpty {
            doctors = doctors.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.specialty.localizedCaseInsensitiveContains(searchText) ||
                $0.city.localizedCaseInsensitiveContains(searchText)
            }
        }

        return doctors
    }

    var doctorsByCity: [String: [Doctor]] {
        Dictionary(grouping: filteredDoctors, by: { $0.city })
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Rechercher un médecin...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()

                    // Specialty Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(specialties, id: \.self) { specialty in
                                SpecialtyChip(
                                    title: specialty,
                                    isSelected: selectedSpecialty == specialty
                                ) {
                                    selectedSpecialty = specialty
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)

                    // Doctors List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Chargement des médecins...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        Spacer()
                    } else if filteredDoctors.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "stethoscope")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Aucun médecin trouvé")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(doctorsByCity.keys.sorted(), id: \.self) { city in
                                Section(header: Text(city).font(.headline)) {
                                    ForEach(doctorsByCity[city] ?? []) { doctor in
                                        NavigationLink(destination: DoctorDetailView(doctor: doctor)) {
                                            DoctorRowView(doctor: doctor)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("Médecins")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.loadDoctors() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadDoctors()
                }
            }
        }
    }
}

// ViewModel mit korrigiertem Namen
class DoctorViewModel: ObservableObject {
    @Published var doctors: [Doctor] = []
    @Published var isLoading = false

    private let apiService = APIService.shared
    private let locationManager = LocationManager.shared

    @MainActor
    func loadDoctors() async {
        isLoading = true

        do {
            let latitude = locationManager.currentCoordinate?.latitude ?? 36.7538
            let longitude = locationManager.currentCoordinate?.longitude ?? 3.0588

            doctors = try await apiService.fetchNearbyDoctors(
                latitude: latitude,
                longitude: longitude,
                radius: 10
            )
        } catch {
            // Load mock data as fallback
            loadMockDoctors()
        }

        isLoading = false
    }

    private func loadMockDoctors() {
        doctors = [
            Doctor(
                id: "1",
                name: "Dr. Ahmed Benali",
                specialty: "Médecine Générale",
                address: "123 Rue Didouche Mourad",
                city: "Alger", // city hinzugefügt
                phoneNumber: "+213 555 0101",
                latitude: 36.7538,
                longitude: 3.0588,
                availableSlots: [
                    AppointmentSlot(id: "1", date: "2024-01-20", time: "09:00", isBooked: false),
                    AppointmentSlot(id: "2", date: "2024-01-20", time: "10:00", isBooked: false)
                ],
                rating: 4.5,
                yearsOfExperience: 10
            ),
            Doctor(
                id: "2",
                name: "Dr. Fatima Khelifi",
                specialty: "Cardiologie",
                address: "456 Boulevard des Martyrs",
                city: "Oran", // city hinzugefügt
                phoneNumber: "+213 555 0202",
                latitude: 35.6969,
                longitude: -0.6331,
                availableSlots: [
                    AppointmentSlot(id: "3", date: "2024-01-21", time: "14:00", isBooked: false)
                ],
                rating: 4.8,
                yearsOfExperience: 15
            )
        ]
    }
}

// Rest der View-Komponenten bleiben gleich...
struct DoctorRowView: View {
    let doctor: Doctor

    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(LinearGradient(
                    colors: [.appPrimary, .appSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(doctor.name.prefix(2).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(doctor.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(doctor.specialty)
                    .font(.system(size: 14))
                    .foregroundColor(.appPrimary)

                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(doctor.city)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct SpecialtyChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.gray.opacity(0.1))
                )
        }
    }
}
