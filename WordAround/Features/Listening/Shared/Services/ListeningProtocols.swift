import Foundation

protocol ListeningSessionStoring {
    func fetchSavedSessions() async -> [ListeningSavedSession]
}
