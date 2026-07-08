//
//  ServiceDetailForm.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import SwiftUI
import SwiftData

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
            var config = ["scope": scope, "owner": owner, "runnerName": runnerName, "tokenKeychainKey": tokenKeychainKey]
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
        draft.name != service.name ||
        draft.type != service.type ||
        draft.interval != service.interval ||
        draft.buildConfig() != service.config
    }

    var body: some View {
        Form {
            Section("Service") {
                TextField("Name", text: $draft.name)
                Picker("Type", selection: $draft.type) {
                    Text("HTTP").tag(CheckerType.http)
                    Text("TCP port").tag(CheckerType.tcp)
                    Text("GitHub runner").tag(CheckerType.githubRunner)
                }
                HStack {
                    Text("Check every")
                    TextField("", value: $draft.interval, format: .number)
                        .frame(width: 60)
                    Text("seconds")
                }
            }

            Section("Config") {
                switch draft.type {
                case .http:
                    TextField("URL", text: $draft.url)
                case .tcp:
                    TextField("Host", text: $draft.host)
                    TextField("Port", text: $draft.port)
                case .githubRunner:
                    Picker("Scope", selection: $draft.scope) {
                        Text("Repository").tag("repo")
                        Text("Organization").tag("org")
                    }
                    .pickerStyle(.segmented)
                    TextField(draft.scope == "org" ? "Organization" : "Owner (org/user)", text: $draft.owner)
                    if draft.scope == "repo" {
                        TextField("Repo", text: $draft.repo)
                    }
                    TextField("Runner name", text: $draft.runnerName)
                    TextField("Keychain key (label)", text: $draft.tokenKeychainKey)
                    SecureField("GitHub token", text: $githubToken)
                    Button("Save token to Keychain") {
                        saveToken()
                    }
                    .disabled(draft.tokenKeychainKey.isEmpty || githubToken.isEmpty)
                    githubTokenHelp
                }
            }

            Section {
                HStack {
                    Button("Revert") {
                        draft = ServiceDraft(from: service)
                    }
                    .disabled(!isDirty)
                    Spacer()
                    Button("Save") {
                        commit()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isDirty || draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(service.name.isEmpty ? "Untitled service" : service.name)
    }

    private var githubTokenHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Token setup")
                .font(.caption.weight(.semibold))
            Text(draft.scope == "org"
                 ? "Needs a PAT with admin:org scope (classic) or organization_self_hosted_runners: read (fine-grained)."
                 : "Needs a PAT with actions: read on this repo.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Paste it above and hit Save — it's written to Keychain under the label you set here, never stored in beacon's own data file.")
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
        guard !draft.tokenKeychainKey.isEmpty, !githubToken.isEmpty else { return }
        Keychain.write(key: draft.tokenKeychainKey, value: githubToken)
        githubToken = ""
    }
}
