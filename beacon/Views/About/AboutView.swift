//
//  AboutView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import SwiftUI

struct AboutView: View {
    private let repoURL = URL(
        string: String(
            localized: "about.github.link",
            defaultValue: "https://github.com/awkitsune/beacon-mac",
        )
    )!

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
            as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
            as? String
            ?? "beacon"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "—"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text(appName)
                .font(.system(size: 16, weight: .semibold))

            Text(
                String(
                    localized: "about.version",
                    defaultValue: "Version \(version) (\(build))",
                )
            )
            .font(.system(size: 11))
            .foregroundStyle(.secondary)

            Text(
                String(
                    localized: "about.description",
                    defaultValue: "beacon monitors your services.",
                )
            )
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Link(
                String(
                    localized: "about.github",
                    defaultValue: "View on GitHub",
                ),
                destination: repoURL
            )
            .font(.system(size: 11))
        }
        .padding(24)
        .frame(width: 260)
    }
}
