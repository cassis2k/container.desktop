//
//  VolumesView.swift
//  container.desktop
//

import SwiftUI

struct VolumesView: View {
    @State private var volumes: [String] = []
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
            } else if volumes.isEmpty {
                emptyStateView
            } else {
                Text("volumes.title")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loadVolumes()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("volumes.empty.title", systemImage: "externaldrive.badge.questionmark")
        } description: {
            Text("volumes.empty.description")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadVolumes() async {
        isLoading = true
        errorMessage = nil

        // TODO: Load volumes from ContainerClient when API is available
        try? await Task.sleep(for: .milliseconds(300))
        volumes = []

        isLoading = false
    }
}

#Preview {
    VolumesView()
}
