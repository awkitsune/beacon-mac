//
//  PreferencesView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftData
import SwiftUI

enum PreferencesSelection: Hashable {
    case general
    case service(String)
}

struct PreferencesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceConfig.name) private var services: [ServiceConfig]
    @State private var selection: PreferencesSelection? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("General", systemImage: "gearshape")
                    .tag(PreferencesSelection.general)

                if !services.isEmpty {
                    Section("Services") {
                        ForEach(services) { service in
                            Label(
                                service.name,
                                systemImage: icon(for: service.type)
                            )
                            .tag(PreferencesSelection.service(service.id))
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        } detail: {
            detailContent
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    addNewService()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add service")

                Button(role: .destructive) {
                    deleteSelected()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete service")
                .disabled(selection == nil)
            }
        }
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        if services.isEmpty {
            ContentUnavailableView(
                "No services",
                systemImage: "server.rack",
                description: Text("Click + to add one.")
            )
        } else {
            List(services, selection: $selection) { service in
                Label(service.name, systemImage: icon(for: service.type))
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .general, .none:
            GeneralSettingsView()
        case .service(let id):
            if let service = services.first(where: { $0.id == id }) {
                ServiceDetailForm(service: service)
                    .id(service.id)
            } else {
                GeneralSettingsView()
            }
        }
    }

    private func icon(for type: CheckerType) -> String {
        switch type {
        case .http: return "globe"
        case .tcp: return "network"
        case .githubRunner: return "gearshape.2"
        }
    }

    private var selectedServiceID: String? {
        if case .service(let id) = selection { return id }
        return nil
    }

    private func addNewService() {
        let newService = ServiceConfig(
            name: "New service",
            type: .http,
            interval: 30,
            config: ["url": ""]
        )
        context.insert(newService)
        try? context.save()
        selection = .service(newService.id)
    }

    private func deleteSelected() {
        guard let id = selectedServiceID,
            let service = services.first(where: { $0.id == id })
        else { return }
        context.delete(service)
        try? context.save()
        selection = .general
    }
}
