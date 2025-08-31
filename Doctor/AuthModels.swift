import Foundation

// MARK: - Registration Models
struct RegistrationRequest: Codable {
    let email: String
    let password: String
    let role: String
    let full_name: String
    let phone: String
    let region: String
    let age: Int
    let blood_type: String
}

struct RegistrationResponse: Codable {
    let success: Bool
    let message: String?
    let user: AuthUser?
    let tokens: AuthTokens?
}

// MARK: - Login Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String?
    let user: AuthUser?
    let tokens: AuthTokens?
}

// MARK: - Token Models
struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let success: Bool
    let tokens: AuthTokens?
    let message: String?
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
}

// MARK: - User Model
struct AuthUser: Codable {
    let id: String
    let email: String
    let full_name: String
    let phone: String
    let region: String
    let age: Int?
    let blood_type: String?
    let role: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case full_name
        case phone
        case region
        case age
        case blood_type
        case role
        case createdAt = "created_at"
    }
}

// MARK: - Error Types
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case serverError(String)
    case invalidResponse
    case tokenExpired
    case registrationFailed(String)
    case loginFailed(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email ou mot de passe incorrect"
        case .networkError:
            return "Erreur de connexion réseau"
        case .serverError(let message):
            return message
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .tokenExpired:
            return "Votre session a expiré"
        case .registrationFailed(let message):
            return "Échec de l'inscription: \(message)"
        case .loginFailed(let message):
            return "Échec de la connexion: \(message)"
        case .unknownError:
            return "Une erreur inconnue s'est produite"
        }
    }
}

// MARK: - Blood Type Enum
enum BloodType: String, CaseIterable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive = "O+"
    case oNegative = "O-"

    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Region Enum
enum AlgerianRegion: String, CaseIterable {
    case algiers = "Algiers"
    case oran = "Oran"
    case constantine = "Constantine"
    case annaba = "Annaba"
    case blida = "Blida"
    case batna = "Batna"
    case djelfa = "Djelfa"
    case setif = "Sétif"
    case sidibelabbes = "Sidi Bel Abbès"
    case biskra = "Biskra"
    case tebessa = "Tébessa"
    case elOued = "El Oued"
    case skikda = "Skikda"
    case tiaret = "Tiaret"
    case bejaia = "Béjaïa"
    case tlemcen = "Tlemcen"

    var displayName: String {
        return self.rawValue
    }
}
