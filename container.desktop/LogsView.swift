//
//  LogsView.swift
//  container.desktop
//

import SwiftUI

@Observable
final class LogsViewModel {
    var logs: String = ""
    var isLoading: Bool = true
    var errorMessage: String?

    func loadLogs() async {
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

struct LogsView: View {
    @State private var viewModel = LogsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("logs.title")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await viewModel.loadLogs()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(Text("logs.refresh"))
            }
            .padding()

            Divider()

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "common.error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.logs.isEmpty {
                ContentUnavailableView(
                    "logs.noLogs",
                    systemImage: "doc.text",
                    description: Text("logs.noLogsDescription")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(viewModel.logs)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
            }
        }
        .task {
            await viewModel.loadLogs()
        }
    }
}

#Preview {
    LogsView()
}
