
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var animateElements = false
    @State private var showMainApp = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    let onboardingPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Trouvez vos médecins",
            subtitle: "Découvrez les meilleurs médecins près de chez vous et prenez rendez-vous facilement",
            imageName: "heart.text.square.fill",
            color: .appSecondary,
            features: [
                "Recherche par spécialité",
                "Réservation instantanée",
                "Rappels automatiques"
            ]
        ),
        OnboardingPage(
            title: "Pharmacies 24h/24",
            subtitle: "Localisez rapidement les pharmacies ouvertes et de garde dans votre région",
            imageName: "cross.vial.fill",
            color: .appGreen,
            features: [
                "Pharmacies de garde",
                "Navigation GPS",
                "Horaires en temps réel"
            ]
        ),
        OnboardingPage(
            title: "Votre santé connectée",
            subtitle: "Gérez tous vos besoins médicaux depuis une seule application",
            imageName: "heart.circle.fill",
            color: .appPurple,
            features: [
                "Historique médical",
                "Notifications personnalisées",
                "Support 24/7"
            ]
        )
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: completeOnboarding) {
                        Text("Passer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .opacity(currentPage < onboardingPages.count - 1 ? 1 : 0)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: onboardingPages[index],
                            isLastPage: index == onboardingPages.count - 1,
                            animateElements: animateElements,
                            onGetStarted: completeOnboarding
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Custom page indicator
                CustomPageIndicator(
                    numberOfPages: onboardingPages.count,
                    currentPage: currentPage
                )
                .padding(.bottom, 30)

                // Continue button
                VStack(spacing: 20) {
                    if currentPage < onboardingPages.count - 1 {
                        Button(action: {
                            withAnimation(.spring()) {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Suivant")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [
                                        onboardingPages[currentPage].color,
                                        onboardingPages[currentPage].color.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(
                                color: onboardingPages[currentPage].color.opacity(0.3),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateElements = true
            }
        }
        .onChange(of: currentPage) { _ in
            animateElements = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateElements = true
                }
            }
        }
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        withAnimation(.spring()) {
            showMainApp = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
    let features: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let animateElements: Bool
    let onGetStarted: () -> Void

    @State private var imageScale: CGFloat = 0.5
    @State private var imageRotation: Double = -30
    @State private var showFeatures = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated icon
            ZStack {
                // Background circles
                ForEach(0..<3) { index in
                    Circle()
                        .fill(page.color.opacity(0.1 - Double(index) * 0.03))
                        .frame(
                            width: 200 + CGFloat(index * 50),
                            height: 200 + CGFloat(index * 50)
                        )
                        .scaleEffect(animateElements ? 1 : 0.5)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                            value: animateElements
                        )
                }

                // Main icon
                Image(systemName: page.imageName)
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(imageScale)
                    .rotationEffect(.degrees(imageRotation))
                    .shadow(color: page.color.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .frame(height: 250)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    imageScale = 1.0
                    imageRotation = 0
                }
            }

            // Title and subtitle
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)

                Text(page.subtitle)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
            }

            // Features list
            VStack(spacing: 15) {
                ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 15) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(page.color)

                        Text(feature)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .opacity(showFeatures ? 1 : 0)
                    .offset(x: showFeatures ? 0 : -50)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1),
                        value: showFeatures
                    )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showFeatures = true
                }
            }

            if isLastPage {
                Button(action: onGetStarted) {
                    HStack {
                        Text("Commencer")
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(
                        color: page.color.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                    .scaleEffect(animateElements ? 1 : 0.8)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring().delay(0.5), value: animateElements)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}

struct CustomPageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage ?
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appPrimary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: index == currentPage ? 30 : 10,
                        height: 10
                    )
                    .animation(.spring(), value: currentPage)
            }
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 1.0),
                    Color(red: 1.0, green: 0.95, blue: 0.95)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )

            // Floating orbs
            ForEach(0..<6) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                [Color.appPrimary, Color.appSecondary, Color.appGreen, Color.appPurple].randomElement()!.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : CGFloat.random(in: -200...200),
                        y: animate ? CGFloat.random(in: -400...400) : CGFloat.random(in: -400...400)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animate
                    )
            }

            // Overlay pattern
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    path.move(to: CGPoint(x: 0, y: height * 0.2))
                    path.addCurve(
                        to: CGPoint(x: width, y: height * 0.3),
                        control1: CGPoint(x: width * 0.3, y: height * 0.1),
                        control2: CGPoint(x: width * 0.7, y: height * 0.4)
                    )
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    OnboardingView()
}
