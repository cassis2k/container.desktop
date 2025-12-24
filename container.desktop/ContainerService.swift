//
//  ContainerService.swift
//  container.desktop
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "container.desktop", category: "ContainerService")

enum ContainerServiceError: LocalizedError {
    case serviceNotInstalled
    case commandNotFound
    case executionFailed(exitCode: Int32, message: String)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serviceNotInstalled:
            return String(localized: "error.serviceNotInstalled")
        case .commandNotFound:
            return String(localized: "error.commandNotFound")
        case .executionFailed(let exitCode, let message):
            return String(localized: "error.executionFailed \(exitCode) \(message)")
        case .networkError(let error):
            return String(localized: "error.networkError \(error.localizedDescription)")
        case .invalidResponse:
            return String(localized: "error.invalidResponse")
        }
    }
}

struct SystemStatus {
    var isInstalled: Bool = false
    var isRunning: Bool = false
    var version: String = ""
    var dataRoot: String = ""
    var installRoot: String = ""
}

struct UpdateInfo {
    let latestVersion: String
    let updateAvailable: Bool
    let currentVersion: String
}

struct LogEntry: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let level: OSLogEntryLog.Level
    let category: String
    let message: String

    nonisolated init(from entry: OSLogEntryLog) {
        self.id = UUID()
        self.date = entry.date
        self.level = entry.level
        self.category = entry.category
        self.message = entry.composedMessage
    }
}

struct ContainerService {
    static let containerPath = "/usr/local/bin/container"
    private static let githubReleasesURL = "https://api.github.com/repos/apple/container/releases/latest"

    // MARK: - Installation Check

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: containerPath)
    }

    // MARK: - Private Process Execution

    private static func executeProcess(arguments: [String]) async -> Result<(output: String, exitCode: Int32), ContainerServiceError> {
        guard isInstalled else {
            logger.warning("Container CLI not found at \(containerPath)")
            return .failure(.serviceNotInstalled)
        }

        // Capture values for use in detached task
        let executablePath = containerPath
        let taskLogger = logger

        return await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                return .success((output, process.terminationStatus))
            } catch {
                taskLogger.error("Failed to execute process: \(error.localizedDescription)")
                return .failure(.executionFailed(exitCode: -1, message: error.localizedDescription))
            }
        }.value
    }

    // MARK: - System Status

    static func fetchSystemStatus() async -> SystemStatus {
        guard isInstalled else {
            return SystemStatus(isInstalled: false)
        }

        let result = await executeProcess(arguments: ["system", "status"])

        switch result {
        case .success(let (output, exitCode)):
            guard exitCode == 0 else {
                return SystemStatus(isInstalled: true, isRunning: false)
            }
            return parseSystemStatus(from: output, isInstalled: true, isRunning: true)
        case .failure:
            return SystemStatus(isInstalled: true, isRunning: false)
        }
    }

    static func parseSystemStatus(from output: String, isInstalled: Bool, isRunning: Bool) -> SystemStatus {
        var status = SystemStatus()
        status.isInstalled = isInstalled
        status.isRunning = isRunning

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("application data root:") {
                status.dataRoot = line
                    .replacingOccurrences(of: "application data root:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("application install root:") {
                status.installRoot = line
                    .replacingOccurrences(of: "application install root:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if line.contains("container-apiserver version:") {
                status.version = extractVersion(from: line)
            }
        }

        return status
    }

    static func extractVersion(from line: String) -> String {
        if let range = line.range(of: "version ") {
            let afterVersion = line[range.upperBound...]
            if let spaceIndex = afterVersion.firstIndex(of: " ") {
                return String(afterVersion[..<spaceIndex])
            } else {
                return String(afterVersion)
            }
        }
        return ""
    }

    // MARK: - Version Checking

    static func checkForUpdates() async -> Result<UpdateInfo, ContainerServiceError> {
        let status = await fetchSystemStatus()
        let currentVersion = status.version

        guard let url = URL(string: githubReleasesURL) else {
            logger.error("Invalid GitHub releases URL")
            return .failure(.invalidResponse)
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                logger.error("Invalid JSON response from GitHub API")
                return .failure(.invalidResponse)
            }

            let latestVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            let updateAvailable = isNewerVersion(latestVersion, than: currentVersion)

            return .success(UpdateInfo(
                latestVersion: latestVersion,
                updateAvailable: updateAvailable,
                currentVersion: currentVersion
            ))
        } catch {
            logger.error("Network error while checking for updates: \(error.localizedDescription)")
            return .failure(.networkError(error))
        }
    }

    static func isNewerVersion(_ latest: String, than current: String) -> Bool {
        guard !current.isEmpty, !latest.isEmpty else { return false }
        let latestClean = latest.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        let currentClean = current.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        return latestClean.compare(currentClean, options: .numeric) == .orderedDescending
    }

    // MARK: - Logs

    static func fetchLogs(lastMinutes: Int = 60, limit: Int = 1000) async -> Result<[LogEntry], ContainerServiceError> {
        await Task.detached(priority: .userInitiated) {
            do {
                let store = try OSLogStore(scope: .system)
                let startDate = Date().addingTimeInterval(-Double(lastMinutes * 60))
                let position = store.position(date: startDate)
                let predicate = NSPredicate(format: "subsystem == 'com.apple.container'")

                let entries = try store.getEntries(at: position, matching: predicate)
                var logEntries: [LogEntry] = []
                logEntries.reserveCapacity(limit)

                for entry in entries {
                    guard let logEntry = entry as? OSLogEntryLog else { continue }
                    logEntries.append(LogEntry(from: logEntry))
                    if logEntries.count >= limit { break }
                }

                return .success(logEntries)
            } catch {
                return .failure(.executionFailed(exitCode: -1, message: error.localizedDescription))
            }
        }.value
    }

    // MARK: - Public Command Execution

    static func runCommand(arguments: [String]) async -> Result<String, ContainerServiceError> {
        let result = await executeProcess(arguments: arguments)

        switch result {
        case .success(let (output, exitCode)):
            if exitCode == 0 {
                return .success(output)
            } else {
                return .failure(.executionFailed(exitCode: exitCode, message: output))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
