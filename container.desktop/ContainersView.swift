//
//  ContainersView.swift
//  container.desktop
//

import SwiftUI

struct ContainersView: View {
    // TODO: Implement container listing when ContainerClient API is available

    var body: some View {
        ServiceStatusView {
            ContentUnavailableView {
                Label("containers.empty.title", systemImage: "shippingbox")
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContainersView()
}
