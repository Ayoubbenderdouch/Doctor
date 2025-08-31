import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                LoginView()
                    .transition(.opacity)
            } else {
                MainTabView(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(), value: authManager.isAuthenticated)
        .onAppear {
            authManager.checkAuthenticationStatus()
            locationManager.requestLocationPermission()
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        TabView(selection: $selectedTab) {
            DoctorListView()
                .tabItem {
                    Label("Médecins", systemImage: "heart.text.square.fill")
                }
                .tag(0)

            PharmacyListView()
                .tabItem {
                    Label("Pharmacies", systemImage: "cross.vial.fill")
                }
                .tag(1)

            MyBookingsView()
                .tabItem {
                    Label("Réservations", systemImage: "calendar")
                }
                .tag(2)

            QRScanView()
                .tabItem {
                    Label("Scanner", systemImage: "qrcode.viewfinder")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.appPrimary)
    }
}
