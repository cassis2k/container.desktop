//
//  StatusBarView.swift
//  container.desktop
//

import SwiftUI

enum ServiceState {
    case notInstalled
    case stopped
    case running

    var color: Color {
        switch self {
        case .notInstalled: return .orange
        case .stopped: return .red
        case .running: return .green
        }
    }

    var labelKey: LocalizedStringKey {
        switch self {
        case .notInstalled: return "status.notInstalled"
        case .stopped: return "status.stopped"
        case .running: return "status.running"
        }
    }
}

struct StatusBarView: View {
    @State private var serviceState: ServiceState = .stopped

    var body: some View {
        HStack {
            Circle()
                .fill(serviceState.color)
                .frame(width: 8, height: 8)
            Text(serviceState.labelKey)
                .font(.caption)
                .foregroundStyle(serviceState.color)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
        .task {
            await pollContainerServiceStatus()
        }
    }

    private func pollContainerServiceStatus() async {
        await checkContainerServiceStatus()

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                await checkContainerServiceStatus()
            }
        }
    }

    private func checkContainerServiceStatus() async {
        let status = await ContainerService.fetchSystemStatus()

        if !status.isInstalled {
            serviceState = .notInstalled
        } else if status.isRunning {
            serviceState = .running
        } else {
            serviceState = .stopped
        }
    }
}

#Preview {
    StatusBarView()
}
