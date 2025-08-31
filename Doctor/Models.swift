import Foundation
import CoreLocation

// MARK: - Doctor Model
struct Doctor: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let specialty: String
    let address: String
    let city: String
    let phoneNumber: String
    let latitude: Double
    let longitude: Double
    let availableSlots: [AppointmentSlot]?
    let rating: Double?
    let yearsOfExperience: Int?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, specialty, address, city
        case phoneNumber = "phone_number"
        case latitude, longitude
        case availableSlots = "available_slots"
        case rating
        case yearsOfExperience = "years_of_experience"
    }
}

// MARK: - Pharmacy Model
struct Pharmacy: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String
    let phoneNumber: String
    let latitude: Double
    let longitude: Double
    let isOpen24Hours: Bool
    let openingHours: String
    var distance: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address
        case phoneNumber = "phone_number"
        case latitude, longitude
        case isOpen24Hours = "is_open_24_hours"
        case openingHours = "opening_hours"
        case distance
    }
}

// MARK: - Appointment Models
struct AppointmentSlot: Identifiable, Codable, Equatable {
    let id: String
    let date: String
    let time: String
    let isBooked: Bool

    enum CodingKeys: String, CodingKey {
        case id, date, time
        case isBooked = "is_booked"
    }
}

struct Reservation: Identifiable, Codable {
    let id: String
    let doctorId: String
    let appointmentDate: String
    let appointmentTime: String
    let serviceType: String
    let notes: String?
    let status: String?
    let confirmationCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case doctorId = "doctor_id"
        case appointmentDate = "appointment_date"
        case appointmentTime = "appointment_time"
        case serviceType = "service_type"
        case notes, status
        case confirmationCode = "confirmation_code"
    }
}

struct ReservationRequest: Codable {
    let doctorId: String
    let appointmentDate: String
    let appointmentTime: String
    let serviceType: String
    let notes: String

    enum CodingKeys: String, CodingKey {
        case doctorId = "doctor_id"
        case appointmentDate = "appointment_date"
        case appointmentTime = "appointment_time"
        case serviceType = "service_type"
        case notes
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let id: String?
    let email: String?
    let fullName: String?
    let phone: String?
    let age: Int
    let bloodType: String
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case phone, age
        case bloodType = "blood_type"
        case latitude, longitude
    }
}

// MARK: - QR Code Models
struct QRCodeData: Codable {
    let doctorId: String
    let appointmentDate: String
    let appointmentTime: String
    let code: String

    enum CodingKeys: String, CodingKey {
        case doctorId = "doctor_id"
        case appointmentDate = "appointment_date"
        case appointmentTime = "appointment_time"
        case code
    }
}

struct QRScanRequest: Codable {
    let qrCode: String

    enum CodingKeys: String, CodingKey {
        case qrCode = "qr_code"
    }
}
