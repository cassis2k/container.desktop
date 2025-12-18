# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build from command line
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop -configuration Debug build

# Build for release
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop -configuration Release build

# Clean build
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop clean
```

For development, open `container.desktop.xcodeproj` in Xcode and use Cmd+B to build, Cmd+R to run.

## Architecture

This is a macOS SwiftUI application for managing containers (Docker-style). The app uses:

- **SwiftUI** for the UI layer
- **NavigationSplitView** for the main sidebar/detail layout
- **ContainerClient** for communication with the container runtime

### Container Runtime

The application requires `container-apiserver` from [Apple's container project](https://github.com/apple/container) to be running. Communication between the app and the API server is done via **XPC** (Apple's Inter-Process Communication framework) using the `ContainerXPC` module.

Key dependencies:
- `ContainerClient` - Client library for interacting with container-apiserver
- `ContainerPersistence` - Settings and configuration storage
- `ContainerizationOCI` - OCI image and container specifications

### Key Components

- `container_desktopApp.swift` - App entry point
- `ContentView.swift` - Main navigation with sidebar sections (Containers, Images, Volumes, Network, Logs, Settings)
- `ContainerService.swift` - Centralized service for system status, version checking, and command execution
- `ImagesView.swift` - Container images management (list, pull, delete)
- `SettingsView.swift` - Application settings and configuration
- `LogsView.swift` - System logs display
- `StatusBarView.swift` - Service status indicator

### Build Settings

- Target: macOS 15.0+
- **Swift 6** with strict concurrency checking
- Hardened Runtime enabled (App Sandbox disabled for container runtime access)

### Localization

The app supports multiple languages using String Catalogs (`Localizable.xcstrings`):
- English (US) - Primary language
- French - Secondary language

To add a new language, open `Localizable.xcstrings` in Xcode and add translations.
