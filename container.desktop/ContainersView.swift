//
//  ContainersView.swift
//  container.desktop
//

import SwiftUI

struct ContainersView: View {
    @State private var containers: [String] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView("common.error", systemImage: "exclamationmark.triangle", description: Text(error))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if containers.isEmpty {
                emptyStateView
            } else {
                Text("containers.title")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loadContainers()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("containers.empty.title", systemImage: "shippingbox")
        } description: {
            Text("containers.empty.description")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadContainers() async {
        isLoading = true
        errorMessage = nil

        // TODO: Load containers from ContainerClient when API is available
        try? await Task.sleep(for: .milliseconds(300))
        containers = []

        isLoading = false
    }
}

#Preview {
    ContainersView()
}
