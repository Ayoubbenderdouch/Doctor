
import SwiftUI
import MapKit

struct PharmacyListView: View {
    @StateObject private var viewModel = PharmacyListViewModel()
    @EnvironmentObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var showOnly24h = false
    @State private var selectedRegion = "Alger"
    @State private var showingMap = false

    let regions = ["Alger", "Oran", "Constantine", "Annaba", "Blida", "Batna"]

    var filteredPharmacies: [Pharmacy] {
        var pharmacies = viewModel.pharmacies

        if showOnly24h {
            pharmacies = pharmacies.filter { $0.isOpen24Hours }
        }

        if !searchText.isEmpty {
            pharmacies = pharmacies.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }

        return pharmacies
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Rechercher une pharmacie...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()

                // Filters
                VStack(spacing: 10) {
                    // Region Picker
                    HStack {
                        Text("Région:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Picker("Région", selection: $selectedRegion) {
                            ForEach(regions, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(.appPrimary)

                        Spacer()

                        // 24h Toggle
                        Toggle(isOn: $showOnly24h) {
                            Label("24h/24", systemImage: "moon.fill")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    }
                    .padding(.horizontal)
                }

                // Pharmacies List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement des pharmacies...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .appGreen))
                    Spacer()
                } else if filteredPharmacies.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "cross.vial")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Aucune pharmacie trouvée")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List(filteredPharmacies) { pharmacy in
                        PharmacyRowView(pharmacy: pharmacy)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Pharmacies")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMap = true }) {
                        Image(systemName: "map")
                            .foregroundColor(.appGreen)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.loadPharmacies() } }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.appGreen)
                    }
                }
            }
            .sheet(isPresented: $showingMap) {
                PharmacyMapView(pharmacies: filteredPharmacies)
            }
            .onAppear {
                Task {
                    await viewModel.loadPharmacies()
                }
            }
            .onChange(of: selectedRegion) { region in
                Task {
                    await viewModel.loadPharmaciesByRegion(region)
                }
            }
            .onChange(of: showOnly24h) { only24h in
                if only24h {
                    Task {
                        await viewModel.load24HourPharmacies()
                    }
                } else {
                    Task {
                        await viewModel.loadPharmacies()
                    }
                }
            }
        }
    }
}

struct PharmacyRowView: View {
    let pharmacy: Pharmacy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(pharmacy.isOpen24Hours ? Color.appGreen : Color.gray)
                    .frame(width: 12, height: 12)

                Text(pharmacy.name)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                if pharmacy.isOpen24Hours {
                    Text("24h/24")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.appGreen)
                        .cornerRadius(12)
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(pharmacy.address)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 5) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(pharmacy.phoneNumber)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Spacer()

                if let distance = pharmacy.distance {
                    Text(String(format: "%.1f km", distance))
                        .font(.system(size: 13))
                        .foregroundColor(.appGreen)
                }
            }

            HStack(spacing: 15) {
                Button(action: { callPharmacy(pharmacy.phoneNumber) }) {
                    Label("Appeler", systemImage: "phone.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appGreen)
                }

                Button(action: { openInMaps(pharmacy.coordinate, name: pharmacy.name) }) {
                    Label("Itinéraire", systemImage: "arrow.triangle.turn.up.right.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appSecondary)
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

    private func callPharmacy(_ phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }

    private func openInMaps(_ coordinate: CLLocationCoordinate2D, name: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

struct PharmacyMapView: View {
    let pharmacies: [Pharmacy]
    @State private var region: MKCoordinateRegion
    @Environment(\.dismiss) var dismiss

    init(pharmacies: [Pharmacy]) {
        self.pharmacies = pharmacies

        let center = pharmacies.first?.coordinate ?? CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588)
        self._region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: pharmacies) { pharmacy in
                MapAnnotation(coordinate: pharmacy.coordinate) {
                    VStack {
                        Image(systemName: "cross.vial.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(pharmacy.isOpen24Hours ? Color.appGreen : Color.blue)
                            .clipShape(Circle())

                        Text(pharmacy.name)
                            .font(.caption)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(5)
                    }
                }
            }
            .navigationTitle("Carte des Pharmacies")
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

class PharmacyListViewModel: ObservableObject {
    @Published var pharmacies: [Pharmacy] = []
    @Published var isLoading = false

    private let apiService = APIService.shared
    private let locationManager = LocationManager.shared

    @MainActor
    func loadPharmacies() async {
        isLoading = true

        do {
            let latitude = locationManager.currentCoordinate?.latitude ?? 36.7538
            let longitude = locationManager.currentCoordinate?.longitude ?? 3.0588

            pharmacies = try await apiService.fetchNearbyPharmacies(
                latitude: latitude,
                longitude: longitude,
                radius: 5
            )

            // Calculate distances
            for index in pharmacies.indices {
                if let distance = locationManager.distance(to: pharmacies[index].coordinate) {
                    pharmacies[index].distance = distance
                }
            }
        } catch {
            loadMockPharmacies()
        }

        isLoading = false
    }

    @MainActor
    func loadPharmaciesByRegion(_ region: String) async {
        isLoading = true

        do {
            pharmacies = try await apiService.fetchPharmaciesByRegion(region)
        } catch {
            loadMockPharmacies()
        }

        isLoading = false
    }

    @MainActor
    func load24HourPharmacies() async {
        isLoading = true

        do {
            pharmacies = try await apiService.fetch24HourPharmacies()
        } catch {
            loadMockPharmacies()
        }

        isLoading = false
    }

    private func loadMockPharmacies() {
        pharmacies = [
            Pharmacy(
                id: "1",
                name: "Pharmacie Centrale",
                address: "Rue Didouche Mourad, Alger",
                phoneNumber: "+213 555 0101",
                latitude: 36.7530,
                longitude: 3.0590,
                isOpen24Hours: true,
                openingHours: "24h/24",
                distance: 1.2
            ),
            Pharmacy(
                id: "2",
                name: "Pharmacie El-Hamma",
                address: "Rue Mohamed Belouizdad, Alger",
                phoneNumber: "+213 555 0202",
                latitude: 36.7540,
                longitude: 3.0600,
                isOpen24Hours: false,
                openingHours: "08:00 - 22:00",
                distance: 2.5
            )
        ]
    }
}
