//
//  VolumesView.swift
//  container.desktop
//

import SwiftUI

struct VolumesView: View {
    // TODO: Implement volume listing when ContainerClient API is available

    var body: some View {
        ContentUnavailableView {
            Label("volumes.empty.title", systemImage: "externaldrive.badge.questionmark")
        } description: {
            Text("volumes.empty.description")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VolumesView()
}
