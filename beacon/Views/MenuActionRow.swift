//
//  MenuActionRow.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import SwiftUI

struct MenuActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .frame(width: 14)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundStyle(isHovering ? .white : .primary)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovering ? Color.accentColor : .clear)
            )
            .padding(.horizontal, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
