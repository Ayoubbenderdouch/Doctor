import Foundation
import CoreLocation

class APIService: ObservableObject {
    static let shared = APIService()
    private let networkManager = NetworkManager.shared

    private init() {}

    // MARK: - Doctor Endpoints

    func fetchNearbyDoctors(latitude: Double, longitude: Double, radius: Double = 10) async throws -> [Doctor] {
        let endpoint = "/api/client/doctors/nearby?latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)"
        return try await networkManager.request(endpoint: endpoint, method: .GET)
    }

    func fetchDoctorsBySpecialty(_ specialty: String) async throws -> [Doctor] {
        let endpoint = "/api/client/doctors/specialty/\(specialty.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await networkManager.request(endpoint: endpoint, method: .GET)
    }

    func searchDoctors(query: String) async throws -> [Doctor] {
        let endpoint = "/api/client/doctors/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await networkManager.request(endpoint: endpoint, method: .GET)
    }

    // MARK: - Pharmacy Endpoints

    func fetchNearbyPharmacies(latitude: Double, longitude: Double, radius: Double = 5) async throws -> [Pharmacy] {
        let endpoint = "/api/client/pharmacies/nearby?latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)"
        return try await networkManager.request(endpoint: endpoint, method: .GET)
    }

    func fetchPharmaciesByRegion(_ region: String) async throws -> [Pharmacy] {
        let endpoint = "/api/pharmacy?region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await networkManager.request(endpoint: endpoint, method: .GET)
    }

    func fetch24HourPharmacies() async throws -> [Pharmacy] {
        let endpoint = "/api/client/pharmacies/24h"
        return try await networkManager.request(endpoint: endpoint, method: .GET)
    }

    // MARK: - Reservation Endpoints

    func createReservation(_ request: ReservationRequest) async throws -> Reservation {
        return try await networkManager.request(
            endpoint: "/api/client/reservations",
            method: .POST,
            body: request
        )
    }

    func getMyReservations() async throws -> [Reservation] {
        return try await networkManager.request(
            endpoint: "/api/client/reservations",
            method: .GET
        )
    }

    func scanQRCode(_ qrData: String) async throws -> Bool {
        let request = QRScanRequest(qrCode: qrData)
        let _: EmptyResponse = try await networkManager.request(
            endpoint: "/api/client/reservations/scan-qr",
            method: .POST,
            body: request
        )
        return true
    }

    // MARK: - Profile Endpoints

    func getUserProfile() async throws -> UserProfile {
        return try await networkManager.request(
            endpoint: "/api/client/profile",
            method: .GET
        )
    }

    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        return try await networkManager.request(
            endpoint: "/api/client/profile",
            method: .POST,
            body: profile
        )
    }
}

struct EmptyResponse: Codable {}
