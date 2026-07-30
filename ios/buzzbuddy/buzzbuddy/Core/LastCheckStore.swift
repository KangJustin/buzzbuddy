//
//  LastCheckStore.swift
//  buzzbuddy
//

import Foundation

/// Local-only record of the most recent check's outcome. `AppState`/
/// `Persistence` retain no history -- a session is discarded once the user
/// finishes -- so this is what powers HomeView's "last check" card, written
/// once from `VerdictView` when a check concludes.
struct LastCheck {
    let category: VerdictCategory
    let date: Date
}

final class LastCheckStore: ObservableObject {
    private let statusKey = "buzzbuddy.lastCheck.status"
    private let dateKey = "buzzbuddy.lastCheck.date"
    private let defaults: UserDefaults

    @Published private(set) var lastCheck: LastCheck?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let status = defaults.string(forKey: statusKey),
           let date = defaults.object(forKey: dateKey) as? Date {
            lastCheck = LastCheck(category: VerdictCategory(backendStatus: status), date: date)
        }
    }

    func record(backendStatus: String, date: Date = Date()) {
        defaults.set(backendStatus, forKey: statusKey)
        defaults.set(date, forKey: dateKey)
        lastCheck = LastCheck(category: VerdictCategory(backendStatus: backendStatus), date: date)
    }
}
