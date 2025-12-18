//
//  LogsView.swift
//  container.desktop
//

import SwiftUI

struct LogsView: View {
    @State private var logs: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("logs.title")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await loadLogs()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(Text("logs.refresh"))
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "common.error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if logs.isEmpty {
                ContentUnavailableView(
                    "logs.noLogs",
                    systemImage: "doc.text",
                    description: Text("logs.noLogsDescription")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(logs)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
            }
        }
        .task {
            await loadLogs()
        }
    }

    private func loadLogs() async {
        isLoading = true
        errorMessage = nil

        let result = await ContainerService.fetchLogs()

        switch result {
        case .success(let output):
            logs = output
        case .failure(let error):
            errorMessage = error.localizedDescription
            logs = ""
        }

        isLoading = false
    }
}

#Preview {
    LogsView()
}
