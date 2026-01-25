//
//  NoteAccessManager.swift
//  HeartLog
//
//  Created by Claude Code on 1/25/26.
//

import Foundation
import SwiftUI

@MainActor
class NoteAccessManager: ObservableObject {
    static let shared = NoteAccessManager()

    @Published private(set) var characterLimit: Int?
    @Published private(set) var hasUnlimitedNotes: Bool = false

    private let freeUserLimit = 200
    private let limitIntroducedVersion = "1.1"

    private init() {}

    func updateAccess(isPremium: Bool) {
        hasUnlimitedNotes = isPremium || isGrandfathered()
        characterLimit = hasUnlimitedNotes ? nil : freeUserLimit
    }

    func canSaveNote(withLength length: Int) -> Bool {
        guard let limit = characterLimit else { return true }
        return length <= limit
    }

    func remainingCharacters(for text: String) -> Int {
        guard let limit = characterLimit else { return Int.max }
        return max(0, limit - text.count)
    }

    private func isGrandfathered() -> Bool {
        let firstInstall = UserDefaults.standard.string(forKey: "firstInstallVersion")

        // No version recorded = upgraded from pre-tracking = grandfathered
        if firstInstall == nil {
            return true
        }

        // Installed before 1.1 = grandfathered
        if compareVersions(firstInstall!, limitIntroducedVersion) == .orderedAscending {
            return true
        }

        return false
    }

    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        return v1.compare(v2, options: .numeric)
    }
}
