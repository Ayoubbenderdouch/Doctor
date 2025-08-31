import SwiftUI

@main
struct DoctorApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var locationManager = LocationManager.shared

    init() {
        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.appPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.appPrimary)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(locationManager)
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Colors
extension Color {
    static let appPrimary = Color(red: 0.95, green: 0.26, blue: 0.21)
    static let appSecondary = Color(red: 0.25, green: 0.62, blue: 0.96)
    static let appGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let appBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let appPurple = Color(red: 0.58, green: 0.39, blue: 0.92)
    static let appOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
}
