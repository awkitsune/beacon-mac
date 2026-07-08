//
//  ServiceDetailForm.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import SwiftData
import SwiftUI

private struct ServiceDraft: Equatable {
    var name: String
    var type: CheckerType
    var interval: Double
    var url: String
    var host: String
    var port: String
    var scope: String
    var owner: String
    var repo: String
    var runnerName: String
    var tokenKeychainKey: String

    init(from service: ServiceConfig) {
        name = service.name
        type = service.type
        interval = service.interval
        url = service.config["url"] ?? ""
        host = service.config["host"] ?? ""
        port = service.config["port"] ?? ""
        scope = service.config["scope"] ?? "repo"
        owner = service.config["owner"] ?? ""
        repo = service.config["repo"] ?? ""
        runnerName = service.config["runnerName"] ?? ""
        tokenKeychainKey = service.config["tokenKeychainKey"] ?? ""
    }

    func buildConfig() -> [String: String] {
        switch type {
        case .http:
            return ["url": url]
        case .tcp:
            return ["host": host, "port": port]
        case .githubRunner:
            var config = [
                "scope": scope, "owner": owner, "runnerName": runnerName,
                "tokenKeychainKey": tokenKeychainKey,
            ]
            if scope == "repo" { config["repo"] = repo }
            return config
        }
    }
}

struct ServiceDetailForm: View {
    let service: ServiceConfig
    @Environment(\.modelContext) private var context

    @State private var draft: ServiceDraft
    @State private var githubToken: String = ""

    init(service: ServiceConfig) {
        self.service = service
        _draft = State(initialValue: ServiceDraft(from: service))
    }

    private var isDirty: Bool {
        draft.name != service.name || draft.type != service.type
            || draft.interval != service.interval
            || draft.buildConfig() != service.config
    }

    private var isValid: Bool {
        guard draft.interval >= 1 else { return false }
        if draft.type == .tcp {
            guard let port = UInt16(draft.port), port > 0 else { return false }
        }
        return true
    }

    var body: some View {
        Form {
            Section(
                String(
                    localized: "forms.service.title",
                    defaultValue: "Service",
                )
            ) {
                TextField(
                    String(
                        localized: "forms.service.name",
                        defaultValue: "Name",
                    ),
                    text: $draft.name
                )
                Picker(
                    String(
                        localized: "forms.service.type",
                        defaultValue: "Type",
                    ),
                    selection: $draft.type
                ) {
                    Text(
                        String(
                            localized: "forms.service.http",
                            defaultValue: "HTTP",
                        ),
                    ).tag(CheckerType.http)
                    Text(
                        String(
                            localized: "forms.service.tcp-port",
                            defaultValue: "TCP port",
                        )
                    ).tag(CheckerType.tcp)
                    Text(
                        String(
                            localized: "forms.service.gh-runner",
                            defaultValue: "GitHub runner",
                        )
                    ).tag(CheckerType.githubRunner)
                }
                HStack {
                    Text(
                        String(
                            localized: "forms.service.check-every",
                            defaultValue: "Check every",
                        )
                    )
                    TextField("", value: $draft.interval, format: .number)
                    Text(intervalUnitText)
                }
            }

            Section(
                String(
                    localized: "forms.service-config.title",
                    defaultValue: "Config",
                )
            ) {
                switch draft.type {
                case .http:
                    TextField(
                        String(
                            localized: "forms.service-config.url",
                            defaultValue: "URL",
                        ),
                        text: $draft.url
                    )
                case .tcp:
                    TextField(
                        String(
                            localized: "forms.service-config.host",
                            defaultValue: "Host",
                        ),
                        text: $draft.host
                    )
                    TextField(
                        String(
                            localized: "forms.service-config.port",
                            defaultValue: "Port",
                        ),
                        text: $draft.port
                    )
                case .githubRunner:
                    Picker(
                        String(
                            localized: "forms.service-config.scope",
                            defaultValue: "Scope",
                        ),
                        selection: $draft.scope
                    ) {
                        Text(
                            String(
                                localized: "forms.service-config.repo",
                                defaultValue: "Repository",
                            )
                        ).tag("repo")
                        Text(
                            String(
                                localized: "forms.service-config.org",
                                defaultValue: "Organization",
                            )
                        ).tag("org")
                    }
                    .pickerStyle(.segmented)
                    TextField(
                        draft.scope == "org"
                            ? String(
                                localized: "forms.service-config.org",
                                defaultValue: "Organization",
                            )
                            : String(
                                localized: "forms.service-config.owner",
                                defaultValue: "Owner (org/user)",
                            ),
                        text: $draft.owner
                    )
                    if draft.scope == "repo" {
                        TextField(
                            String(
                                localized: "forms.service-config.repo",
                                defaultValue: "Repository",
                            ),
                            text: $draft.repo
                        )
                    }
                    TextField(
                        String(
                            localized: "forms.service-config.runner-name",
                            defaultValue: "Runner name",
                        ),
                        text: $draft.runnerName
                    )
                    TextField(
                        String(
                            localized: "forms.service-config.keychain-key",
                            defaultValue: "Keychain key (label)",
                        ),
                        text: $draft.tokenKeychainKey
                    )
                    SecureField(
                        String(
                            localized: "forms.service-config.gh-token",
                            defaultValue: "GitHub token",
                        ),
                        text: $githubToken
                    )
                    Button(
                        String(
                            localized: "labels.buttons.save-token-keychain",
                            defaultValue: "Save token to Keychain",
                        )
                    ) {
                        saveToken()
                    }
                    .disabled(
                        draft.tokenKeychainKey.isEmpty || githubToken.isEmpty
                    )
                    githubTokenHelp
                }
            }

            Section {
                HStack {
                    Button(
                        String(
                            localized: "labels.buttons.revert",
                            defaultValue: "Revert",
                        )
                    ) {
                        draft = ServiceDraft(from: service)
                    }
                    .disabled(!isDirty)
                    Spacer()
                    Button(
                        String(
                            localized: "labels.buttons.save",
                            defaultValue: "Save",
                        )
                    ) {
                        commit()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        !isDirty
                            || draft.name.trimmingCharacters(in: .whitespaces)
                                .isEmpty
                            || !isValid
                    )
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(
            service.name.isEmpty
                ? String(
                    localized: "placeholders.untitled-service",
                    defaultValue: "Untitled service",
                ) : service.name
        )
    }

    private var intervalUnitText: String {
        let format = String(
            localized: "forms.service.interval-unit",
            defaultValue: "%lld seconds"
        )
        let formatted = String.localizedStringWithFormat(
            format,
            Int(draft.interval)
        )
        return formatted.drop { $0.isNumber }
            .trimmingCharacters(in: .whitespaces)
    }

    private var githubTokenHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                String(
                    localized: "info.token-setup.label",
                    defaultValue: "Token setup",
                )
            )
            .font(.caption.weight(.semibold))
            Text(
                draft.scope == "org"
                    ? String(
                        localized: "info.token-setup.org",
                        defaultValue:
                            "Needs a Personal access token with admin:org scope (classic) or organization_self_hosted_runners: read (fine-grained).",
                    )
                    : String(
                        localized: "info.token-setup.repo",
                        defaultValue:
                            "Needs a Personal access token with actions: read on this repo.",
                    )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(
                String(
                    localized: "info.token-setup.store-policy",
                    defaultValue:
                        "Paste it above and hit Save — it's written to Keychain under the label you set here, never stored in beacon's own data files."
                )

            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func commit() {
        service.name = draft.name
        service.type = draft.type
        service.interval = draft.interval
        service.config = draft.buildConfig()
        try? context.save()
    }

    private func saveToken() {
        guard !draft.tokenKeychainKey.isEmpty, !githubToken.isEmpty else {
            return
        }
        Keychain.write(key: draft.tokenKeychainKey, value: githubToken)
        githubToken = ""
    }
}
