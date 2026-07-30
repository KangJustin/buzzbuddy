//
//  EmergencyContactStore.swift
//  buzzbuddy
//

import Foundation

/// Local-only, user-toggleable "emergency contact" flag. Not backend data --
/// purely a small UI convenience so the Contacts screen can show a real,
/// functional badge instead of a fabricated one, since no such flag exists on
/// `Contact` or anywhere server-side.
final class EmergencyContactStore: ObservableObject {
    private let defaultsKey = "buzzbuddy.emergencyContactIDs"
    private let defaults: UserDefaults

    @Published private(set) var emergencyContactIDs: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.emergencyContactIDs = Set(defaults.stringArray(forKey: defaultsKey) ?? [])
    }

    func isEmergencyContact(_ id: String) -> Bool {
        emergencyContactIDs.contains(id)
    }

    func toggle(_ id: String) {
        if emergencyContactIDs.contains(id) {
            emergencyContactIDs.remove(id)
        } else {
            emergencyContactIDs.insert(id)
        }
        defaults.set(Array(emergencyContactIDs), forKey: defaultsKey)
    }
}
