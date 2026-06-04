import SwiftUI
import GoogleSignIn

@main
struct WordAroundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var preferences = UserPreferencesStore.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                rootView
            }
            .environmentObject(sessionStore)
            .environmentObject(preferences)
            .preferredColorScheme(preferences.theme.colorScheme)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .task {
                await sessionStore.refreshAuthState()
                await NotificationService.shared.sync(with: preferences)
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else {
            switch sessionStore.state {
            case .loading:
                ProgressView()
                    .tint(.blue)
            case .loggedOut:
                AuthView()
            case .emailVerificationRequired:
                VerifyEmailView()
            case .authenticated:
                HomeView()
            }
        }
    }
}
