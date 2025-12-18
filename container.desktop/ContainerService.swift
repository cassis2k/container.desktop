//
//  ContainerService.swift
//  container.desktop
//

import Foundation
import os.log

private let logger = Logger(subsystem: "container.desktop", category: "ContainerService")

enum ContainerServiceError: LocalizedError {
    case commandNotFound
    case executionFailed(exitCode: Int32, message: String)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
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

struct ContainerService {
    static let containerPath = "/usr/local/bin/container"
    private static let githubReleasesURL = "https://api.github.com/repos/apple/container/releases/latest"

    // MARK: - Private Process Execution

    private static func executeProcess(arguments: [String]) async -> (output: String, exitCode: Int32) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: containerPath)
                process.arguments = arguments

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: (output, process.terminationStatus))
                } catch {
                    logger.error("Failed to execute process: \(error.localizedDescription)")
                    continuation.resume(returning: (error.localizedDescription, -1))
                }
            }
        }
    }

    // MARK: - System Status

    static func fetchSystemStatus() async -> SystemStatus {
        let (output, exitCode) = await executeProcess(arguments: ["system", "status"])

        guard exitCode == 0 else {
            return SystemStatus()
        }

        return parseSystemStatus(from: output, isRunning: true)
    }

    private static func parseSystemStatus(from output: String, isRunning: Bool) -> SystemStatus {
        var status = SystemStatus()
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

    private static func extractVersion(from line: String) -> String {
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

        let latestParts = latestClean.split(separator: ".").compactMap { Int($0) }
        let currentParts = currentClean.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let latestPart = i < latestParts.count ? latestParts[i] : 0
            let currentPart = i < currentParts.count ? currentParts[i] : 0

            if latestPart > currentPart {
                return true
            } else if latestPart < currentPart {
                return false
            }
        }
        return false
    }

    // MARK: - Logs

    static func fetchLogs() async -> Result<String, Error> {
        let (output, exitCode) = await executeProcess(arguments: ["system", "logs"])

        if exitCode >= 0 {
            return .success(output)
        } else {
            let error = NSError(
                domain: "ContainerService",
                code: Int(exitCode),
                userInfo: [NSLocalizedDescriptionKey: "Failed to execute container command"]
            )
            return .failure(error)
        }
    }

    // MARK: - Public Command Execution

    static func runCommand(arguments: [String]) async -> Result<String, Error> {
        let (output, exitCode) = await executeProcess(arguments: arguments)

        if exitCode == 0 {
            return .success(output)
        } else {
            let error = NSError(
                domain: "ContainerService",
                code: Int(exitCode),
                userInfo: [NSLocalizedDescriptionKey: output]
            )
            return .failure(error)
        }
    }
}
