//
//  ContainerService.swift
//  container.desktop
//

import Foundation

struct SystemStatus {
    var isRunning: Bool = false
    var version: String = ""
    var dataRoot: String = ""
    var installRoot: String = ""
}

struct ContainerService {
    static let containerPath = "/usr/local/bin/container"
    private static let githubReleasesURL = "https://api.github.com/repos/apple/container/releases/latest"

    // MARK: - System Status

    static func fetchSystemStatus() async -> SystemStatus {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var status = SystemStatus()

                let process = Process()
                process.executableURL = URL(fileURLWithPath: containerPath)
                process.arguments = ["system", "status"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    status.isRunning = process.terminationStatus == 0

                    if status.isRunning {
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        if let output = String(data: data, encoding: .utf8) {
                            status = parseSystemStatus(from: output, isRunning: true)
                        }
                    }
                } catch {
                    status.isRunning = false
                }

                continuation.resume(returning: status)
            }
        }
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

    static func checkForUpdates() async -> (latestVersion: String, updateAvailable: Bool, currentVersion: String) {
        let status = await fetchSystemStatus()
        let currentVersion = status.version

        guard let url = URL(string: githubReleasesURL) else {
            return ("", false, currentVersion)
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tagName = json["tag_name"] as? String {
                let latestVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                let updateAvailable = isNewerVersion(latestVersion, than: currentVersion)
                return (latestVersion, updateAvailable, currentVersion)
            }
        } catch {
            // Log error in production
        }

        return ("", false, currentVersion)
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
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: containerPath)
                process.arguments = ["system", "logs"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: .success(output))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - Process Execution Helper

    static func runCommand(arguments: [String]) async -> Result<String, Error> {
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

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: .success(output))
                    } else {
                        let error = NSError(
                            domain: "ContainerService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: output]
                        )
                        continuation.resume(returning: .failure(error))
                    }
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
