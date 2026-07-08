//
//  GeneralSettingsView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("showStatusBadge") private var showStatusBadge = true

    var body: some View {
        Form {
            Section("Menu Bar") {
                Toggle("Show up/down counts on icon", isOn: $showStatusBadge)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}
