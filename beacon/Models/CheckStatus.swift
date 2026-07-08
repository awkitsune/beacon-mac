//
//  CheckStatus.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftUI

enum HealthState: Int, Comparable {
    case
        up = 0
    case
        down = 2
    case
        unknown = 1

    static func < (lhs: HealthState, rhs: HealthState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct CheckStatus {
    var state: HealthState = .unknown
    var message: String = "not checked yet"
    var lastChecked: Date? = nil
}

extension HealthState {
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .unknown: return .gray
        }
    }
}
