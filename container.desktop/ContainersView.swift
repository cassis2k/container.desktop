//
//  ContainersView.swift
//  container.desktop
//

import SwiftUI

struct ContainersView: View {
    // TODO: Implement container listing when ContainerClient API is available

    var body: some View {
        ContentUnavailableView {
            Label("containers.empty.title", systemImage: "shippingbox")
        } description: {
            Text("containers.empty.description")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContainersView()
}
