import SwiftUI
import GoogleSignIn

@main
struct WordAroundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                rootView
            }
            .environmentObject(sessionStore)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .task {
                await sessionStore.refreshAuthState()
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
