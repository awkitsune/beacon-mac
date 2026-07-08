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
    let scheduler: CheckScheduler

    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceConfig.sortOrder) private var services: [ServiceConfig]
    @State private var selection: PreferencesSelection? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label(
                    String(
                        localized: "preferences.title",
                        defaultValue: "Preferences",
                    ),
                    systemImage: "gearshape"
                )
                .tag(PreferencesSelection.general)

                if !services.isEmpty {
                    Section(
                        String(
                            localized: "services.title",
                            defaultValue: "Services",
                        )
                    ) {
                        ForEach(services) { service in
                            Label(
                                service.name,
                                systemImage: icon(for: service.type)
                            )
                            .tag(PreferencesSelection.service(service.id))
                        }
                        .onMove(perform: moveServices)
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
                .help(
                    String(
                        localized: "labels.buttons.add-service",
                        defaultValue: "Add service",
                    )
                )

                Button(role: .destructive) {
                    deleteSelected()
                } label: {
                    Image(systemName: "trash")
                }
                .help(
                    String(
                        localized: "labels.buttons.delete-service",
                        defaultValue: "Delete service",
                    )
                )
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
    private var detailContent: some View {
        switch selection {
        case .general, .none:
            GeneralSettingsView(
                scheduler: scheduler,
                services: services,
                context: context
            )
        case .service(let id):
            if let service = services.first(where: { $0.id == id }) {
                ServiceDetailForm(service: service)
                    .id(service.id)
            } else {
                GeneralSettingsView(
                    scheduler: scheduler,
                    services: services,
                    context: context
                )
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
        let newSortOrder = (services.map(\.sortOrder).max() ?? -1) + 1
        let newService = ServiceConfig(
            name: String(
                localized: "placeholders.untitled-service",
                defaultValue: "Untitled service",
            ),
            type: .http,
            interval: 30,
            config: ["url": ""],
            sortOrder: newSortOrder
        )
        context.insert(newService)
        try? context.save()
        selection = .service(newService.id)
        scheduler.start(newService)
    }

    private func deleteSelected() {
        guard let id = selectedServiceID,
            let service = services.first(where: { $0.id == id })
        else { return }
        scheduler.stop(id: id)
        context.delete(service)
        try? context.save()
        selection = .general
    }

    private func moveServices(from source: IndexSet, to destination: Int) {
        var reordered = services
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, service) in reordered.enumerated() {
            service.sortOrder = index
        }
        try? context.save()
    }
}
