import SwiftUI
import MapKit

// Vue de carte pour les pharmacies
struct PharmacyMapView: View {
    let pharmacies: [Pharmacy]
    @Binding var selectedPharmacy: Pharmacy?
    @Environment(\.dismiss) var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: pharmacies) { pharmacy in
                MapAnnotation(coordinate: pharmacy.coordinate) {
                    VStack {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(pharmacy.isOpen24Hours ? Color.green : Color.blue)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedPharmacy = pharmacy
                            }

                        if selectedPharmacy?.id == pharmacy.id {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pharmacy.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text(pharmacy.phoneNumber)
                                    .font(.caption2)
                                if pharmacy.isOpen24Hours {
                                    Text("24h/24")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 3)
                        }
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
            .overlay(alignment: .bottom) {
                if let pharmacy = selectedPharmacy {
                    PharmacyDetailCard(pharmacy: pharmacy)
                        .padding()
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

// Carte de détail pour la pharmacie sélectionnée
struct PharmacyDetailCard: View {
    let pharmacy: Pharmacy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pharmacy.name)
                        .font(.headline)

                    Text(pharmacy.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if pharmacy.isOpen24Hours {
                    Label("24h", systemImage: "moon.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Divider()

            HStack(spacing: 20) {
                // Bouton Appeler
                Button(action: {
                    if let url = URL(string: "tel://\(pharmacy.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Appeler", systemImage: "phone.fill")
                        .font(.subheadline)
                }

                // Bouton Navigation
                Button(action: {
                    openInMaps(coordinate: pharmacy.coordinate, name: pharmacy.name)
                }) {
                    Label("Itinéraire", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.subheadline)
                }
            }

            Text("Horaires: \(pharmacy.openingHours)")
                .font(.caption)
                .foregroundColor(pharmacy.isOpen24Hours ? .green : .primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }

    private func openInMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// Extension pour les annotations MapKit
extension MKPointAnnotation {
    static func fromPharmacy(_ pharmacy: Pharmacy) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = pharmacy.coordinate
        annotation.title = pharmacy.name
        annotation.subtitle = pharmacy.isOpen24Hours ? "Ouvert 24h/24" : pharmacy.openingHours
        return annotation
    }
}
