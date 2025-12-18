# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS desktop application for managing Docker containers, built with SwiftUI and SwiftData. The app provides a native macOS interface to view and manage containers, images, volumes, and networks.

**Product Bundle ID**: `curiousasctivity.container-desktop`
**Development Team**: 7SSS3XF3SE
**Deployment Target**: macOS 26.1+
**Swift Version**: 5.0

## Build Commands

```bash
# Build the project
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop -configuration Debug build

# Build for release
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop -configuration Release build

# Clean build
xcodebuild -project container.desktop.xcodeproj -scheme container.desktop clean

# Run in Xcode (preferred)
open container.desktop.xcodeproj
```

## Architecture

### App Structure

The application follows a standard SwiftUI + SwiftData architecture:

- **`container_desktopApp.swift`**: Main app entry point with SwiftData ModelContainer setup
- **`ContentView.swift`**: Root view with NavigationSplitView showing sidebar navigation
- **`Item.swift`**: SwiftData model (currently a placeholder with timestamp)

### Navigation Structure

The app uses a NavigationSplitView with a sidebar for navigation between main sections:
- Conteneur (Containers)
- Images
- Volumes
- Network

Currently, only Conteneur and Images have placeholder detail views implemented. Volumes and Network sections fall through to the default case.

### Data Layer

SwiftData is configured with an in-memory or persistent ModelContainer. The schema currently includes only the `Item` model, which appears to be a template placeholder that will likely be replaced with actual Docker-related models (Container, Image, Volume, Network).

## Key Build Settings

- **App Sandbox**: Enabled
- **Hardened Runtime**: Enabled
- **User Selected Files**: Read-only access
- **Swift Concurrency**: Approachable concurrency enabled with MainActor default isolation
- **Code Signing**: Automatic, using Apple Development certificate

## Development Notes

### Language

The UI is currently in French ("Conteneur", "Images", "Volumes", "Network", "Sélectionnez un élément"). When adding new features, maintain consistency with the existing language choice or implement proper localization.

### SwiftData Models

The `Item` model is a template and should be replaced with actual domain models. Expected models based on the navigation structure:
- Container model
- Image model
- Volume model
- Network model

### Navigation Implementation

The detail view in `ContentView.swift` uses a switch statement on the selection state. When implementing new sections (Volumes, Network), add corresponding cases to the switch statement.
