//
//  ServiceRow.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftUI

struct ServiceRow: View {
    let service: ServiceConfig
    let status: CheckStatus
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(status.state.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.system(size: 13))
                Text(status.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
