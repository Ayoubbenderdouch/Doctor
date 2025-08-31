import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://pharmacy-med17-production.up.railway.app"

    private init() {}

    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }

    enum NetworkError: LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case serverError(String)
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return NSLocalizedString("URL invalide", comment: "")
            case .noData:
                return NSLocalizedString("Aucune donnée reçue", comment: "")
            case .decodingError:
                return NSLocalizedString("Erreur de décodage", comment: "")
            case .serverError(let message):
                return message
            case .unauthorized:
                return NSLocalizedString("Non autorisé", comment: "")
            }
        }
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {

        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = KeychainManager.shared.get(for: .accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if provided
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError(NSLocalizedString("Réponse invalide", comment: ""))
            }

            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(NSLocalizedString("Erreur serveur: \(httpResponse.statusCode)", comment: ""))
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)

        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
}
