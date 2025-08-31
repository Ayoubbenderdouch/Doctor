import SwiftUI
import MapKit
import CoreLocation

struct DoctorMapView: View {
    let doctors: [Doctor]
    @Binding var selectedDoctor: Doctor?
    @State private var region: MKCoordinateRegion
    @State private var showDetailSheet = false
    @State private var mapType: MKMapType = .standard
    @State private var showUserLocation = true
    @Environment(\.dismiss) var dismiss

    init(doctors: [Doctor], selectedDoctor: Binding<Doctor?>) {
        self.doctors = doctors
        self._selectedDoctor = selectedDoctor

        // Zentrum auf Algier
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $region,
                    showsUserLocation: showUserLocation,
                    annotationItems: doctors) { doctor in
                    MapAnnotation(coordinate: doctor.coordinate) {
                        DoctorMapPin(
                            doctor: doctor,
                            isSelected: selectedDoctor?.id == doctor.id,
                            specialtyColors: specialtyColors
                        ) {
                            withAnimation(.spring()) {
                                selectedDoctor = doctor
                                showDetailSheet = true
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)

                // Map Controls
                VStack {
                    HStack {
                        // Map Type Selector
                        MapTypeSelector(mapType: $mapType)
                            .padding(.leading)

                        Spacer()

                        // Current Location Button
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.appSecondary)
                                        .shadow(color: .black.opacity(0.2), radius: 5)
                                )
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 60)

                    Spacer()

                    // Doctor List Bottom Sheet
                    DoctorMapListView(
                        doctors: doctors,
                        selectedDoctor: $selectedDoctor,
                        onSelectDoctor: { doctor in
                            selectedDoctor = doctor
                            showDetailSheet = true
                            centerOnDoctor(doctor)
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Carte des Médecins")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.appSecondary)
                }
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let doctor = selectedDoctor {
                DoctorDetailMapSheet(doctor: doctor)
            }
        }
    }

    private func centerOnUserLocation() {
        // Hier würde normalerweise die aktuelle Position des Benutzers abgerufen
        // Für Demo-Zwecke verwenden wir Algier
        withAnimation {
            region.center = CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588)
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }

    private func centerOnDoctor(_ doctor: Doctor) {
        withAnimation {
            region.center = doctor.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
    }

    let specialtyColors: [String: Color] = [
        "Médecine Générale": .appSecondary,
        "Cardiologie": .appPrimary,
        "Dermatologie": .appOrange,
        "Pédiatrie": .appPurple,
        "Orthopédie": .appGreen,
        "Gynécologie": .pink,
        "Ophtalmologie": .cyan
    ]
}

struct DoctorMapPin: View {
    let doctor: Doctor
    let isSelected: Bool
    let specialtyColors: [String: Color]
    let action: () -> Void

    @State private var showLabel = false

    var pinColor: Color {
        specialtyColors[doctor.specialty] ?? .appSecondary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Doctor info bubble
            if isSelected || showLabel {
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(doctor.specialty)
                        .font(.system(size: 12))
                        .foregroundColor(pinColor)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text("\(doctor.availableSlots.filter { !$0.isBooked }.count) créneaux")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Pin
            ZStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [pinColor, pinColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: pinColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Image(systemName: getSpecialtyIcon(for: doctor.specialty))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: -5)
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    showLabel.toggle()
                    action()
                }
            }
        }
    }

    func getSpecialtyIcon(for specialty: String) -> String {
        let icons: [String: String] = [
            "Médecine Générale": "stethoscope",
            "Cardiologie": "heart.fill",
            "Dermatologie": "face.smiling",
            "Pédiatrie": "figure.2.and.child.holdinghands",
            "Orthopédie": "figure.walk",
            "Gynécologie": "person.fill",
            "Ophtalmologie": "eye.fill"
        ]
        return icons[specialty] ?? "stethoscope"
    }
}

struct MapTypeSelector: View {
    @Binding var mapType: MKMapType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MapTypeOption.allCases, id: \.self) { option in
                Button(action: {
                    withAnimation {
                        mapType = option.mapType
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: option.icon)
                            .font(.system(size: 20))
                        Text(option.title)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(mapType == option.mapType ? .white : .gray)
                    .frame(width: 60, height: 50)
                    .background(
                        mapType == option.mapType ?
                        Color.appSecondary :
                        Color.white.opacity(0.9)
                    )
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

enum MapTypeOption: CaseIterable {
    case standard
    case satellite
    case hybrid

    var mapType: MKMapType {
        switch self {
        case .standard: return .standard
        case .satellite: return .satellite
        case .hybrid: return .hybrid
        }
    }

    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe"
        case .hybrid: return "square.stack.3d.up"
        }
    }

    var title: String {
        switch self {
        case .standard: return "Plan"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybride"
        }
    }
}

struct DoctorMapListView: View {
    let doctors: [Doctor]
    @Binding var selectedDoctor: Doctor?
    let onSelectDoctor: (Doctor) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }

            // Header
            HStack {
                Text("\(doctors.count) médecins à proximité")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }

            // Doctor List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(doctors) { doctor in
                        DoctorMapCard(
                            doctor: doctor,
                            isSelected: selectedDoctor?.id == doctor.id
                        ) {
                            onSelectDoctor(doctor)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: isExpanded ? 400 : 150)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.95))
                )
                .ignoresSafeArea()
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

struct DoctorMapCard: View {
    let doctor: Doctor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Specialty Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    getSpecialtyColor().opacity(0.2),
                                    getSpecialtyColor().opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: getSpecialtyIcon())
                        .font(.system(size: 24))
                        .foregroundColor(getSpecialtyColor())
                }

                // Doctor Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(doctor.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(doctor.specialty)
                        .font(.system(size: 14))
                        .foregroundColor(getSpecialtyColor())

                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 12))
                        Text("\(doctor.availableSlots.filter { !$0.isBooked }.count) créneaux disponibles")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Direction Arrow
                Image(systemName: "location.arrow.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(getSpecialtyColor())
                    .opacity(isSelected ? 1 : 0.5)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? getSpecialtyColor().opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? getSpecialtyColor() : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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

    func getSpecialtyIcon() -> String {
        let icons: [String: String] = [
            "Médecine Générale": "stethoscope",
            "Cardiologie": "heart.fill",
            "Dermatologie": "face.smiling",
            "Pédiatrie": "figure.2.and.child.holdinghands",
            "Orthopédie": "figure.walk",
            "Gynécologie": "person.fill",
            "Ophtalmologie": "eye.fill"
        ]
        return icons[doctor.specialty] ?? "stethoscope"
    }
}

struct DoctorDetailMapSheet: View {
    let doctor: Doctor
    @Environment(\.dismiss) var dismiss
    @State private var showBooking = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Doctor Header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [getSpecialtyColor(), getSpecialtyColor().opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Text(doctor.name.prefix(2))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 10) {
                            Text(doctor.name)
                                .font(.system(size: 26, weight: .bold))

                            HStack {
                                Image(systemName: getSpecialtyIcon())
                                    .font(.system(size: 18))
                                Text(doctor.specialty)
                                    .font(.system(size: 18))
                            }
                            .foregroundColor(getSpecialtyColor())
                        }
                    }
                    .padding(.top)

                    // Contact & Location
                    VStack(spacing: 20) {
                        // Address
                        HStack(spacing: 15) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Adresse")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(doctor.address)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Button(action: openInMaps) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.05))
                        )

                        // Phone
                        HStack(spacing: 15) {
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Téléphone")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(doctor.phoneNumber)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Button(action: callDoctor) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color.green))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.05))
                        )
                    }
                    .padding(.horizontal)

                    // Available Slots Preview
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 20))
                                .foregroundColor(getSpecialtyColor())

                            Text("Prochains créneaux disponibles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(doctor.availableSlots.filter { !$0.isBooked }.prefix(5)) { slot in
                                    VStack(spacing: 8) {
                                        Text(slot.date, format: .dateTime.weekday(.abbreviated).locale(Locale(identifier: "fr_FR")))
                                            .font(.system(size: 12))
                                            .textCase(.uppercase)

                                        Text(slot.date, format: .dateTime.day())
                                            .font(.system(size: 22, weight: .bold))

                                        Text(slot.time)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.primary)
                                    .frame(width: 80, height: 90)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(getSpecialtyColor().opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(getSpecialtyColor().opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { showBooking = true }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20))
                                Text("Prendre rendez-vous")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [getSpecialtyColor(), getSpecialtyColor().opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(
                                color: getSpecialtyColor().opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                        }

                        HStack(spacing: 15) {
                            ShareButton(doctor: doctor, color: getSpecialtyColor())
                            SaveButton(doctor: doctor, color: getSpecialtyColor())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }

    }

    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: doctor.coordinate))
        mapItem.name = doctor.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func callDoctor() {
        if let url = URL(string: "tel://\(doctor.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
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

    func getSpecialtyIcon() -> String {
        let icons: [String: String] = [
            "Médecine Générale": "stethoscope",
            "Cardiologie": "heart.fill",
            "Dermatologie": "face.smiling",
            "Pédiatrie": "figure.2.and.child.holdinghands",
            "Orthopédie": "figure.walk",
            "Gynécologie": "person.fill",
            "Ophtalmologie": "eye.fill"
        ]
        return icons[doctor.specialty] ?? "stethoscope"
    }
}

struct ShareButton: View {
    let doctor: Doctor
    let color: Color

    var body: some View {
        Button(action: shareDoctor) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                Text("Partager")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: 2)
            )
        }
    }

    private func shareDoctor() {
        let text = """
        Dr. \(doctor.name)
        Spécialité: \(doctor.specialty)
        Adresse: \(doctor.address)
        Téléphone: \(doctor.phoneNumber)
        """

        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

struct SaveButton: View {
    let doctor: Doctor
    let color: Color
    @State private var isSaved = false

    var body: some View {
        Button(action: toggleSave) {
            HStack {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                Text(isSaved ? "Enregistré" : "Enregistrer")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSaved ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSaved ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color, lineWidth: 2)
                    )
            )
        }
    }

    private func toggleSave() {
        withAnimation(.spring()) {
            isSaved.toggle()
        }

        // Hier würde normalerweise die Speicherlogik implementiert werden
    }
}
