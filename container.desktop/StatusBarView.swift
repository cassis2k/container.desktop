//
//  StatusBarView.swift
//  container.desktop
//

import SwiftUI

struct StatusBarView: View {
    @State private var isContainerServiceRunning: Bool = false

    var body: some View {
        HStack {
            Circle()
                .fill(isContainerServiceRunning ? .green : .red)
                .frame(width: 8, height: 8)
            Text(isContainerServiceRunning ? "status.running" : "status.stopped")
                .font(.caption)
                .foregroundStyle(isContainerServiceRunning ? .green : .red)
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
        // Initial check
        await checkContainerServiceStatus()

        // Poll every 5 seconds - automatically cancelled when view disappears
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                await checkContainerServiceStatus()
            }
        }
    }

    private func checkContainerServiceStatus() async {
        let status = await ContainerService.fetchSystemStatus()
        isContainerServiceRunning = status.isRunning
    }
}

#Preview {
    StatusBarView()
}
