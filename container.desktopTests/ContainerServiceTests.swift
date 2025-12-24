//
//  ContainerServiceTests.swift
//  container.desktopTests
//

import XCTest
@testable import container_desktop

@MainActor
final class ContainerServiceTests: XCTestCase {

    // MARK: - isNewerVersion Tests

    func testIsNewerVersion_basicComparison() {
        XCTAssertTrue(ContainerService.isNewerVersion("0.8.0", than: "0.7.1"))
        XCTAssertFalse(ContainerService.isNewerVersion("0.7.0", than: "0.7.1"))
        XCTAssertFalse(ContainerService.isNewerVersion("1.0.0", than: "1.0.0"))
    }

    func testIsNewerVersion_handlesVPrefix() {
        XCTAssertTrue(ContainerService.isNewerVersion("v2.0.0", than: "v1.0.0"))
    }

    func testIsNewerVersion_emptyStrings_returnsFalse() {
        XCTAssertFalse(ContainerService.isNewerVersion("", than: "1.0.0"))
        XCTAssertFalse(ContainerService.isNewerVersion("1.0.0", than: ""))
    }

    // MARK: - extractVersion Tests

    func testExtractVersion_standardFormat_extractsCorrectly() {
        let line = "container-apiserver version 0.7.1 (build info)"
        XCTAssertEqual(ContainerService.extractVersion(from: line), "0.7.1")
    }

    func testExtractVersion_versionAtEnd_extractsCorrectly() {
        let line = "container-apiserver version 1.2.3"
        XCTAssertEqual(ContainerService.extractVersion(from: line), "1.2.3")
    }

    func testExtractVersion_noVersionKeyword_returnsEmpty() {
        let line = "some random text without the v-word info"
        XCTAssertEqual(ContainerService.extractVersion(from: line), "")
    }

    func testExtractVersion_emptyLine_returnsEmpty() {
        XCTAssertEqual(ContainerService.extractVersion(from: ""), "")
    }

    func testExtractVersion_versionWithExtraSpaces_extractsCorrectly() {
        let line = "container-apiserver version 2.0.0 extra info here"
        XCTAssertEqual(ContainerService.extractVersion(from: line), "2.0.0")
    }

    // MARK: - parseSystemStatus Tests

    func testParseSystemStatus_completeOutput_parsesCorrectly() {
        let output = """
        application data root: /var/lib/container
        application install root: /usr/local
        container-apiserver version: 0.7.1
        """

        let status = ContainerService.parseSystemStatus(from: output, isInstalled: true, isRunning: true)

        XCTAssertTrue(status.isInstalled)
        XCTAssertTrue(status.isRunning)
        XCTAssertEqual(status.dataRoot, "/var/lib/container")
        XCTAssertEqual(status.installRoot, "/usr/local")
    }

    func testParseSystemStatus_partialOutput_parsesAvailableFields() {
        let output = """
        application data root: /custom/path
        """

        let status = ContainerService.parseSystemStatus(from: output, isInstalled: true, isRunning: false)

        XCTAssertTrue(status.isInstalled)
        XCTAssertFalse(status.isRunning)
        XCTAssertEqual(status.dataRoot, "/custom/path")
        XCTAssertEqual(status.installRoot, "")
    }

    func testParseSystemStatus_emptyOutput_returnsDefaultValues() {
        let status = ContainerService.parseSystemStatus(from: "", isInstalled: false, isRunning: false)

        XCTAssertFalse(status.isInstalled)
        XCTAssertFalse(status.isRunning)
        XCTAssertEqual(status.dataRoot, "")
        XCTAssertEqual(status.installRoot, "")
        XCTAssertEqual(status.version, "")
    }

    func testParseSystemStatus_withExtraWhitespace_trimsCorrectly() {
        let output = """
        application data root:    /path/with/spaces
        application install root:   /another/path
        """

        let status = ContainerService.parseSystemStatus(from: output, isInstalled: true, isRunning: true)

        XCTAssertEqual(status.dataRoot, "/path/with/spaces")
        XCTAssertEqual(status.installRoot, "/another/path")
    }

    func testParseSystemStatus_preservesInstalledAndRunningFlags() {
        let status1 = ContainerService.parseSystemStatus(from: "", isInstalled: true, isRunning: false)
        XCTAssertTrue(status1.isInstalled)
        XCTAssertFalse(status1.isRunning)

        let status2 = ContainerService.parseSystemStatus(from: "", isInstalled: false, isRunning: true)
        XCTAssertFalse(status2.isInstalled)
        XCTAssertTrue(status2.isRunning)
    }
}
