//
//  LogsView.swift
//  container.desktop
//

import OSLog
import SwiftUI

enum LogLevelFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case fault = "Fault"
    case error = "Error"
    case notice = "Notice"
    case info = "Info"
    case debug = "Debug"

    var id: String { rawValue }

    func matches(_ level: OSLogEntryLog.Level) -> Bool {
        switch self {
        case .all: return true
        case .debug: return level == .debug
        case .info: return level == .info
        case .notice: return level == .notice
        case .error: return level == .error
        case .fault: return level == .fault
        }
    }
}

enum LogTimePeriod: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 15
    case oneHour = 60
    case sixHours = 360
    case twentyFourHours = 1440
    case sevenDays = 10080

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fifteenMinutes: return "15 min"
        case .oneHour: return "1 hour"
        case .sixHours: return "6 hours"
        case .twentyFourHours: return "24 hours"
        case .sevenDays: return "7 days"
        }
    }

    var hours: Int {
        rawValue / 60
    }

    var minutes: Int {
        rawValue
    }
}

@Observable
final class LogsViewModel {
    var logEntries: [LogEntry] = []
    var isLoading: Bool = true
    var errorMessage: String?
    var selectedFilter: LogLevelFilter = .all
    var selectedPeriod: LogTimePeriod = .oneHour

    var filteredEntries: [LogEntry] {
        if selectedFilter == .all {
            return logEntries
        }
        return logEntries.filter { selectedFilter.matches($0.level) }
    }

    func loadLogs() async {
        isLoading = true
        errorMessage = nil

        let result = await ContainerService.fetchLogs(lastMinutes: selectedPeriod.minutes)

        switch result {
        case .success(let entries):
            logEntries = entries.sorted { $0.date > $1.date }
        case .failure(let error):
            errorMessage = error.localizedDescription
            logEntries = []
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
                Picker(selection: $viewModel.selectedPeriod) {
                    ForEach(LogTimePeriod.allCases) { period in
                        Text(period.label).tag(period)
                    }
                } label: {
                    EmptyView()
                }
                .frame(width: 100)
                .onChange(of: viewModel.selectedPeriod) {
                    Task {
                        await viewModel.loadLogs()
                    }
                }
                Spacer()
                Picker(selection: $viewModel.selectedFilter) {
                    ForEach(LogLevelFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 350)
                Text("\(viewModel.filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
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
            } else if viewModel.filteredEntries.isEmpty {
                ContentUnavailableView(
                    "logs.noLogs",
                    systemImage: "doc.text",
                    description: Text("logs.noLogsDescription")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredEntries) { entry in
                    LogEntryRow(entry: entry)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadLogs()
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    @State private var showCopiedFeedback = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                levelBadge
                Text(entry.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if showCopiedFeedback {
                    Text("logs.copied")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }
                if isHovered && !showCopiedFeedback {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .transition(.opacity)
                    .help(Text("logs.copyLine"))
                }
                Text(entry.date, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(entry.message)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func copyToClipboard() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.string(from: entry.date)
        let logLine = "[\(formattedDate)] [\(levelInfo.1)] [\(entry.category)] \(entry.message)"

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logLine, forType: .string)

        withAnimation {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }

    @ViewBuilder
    private var levelBadge: some View {
        let (color, label) = levelInfo
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var levelInfo: (Color, String) {
        switch entry.level {
        case .debug:
            return (.gray, "DEBUG")
        case .info:
            return (.blue, "INFO")
        case .notice:
            return (.green, "NOTICE")
        case .error:
            return (.orange, "ERROR")
        case .fault:
            return (.red, "FAULT")
        @unknown default:
            return (.gray, "LOG")
        }
    }
}

#Preview {
    LogsView()
}
