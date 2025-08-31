import SwiftUI
import MapKit
import CoreLocation

struct PharmacyView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var apiService = APIService.shared
    @State private var selectedPharmacy: Pharmacy?
    @State private var showingMap = false
    @State private var searchText = ""
    @State private var showOnly24h = false
    @State private var animateCards = false
    @State private var pulseAnimation = false
    @State private var selectedFilter = "distance"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedInitialData = false

    // Radius für die Suche (in km)
    @State private var searchRadius: Double = 5.0

    @State private var pharmacies: [Pharmacy] = []

    var filteredPharmacies: [Pharmacy] {
        var filtered = pharmacies

        if showOnly24h {
            filtered = filtered.filter { $0.isOpen24Hours }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort by selected filter
        switch selectedFilter {
        case "distance":
            filtered.sort { ($0.distance ?? 0) < ($1.distance ?? 0) }
        case "name":
            filtered.sort { $0.name < $1.name }
        case "24h":
            filtered.sort { $0.isOpen24Hours && !$1.isOpen24Hours }
        default:
            break
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Ultra Modern Animated Background
                UltraModernBackground()

                VStack(spacing: 0) {
                    // Futuristic Header
                    VStack(spacing: 25) {
                        // Animated Logo and Title
                        HStack(spacing: 20) {
                            // 3D-like animated logo
                            ZStack {
                                ForEach(0..<3) { index in
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.appGreen.opacity(0.3 - Double(index) * 0.1),
                                                    Color.cyan.opacity(0.3 - Double(index) * 0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50 - CGFloat(index * 5), height: 50 - CGFloat(index * 5))
                                        .rotationEffect(.degrees(pulseAnimation ? Double(index * 15) : Double(index * -15)))
                                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                                        .animation(
                                            .easeInOut(duration: 2)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                            value: pulseAnimation
                                        )
                                }

                                Image(systemName: "cross.vial.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .green.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: .appGreen, radius: 5)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Pharmacies")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.appGreen, .cyan, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("\(filteredPharmacies.count) disponibles")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .opacity(animateCards ? 1 : 0)
                                    .animation(.easeIn(duration: 0.5).delay(0.3), value: animateCards)
                            }

                            Spacer()

                            // Map Button with pulse
                            Button(action: { showingMap = true }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)

                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.appGreen, .cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: 50, height: 50)
                                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                        .opacity(pulseAnimation ? 0 : 0.8)
                                        .animation(
                                            .easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false),
                                            value: pulseAnimation
                                        )

                                    Image(systemName: "map.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.appGreen, .cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }

                            // Refresh Button
                            Button(action: fetchNearbyPharmacies) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)

                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .appGreen))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 20))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.appGreen, .cyan],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Futuristic Search Bar
                        HStack(spacing: 15) {
                            // Search icon with animation
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.appGreen.opacity(0.2), .cyan.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)

                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.appGreen, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .rotationEffect(.degrees(searchText.isEmpty ? 0 : 360))
                                    .animation(.easeInOut(duration: 0.5), value: searchText)
                            }

                            TextField("Rechercher...", text: $searchText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .onChange(of: searchText) { _ in
                                    searchPharmaciesIfNeeded()
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        searchText = ""
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.gray, .gray.opacity(0.7)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.ultraThinMaterial)

                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.5),
                                                .clear,
                                                .white.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )

                                // Animated border
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: searchText.isEmpty ?
                                                [.clear, .clear] :
                                                [.appGreen.opacity(0.5), .cyan.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: searchText)
                            }
                        )
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                        .padding(.horizontal)

                        // Filter Options
                        VStack(spacing: 15) {
                            // 24h Toggle with custom design
                            HStack {
                                ForEach(["distance", "name", "24h"], id: \.self) { filter in
                                    FilterChip(
                                        title: filter == "distance" ? "Distance" :
                                               filter == "name" ? "Nom" : "24h/24",
                                        icon: filter == "distance" ? "location.fill" :
                                              filter == "name" ? "textformat" : "moon.stars.fill",
                                        isSelected: selectedFilter == filter,
                                        color: filter == "24h" ? .appGreen : .appSecondary
                                    ) {
                                        withAnimation(.spring()) {
                                            selectedFilter = filter
                                            if filter == "24h" {
                                                showOnly24h.toggle()
                                                if showOnly24h {
                                                    fetch24HourPharmacies()
                                                } else {
                                                    fetchNearbyPharmacies()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Radius Selector
                            if locationManager.isAuthorized {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Rayon de recherche: \(Int(searchRadius)) km")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Slider(value: $searchRadius, in: 1...20, step: 1) { _ in
                                        // On editing ended
                                        fetchNearbyPharmacies()
                                    }
                                    .accentColor(.appGreen)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    .background(
                        ZStack {
                            // Gradient mesh background
                            MeshGradient()
                                .opacity(0.3)

                            // Glass effect
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.ultraThinMaterial)
                        }
                        .ignoresSafeArea(edges: .top)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )

                    // Error Message
                    if let errorMessage = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)

                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                self.errorMessage = nil
                                fetchNearbyPharmacies()
                            }) {
                                Text("Réessayer")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.appGreen)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Pharmacy Cards with parallax
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            if isLoading && pharmacies.isEmpty {
                                // Loading State
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .appGreen))
                                        .scaleEffect(1.5)

                                    Text("Chargement des pharmacies...")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 100)
                            } else if filteredPharmacies.isEmpty {
                                EmptyStateView()
                                    .padding(.top, 50)
                            } else {
                                ForEach(Array(filteredPharmacies.enumerated()), id: \.element.id) { index, pharmacy in
                                    UltraModernPharmacyCard(
                                        pharmacy: pharmacy,
                                        index: index
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedPharmacy = pharmacy
                                            showingMap = true
                                        }
                                    }
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(y: animateCards ? 0 : 50)
                                    .scaleEffect(animateCards ? 1 : 0.8)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1),
                                        value: animateCards
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await fetchNearbyPharmaciesAsync()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMap) {
                PharmacyMapView(pharmacies: filteredPharmacies, selectedPharmacy: $selectedPharmacy)
            }
            .onAppear {
                setupLocationManager()
                if !hasLoadedInitialData {
                    fetchNearbyPharmacies()
                    hasLoadedInitialData = true
                }
                withAnimation {
                    animateCards = true
                    pulseAnimation = true
                }
            }
        }
    }

    // MARK: - Location Setup
    private func setupLocationManager() {
        if !locationManager.isAuthorized && !locationManager.isDenied {
            locationManager.requestLocationPermission()
        }

        if locationManager.isAuthorized {
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - API Calls
    private func fetchNearbyPharmacies() {
        Task {
            await fetchNearbyPharmaciesAsync()
        }
    }

    @MainActor
    private func fetchNearbyPharmaciesAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            let latitude: Double
            let longitude: Double

            // Use user location if available, otherwise use Algiers center
            if let userLocation = locationManager.location {
                latitude = userLocation.coordinate.latitude
                longitude = userLocation.coordinate.longitude
            } else {
                // Default to Algiers center
                latitude = 36.7538
                longitude = 3.0588
            }

            // Fetch pharmacies from API
            let fetchedPharmacies = try await apiService.fetchPharmaciesNearby(
                latitude: latitude,
                longitude: longitude,
                radius: searchRadius
            )

            // Update pharmacies with calculated distances
            self.pharmacies = fetchedPharmacies.map { pharmacy in
                var updatedPharmacy = pharmacy

                // Calculate distance
                if let userLocation = locationManager.location {
                    let pharmacyLocation = CLLocation(
                        latitude: pharmacy.latitude,
                        longitude: pharmacy.longitude
                    )
                    updatedPharmacy.distance = userLocation.distance(from: pharmacyLocation) / 1000 // Convert to km
                }

                return updatedPharmacy
            }

            // Animate the cards
            withAnimation {
                animateCards = true
            }

        } catch {
            handleAPIError(error)
        }

        isLoading = false
    }

    private func fetch24HourPharmacies() {
        Task {
            await fetch24HourPharmaciesAsync()
        }
    }

    @MainActor
    private func fetch24HourPharmaciesAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch 24h pharmacies from API
            let fetchedPharmacies = try await apiService.fetch24HourPharmacies()

            // Update pharmacies with calculated distances
            self.pharmacies = fetchedPharmacies.map { pharmacy in
                var updatedPharmacy = pharmacy

                // Calculate distance if location is available
                if let userLocation = locationManager.location {
                    let pharmacyLocation = CLLocation(
                        latitude: pharmacy.latitude,
                        longitude: pharmacy.longitude
                    )
                    updatedPharmacy.distance = userLocation.distance(from: pharmacyLocation) / 1000
                }

                return updatedPharmacy
            }

        } catch {
            handleAPIError(error)
        }

        isLoading = false
    }

    private func searchPharmaciesIfNeeded() {
        guard !searchText.isEmpty else {
            fetchNearbyPharmacies()
            return
        }

        Task {
            await searchPharmaciesAsync()
        }
    }

    @MainActor
    private func searchPharmaciesAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            // Search pharmacies from API
            let fetchedPharmacies = try await apiService.searchPharmacies(query: searchText)

            // Update pharmacies with calculated distances
            self.pharmacies = fetchedPharmacies.map { pharmacy in
                var updatedPharmacy = pharmacy

                // Calculate distance if location is available
                if let userLocation = locationManager.location {
                    let pharmacyLocation = CLLocation(
                        latitude: pharmacy.latitude,
                        longitude: pharmacy.longitude
                    )
                    updatedPharmacy.distance = userLocation.distance(from: pharmacyLocation) / 1000
                }

                return updatedPharmacy
            }

        } catch {
            handleAPIError(error)
        }

        isLoading = false
    }

    private func handleAPIError(_ error: Error) {
        print("API Error: \(error)")

        // Check if it's an authentication error
        if let authError = error as? AuthError {
            switch authError {
            case .tokenExpired:
                errorMessage = "Votre session a expiré. Veuillez vous reconnecter."
                // You might want to redirect to login here
            case .networkError:
                errorMessage = "Erreur de connexion. Vérifiez votre connexion internet."
                loadMockDataAsFailsafe()
            default:
                errorMessage = "Une erreur s'est produite: \(authError.localizedDescription)"
                loadMockDataAsFailsafe()
            }
        } else {
            errorMessage = "Impossible de charger les pharmacies. Utilisation des données de démonstration."
            loadMockDataAsFailsafe()
        }
    }

    // MARK: - Failsafe Mock Data
    private func loadMockDataAsFailsafe() {
        // Load mock data when API fails
        pharmacies = [
            Pharmacy(
                name: "Pharmacie Centrale",
                address: "Rue Didouche Mourad, Alger",
                phoneNumber: "+213 555 0101",
                coordinate: CLLocationCoordinate2D(latitude: 36.7530, longitude: 3.0590),
                isOpen24Hours: true,
                openingHours: "24h/24"
            ),
            Pharmacy(
                name: "Pharmacie El-Hamma",
                address: "Rue Mohamed Belouizdad, Alger",
                phoneNumber: "+213 555 0202",
                coordinate: CLLocationCoordinate2D(latitude: 36.7540, longitude: 3.0600),
                isOpen24Hours: false,
                openingHours: "08:00 - 22:00"
            ),
            Pharmacy(
                name: "Pharmacie de Garde",
                address: "Boulevard des Martyrs, Alger",
                phoneNumber: "+213 555 0303",
                coordinate: CLLocationCoordinate2D(latitude: 36.7520, longitude: 3.0580),
                isOpen24Hours: true,
                openingHours: "24h/24"
            )
        ]

        updatePharmacyDistances()
    }

    private func updatePharmacyDistances() {
        guard let userLocation = locationManager.location else { return }

        for index in pharmacies.indices {
            let pharmacyLocation = CLLocation(
                latitude: pharmacies[index].coordinate.latitude,
                longitude: pharmacies[index].coordinate.longitude
            )
            pharmacies[index].distance = userLocation.distance(from: pharmacyLocation) / 1000
        }
    }
}

// MARK: - UI Components

struct UltraModernPharmacyCard: View {
    let pharmacy: Pharmacy
    let index: Int
    @State private var isPressed = false
    @State private var showDetails = false

    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            pharmacy.isOpen24Hours ?
                                Color.appGreen.opacity(0.05) :
                                Color.appSecondary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    pharmacy.isOpen24Hours ?
                                        Color.appGreen.opacity(0.3) :
                                        Color.gray.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)

            VStack(spacing: 20) {
                // Header with animation
                HStack(spacing: 20) {
                    // Animated Icon
                    ZStack {
                        // Rotating background
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        pharmacy.isOpen24Hours ? .appGreen : .appSecondary,
                                        pharmacy.isOpen24Hours ? .cyan : .appPurple,
                                        pharmacy.isOpen24Hours ? .appGreen : .appSecondary
                                    ],
                                    center: .center
                                )
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(isPressed ? 360 : 0))
                            .animation(.easeInOut(duration: 0.5), value: isPressed)

                        // Inner circle
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)

                        // Icon with gradient
                        Image(systemName: "cross.vial.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: pharmacy.isOpen24Hours ?
                                        [.appGreen, .cyan] :
                                        [.appSecondary, .appPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        // Pharmacy name with animation
                        Text(pharmacy.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        // Address with icon
                        HStack(spacing: 8) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.gray, .gray.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text(pharmacy.address)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        // 24h Badge
                        if pharmacy.isOpen24Hours {
                            HStack(spacing: 8) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 12))

                                Text("Ouvert 24h/24")
                                    .font(.system(size: 13, weight: .semibold))

                                Spacer()

                                // Animated pulse dot
                                ZStack {
                                    Circle()
                                        .fill(Color.appGreen)
                                        .frame(width: 8, height: 8)

                                    Circle()
                                        .stroke(Color.appGreen, lineWidth: 2)
                                        .frame(width: 16, height: 16)
                                        .scaleEffect(isPressed ? 1.5 : 1.0)
                                        .opacity(isPressed ? 0 : 1)
                                        .animation(
                                            .easeOut(duration: 1)
                                            .repeatForever(autoreverses: false),
                                            value: isPressed
                                        )
                                }
                            }
                            .foregroundColor(.appGreen)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.appGreen.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.appGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    Spacer()
                }

                // Interactive Details Section
                VStack(spacing: 15) {
                    HStack(spacing: 25) {
                        // Phone with action
                        ActionButton(
                            icon: "phone.fill",
                            title: "Appeler",
                            subtitle: pharmacy.phoneNumber,
                            color: .blue,
                            action: {
                                if let url = URL(string: "tel://\(pharmacy.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )

                        // Distance
                        if let distance = pharmacy.distance {
                            InfoBox(
                                icon: "location.fill",
                                value: String(format: "%.1f", distance),
                                unit: "km",
                                color: .appPrimary
                            )
                        }

                        // Hours
                        InfoBox(
                            icon: "clock.fill",
                            value: pharmacy.isOpen24Hours ? "24h" : "Fermé",
                            unit: pharmacy.isOpen24Hours ? "" : "22h",
                            color: pharmacy.isOpen24Hours ? .appGreen : .orange
                        )
                    }

                    // Animated action bar
                    HStack(spacing: 15) {
                        // Navigate button
                        ModernActionButton(
                            title: "Itinéraire",
                            icon: "location.arrow.triangle.fill",
                            gradient: [.appSecondary, .appPurple]
                        ) {
                            // Navigation action
                        }

                        // Details button
                        ModernActionButton(
                            title: "Détails",
                            icon: "info.circle.fill",
                            gradient: [.appGreen, .cyan]
                        ) {
                            withAnimation(.spring()) {
                                showDetails.toggle()
                            }
                        }
                    }
                }
                .padding(.top, 10)

                // Expandable details
                if showDetails {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                            .background(Color.gray.opacity(0.3))

                        Text("Services disponibles:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(["Vaccins", "Tests", "Conseil", "Urgences"], id: \.self) { service in
                                ServiceChip(service: service)
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(25)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .rotation3DEffect(
            .degrees(isPressed ? 5 : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(color.opacity(0.1))
            )
        }
    }
}

struct InfoBox: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring()) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isPressed ? 0.8 : 1)
            )
            .cornerRadius(15)
            .shadow(
                color: gradient[0].opacity(0.3),
                radius: isPressed ? 5 : 10,
                x: 0,
                y: isPressed ? 2 : 5
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct ServiceChip: View {
    let service: String

    var body: some View {
        Text(service)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.appSecondary)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.appSecondary.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.appSecondary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(), value: isSelected)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray, .gray.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("Aucune pharmacie trouvée")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Text("Essayez de modifier vos filtres")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
        )
    }
}

struct UltraModernBackground: View {
    @State private var animate = false
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 0.95)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )

            // Animated mesh
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appGreen.opacity(0.3),
                                Color.cyan.opacity(0.2),
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
                    .rotationEffect(.degrees(rotation + Double(index * 60)))
            }

            // Geometric patterns
            GeometryReader { geometry in
                ForEach(0..<3) { index in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height * CGFloat(index) / 3))
                        path.addCurve(
                            to: CGPoint(x: geometry.size.width, y: geometry.size.height * CGFloat(index + 1) / 3),
                            control1: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * CGFloat(index) / 3 + (animate ? 50 : -50)),
                            control2: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * CGFloat(index + 1) / 3 + (animate ? -50 : 50))
                        )
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appGreen.opacity(0.1),
                                Color.cyan.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 5)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animate = true
            }
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct MeshGradient: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for i in 0..<20 {
                    for j in 0..<20 {
                        let x = size.width * CGFloat(i) / 20
                        let y = size.height * CGFloat(j) / 20

                        let hue = (sin(time + Double(i + j) * 0.1) + 1) / 2
                        let color = Color(hue: hue * 0.1 + 0.3, saturation: 0.3, brightness: 0.9)

                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 30, height: 30)),
                            with: .color(color.opacity(0.3))
                        )
                    }
                }
            }
        }
    }
}
