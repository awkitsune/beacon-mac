//
//  MenuHeaderView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftUI

struct MenuHeaderView: View {
    let lastUpdated: Date?
    let scheduler: CheckScheduler

    let onRefreshAll: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    String(
                        localized: "application.name",
                        defaultValue: "beacon",
                    )
                )
                .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 8) {
                    Text(badgeText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)

                }

            }
            Spacer()

            Button(action: onRefreshAll) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var badgeText: String {
        var parts: [String] = []
        parts.append(
            lastUpdated != nil
                ? Self.timeFormatter.string(from: lastUpdated!)
                : String(
                    localized: "message.services-not-updated",
                    defaultValue: "Not updated yet",
                )
        )
        if scheduler.upCount > 0 {
            parts.append(
                String(
                    localized: "services.count.up",
                    defaultValue: "up:\(scheduler.upCount)",
                )
            )
        }
        if scheduler.downCount > 0 {
            parts.append(
                String(
                    localized: "services.count.down",
                    defaultValue: "down:\(scheduler.downCount)",
                )
            )
        }
        return parts.joined(separator: "|")
    }
}
