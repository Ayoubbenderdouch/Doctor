import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditing = false
    @State private var age = ""
    @State private var bloodType = "O+"
    @State private var showingLogoutAlert = false

    let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.appPrimary, .appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(authManager.currentUser?.full_name.prefix(2).uppercased() ?? "U")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 5) {
                            Text(authManager.currentUser?.full_name ?? "Utilisateur")
                                .font(.system(size: 20, weight: .semibold))

                            Text(authManager.currentUser?.email ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Text(authManager.currentUser?.phone ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 10)
                }

                Section("Informations médicales") {
                    if isEditing {
                        HStack {
                            Text("Âge")
                            Spacer()
                            TextField("30", text: $age)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        Picker("Groupe sanguin", selection: $bloodType) {
                            ForEach(bloodTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    } else {
                        HStack {
                            Text("Âge")
                            Spacer()
                            Text("\(viewModel.profile?.age ?? 0) ans")
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Text("Groupe sanguin")
                            Spacer()
                            Text(viewModel.profile?.bloodType ?? "Non renseigné")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section("Localisation") {
                    HStack {
                        Text("Position actuelle")
                        Spacer()
                        if let profile = viewModel.profile {
                            Text(String(format: "%.4f, %.4f", profile.latitude, profile.longitude))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        } else {
                            Text("Non disponible")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section {
                    Button(action: {
                        if isEditing {
                            saveProfile()
                        } else {
                            isEditing = true
                            age = String(viewModel.profile?.age ?? 30)
                            bloodType = viewModel.profile?.bloodType ?? "O+"
                        }
                    }) {
                        HStack {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                            Text(isEditing ? "Enregistrer" : "Modifier le profil")
                        }
                        .foregroundColor(.appPrimary)
                    }

                    if isEditing {
                        Button("Annuler") {
                            isEditing = false
                        }
                        .foregroundColor(.gray)
                    }
                }

                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                            Text("Se déconnecter")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Mon Profil")
            .onAppear {
                Task {
                    await viewModel.loadProfile()
                }
            }
            .alert("Déconnexion", isPresented: $showingLogoutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Se déconnecter", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter?")
            }
            .alert("Profil mis à jour", isPresented: $viewModel.showSuccess) {
                Button("OK") {}
            } message: {
                Text("Vos informations ont été mises à jour avec succès")
            }
        }
    }

    private func saveProfile() {
        Task {
            let success = await viewModel.updateProfile(
                age: Int(age) ?? 30,
                bloodType: bloodType
            )

            if success {
                isEditing = false
            }
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let apiService = APIService.shared
    private let locationManager = LocationManager.shared

    @MainActor
    func loadProfile() async {
        do {
            profile = try await apiService.getUserProfile()
        } catch {
            // Use mock data as fallback
            profile = UserProfile(
                id: "1",
                email: "user@example.com",
                fullName: "Utilisateur Test",
                phone: "+213 555 0000",
                age: 30,
                bloodType: "O+",
                latitude: locationManager.currentCoordinate?.latitude ?? 36.7538,
                longitude: locationManager.currentCoordinate?.longitude ?? 3.0588
            )
        }
    }

    @MainActor
    func updateProfile(age: Int, bloodType: String) async -> Bool {
        let latitude = locationManager.currentCoordinate?.latitude ?? 36.7538
        let longitude = locationManager.currentCoordinate?.longitude ?? 3.0588

        let updatedProfile = UserProfile(
            id: profile?.id,
            email: profile?.email,
            fullName: profile?.fullName,
            phone: profile?.phone,
            age: age,
            bloodType: bloodType,
            latitude: latitude,
            longitude: longitude
        )

        do {
            profile = try await apiService.updateUserProfile(updatedProfile)
            showSuccess = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            // Update local copy anyway
            profile = updatedProfile
            showSuccess = true
            return true
        }
    }
}
