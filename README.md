# Container Desktop

A native macOS application for managing containers using Apple's [Container](https://github.com/apple/container) framework.

![macOS](https://img.shields.io/badge/macOS-26.1+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![Container](https://img.shields.io/badge/Apple%20Container-0.7.1+-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Vibe Coding Project

This application is developed using **vibe coding** methodology. The code is written by [Claude](https://claude.ai) (Anthropic's AI assistant) using [Claude Code](https://claude.ai/code), with human supervision by [@cassis2k](https://github.com/cassis2k).

Claude uses the [Cupertino MCP Server](https://github.com/pckernmcp/cupertino) to access Apple documentation, Swift Evolution proposals, and sample code during development.

## Overview

Container.desktop provides a graphical interface for managing containers on macOS, built on top of Apple's native containerization technology. It communicates with the `container-apiserver` daemon to manage images, containers, volumes, and networks.

## Features

- **Images Management**: List, pull, and delete container images
- **Containers**: View and manage running containers
- **Volumes**: Manage persistent storage volumes
- **Networks**: Configure container networking
- **Settings**: Configure container runtime settings (registry, DNS, kernel, etc.)

## Requirements

- macOS 26 or later
- [Apple Container](https://github.com/apple/container) **v0.7.1** or later installed and running
- Xcode 26 (for building from source)

> **Note**: The application automatically checks for new versions of Apple Container by querying the GitHub API. This helps you stay up to date with the latest features and security fixes.

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/cassis2k/container.desktop.git
cd container.desktop
```

2. Open the project in Xcode:
```bash
open container.desktop.xcodeproj
```

3. Build and run (Cmd+R)

### Command Line Build

```bash
# Debug build
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop -configuration Debug build

# Release build
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop -configuration Release build
```

## Architecture

### Key Components

| File | Description |
|------|-------------|
| `container_desktopApp.swift` | App entry point |
| `ContentView.swift` | Main navigation with sidebar layout |
| `ContainerService.swift` | Centralized service for system status and commands |
| `ImagesView.swift` | Container images management UI |
| `LogsView.swift` | System logs display |
| `SettingsView.swift` | Runtime configuration settings |
| `StatusBarView.swift` | Status bar component |

### Dependencies

- [ContainerClient](https://github.com/apple/container) - Apple's container management framework
- [ContainerizationOCI](https://github.com/apple/container) - OCI image handling

## Configuration

Settings are stored in `com.apple.container.defaults` UserDefaults domain. Available settings:

| Setting | Description |
|---------|-------------|
| `build.rosetta` | Use Rosetta for amd64 images on arm64 |
| `registry.domain` | Default container registry (default: docker.io) |
| `dns.domain` | Local DNS domain for containers |
| `image.builder` | Builder image reference |
| `image.init` | Initial filesystem image reference |
| `kernel.url` | Kernel file URL |
| `kernel.binaryPath` | Kernel binary path in archive |

## Development

### Project Structure

```
container.desktop/
├── container.desktop.xcodeproj/
├── container.desktop/
│   ├── container_desktopApp.swift
│   ├── ContentView.swift
│   ├── ContainerService.swift
│   ├── ImagesView.swift
│   ├── LogsView.swift
│   ├── SettingsView.swift
│   ├── StatusBarView.swift
│   └── Localizable.xcstrings
├── CLAUDE.md
└── README.md
```

### Build Settings

- **Target**: macOS 26.1+
- **Swift**: 6 with strict concurrency checking
- **Hardened Runtime**: Enabled (App Sandbox disabled for container runtime access)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Apple Container](https://github.com/apple/container) - The underlying container runtime
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Apple's declarative UI framework
- [Claude Code](https://claude.ai/code) - AI-powered coding assistant
- [Cupertino MCP Server](https://github.com/mihaelamj/cupertino) - MCP server for Apple documentation access
