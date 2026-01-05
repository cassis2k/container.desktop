//
//  ServiceStatusView.swift
//  container.desktop
//

import AppKit
import SwiftUI

private let installURL = "https://github.com/apple/container/releases"

enum ServiceStatus: Equatable {
    case checking
    case notInstalled
    case stopped
    case running
}

struct ServiceStatusView<Content: View>: View {
    @State private var serviceStatus: ServiceStatus = .checking
    @State private var isStartingService: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            switch serviceStatus {
            case .checking:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .notInstalled:
                notInstalledView
            case .stopped:
                stoppedView
            case .running:
                content()
            }
        }
        .task {
            await checkServiceStatus()
        }
    }

    private var notInstalledView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.square")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
            Text("service.notInstalled.title")
                .font(.title)
                .frame(minWidth: 500)
            HStack(spacing: 8) {
                Text(installURL)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(installURL, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("copy.url")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stoppedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "power.circle")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
            Text("service.stopped.title")
                .font(.title)
                .frame(minWidth: 500)
            Button {
                Task {
                    await startService()
                }
            } label: {
                if isStartingService {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("service.stopped.action")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isStartingService)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func checkServiceStatus() async {
        let status = await ContainerService.fetchSystemStatus()

        if !status.isInstalled {
            serviceStatus = .notInstalled
        } else if status.isRunning {
            serviceStatus = .running
        } else {
            serviceStatus = .stopped
        }
    }

    @MainActor
    private func startService() async {
        isStartingService = true

        let result = await ContainerService.startService()

        switch result {
        case .success:
            // Wait a bit for the service to be fully ready
            try? await Task.sleep(for: .milliseconds(500))
            await checkServiceStatus()
        case .failure:
            // Still check status in case it started anyway
            await checkServiceStatus()
        }

        isStartingService = false
    }
}

#Preview("Running") {
    ServiceStatusView {
        Text("Content when service is running")
    }
}
