//
//  ImagesView.swift
//  container.desktop
//

import SwiftUI
import ContainerClient
internal import ContainerizationOCI

struct ImageRow: Identifiable {
    let id: String
    let reference: String
    let registry: String
    let name: String
    let tag: String
    let digest: String
    var size: Int64?
    var createdAt: Date?

    /// System images are managed automatically and should not be modified by the user
    var isSystemImage: Bool {
        name == "vminit"
    }

    // Static formatters for better performance
    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(from clientImage: ClientImage) {
        self.id = clientImage.description.digest
        let reference = clientImage.description.reference
        self.reference = reference

        // Parse reference: registry/path/name:tag
        // Example: docker.io/library/alpine:latest
        let tagParts = reference.split(separator: ":")
        let fullPath = String(tagParts.first ?? Substring(reference))
        self.tag = tagParts.count > 1 ? String(tagParts.last!) : "latest"

        // Split path into components
        let pathComponents = fullPath.split(separator: "/")
        if pathComponents.count >= 2 {
            // First component is the registry
            self.registry = String(pathComponents[0])
            // Last component is the image name
            self.name = String(pathComponents.last!)
        } else {
            // No registry specified, assume docker.io
            self.registry = "docker.io"
            self.name = fullPath
        }

        self.digest = clientImage.description.digest
        self.size = nil
        self.createdAt = nil
    }

    var formattedSize: String {
        guard let size = size else { return "-" }
        return Self.byteFormatter.string(fromByteCount: size)
    }

    var formattedDate: String {
        guard let date = createdAt else { return "-" }
        return Self.dateFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Enriches the row with details from the client image
    mutating func enrichWithDetails(from clientImage: ClientImage) async {
        guard let details = try? await clientImage.details() else { return }

        // Find the arm64 variant or first available variant
        let variant = details.variants.first { $0.platform.architecture == "arm64" }
            ?? details.variants.first { $0.platform.architecture != "unknown" }

        guard let variant = variant else { return }

        self.size = variant.size

        if let created = variant.config.created {
            self.createdAt = Self.iso8601Formatter.date(from: created)
        }
    }
}

struct ImageCardView: View {
    let image: ImageRow
    let onDelete: () -> Void
    @SwiftUI.State private var isHovered = false
    @SwiftUI.State private var isDeleteHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Icon + Name + Tag badge + Delete button
            HStack(alignment: .top, spacing: 12) {
                // Image icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(image.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(image.registry)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Tag badge + Action buttons
                VStack(alignment: .trailing, spacing: 8) {
                    Text(image.tag)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundStyle(Color.secondary)
                        .clipShape(Capsule())

                    if image.isSystemImage {
                        // System badge for managed images
                        Label("images.system", systemImage: "gearshape.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(Color.orange)
                            .clipShape(Capsule())
                    } else {
                        // Delete button for user images
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(isDeleteHovered ? Color.red : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isDeleteHovered = hovering
                        }
                    }
                }
            }

            Divider()

            // Details grid
            HStack(spacing: 24) {
                // Digest
                VStack(alignment: .leading, spacing: 2) {
                    Text("images.digest")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(image.digest.replacingOccurrences(of: "sha256:", with: "").prefix(12))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Created
                VStack(alignment: .leading, spacing: 2) {
                    Text("images.created")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(image.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Size
                VStack(alignment: .trailing, spacing: 2) {
                    Text("images.size")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(image.formattedSize)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 8 : 4, y: isHovered ? 4 : 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(isHovered ? 0.1 : 0.05), lineWidth: 1)
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ImagesView: View {
    @SwiftUI.State private var images: [ImageRow] = []
    @SwiftUI.State private var isLoading: Bool = true
    @SwiftUI.State private var errorMessage: String?
    @SwiftUI.State private var imageToDelete: ImageRow?
    @SwiftUI.State private var showingPullSheet: Bool = false
    @SwiftUI.State private var pullImageReference: String = ""
    @SwiftUI.State private var isPulling: Bool = false
    @SwiftUI.State private var pullError: String?

    private let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 450), spacing: 16)
    ]

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView("common.error", systemImage: "exclamationmark.triangle", description: Text(error))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if images.isEmpty {
                ContentUnavailableView("images.empty.title", systemImage: "square.3.layers.3d.slash")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(images) { image in
                            ImageCardView(
                                image: image,
                                onDelete: {
                                    imageToDelete = image
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingPullSheet = true }) {
                    Label("images.pull", systemImage: "plus")
                }
            }
        }
        .task {
            await loadImages()
        }
        .sheet(isPresented: $showingPullSheet) {
            pullImageSheet
        }
        .alert("images.delete.title", isPresented: .init(
            get: { imageToDelete != nil },
            set: { if !$0 { imageToDelete = nil } }
        )) {
            Button("common.cancel", role: .cancel) {
                imageToDelete = nil
            }
            Button("images.delete.confirm", role: .destructive) {
                if let image = imageToDelete {
                    Task {
                        await deleteImage(image)
                    }
                }
                imageToDelete = nil
            }
        } message: {
            if let image = imageToDelete {
                Text("images.delete.message \(image.name)")
            }
        }
    }

    private func loadImages() async {
        isLoading = true
        errorMessage = nil

        do {
            let clientImages = try await ClientImage.list()
            var rows = clientImages.map { ImageRow(from: $0) }

            // Load details for each image to get size and creation date
            for (index, clientImage) in clientImages.enumerated() {
                await rows[index].enrichWithDetails(from: clientImage)
            }

            images = rows
        } catch {
            errorMessage = error.localizedDescription
            images = []
        }

        isLoading = false
    }

    private func deleteImage(_ image: ImageRow) async {
        do {
            try await ClientImage.delete(reference: image.reference)
            images.removeAll { $0.id == image.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var pullImageSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text("images.pull.title")
                    .font(.headline)
                Spacer()
                Button {
                    showingPullSheet = false
                    pullImageReference = ""
                    pullError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .frame(width: 350)

            VStack(alignment: .leading, spacing: 4) {
                Text("images.pull.reference")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("images.pull.placeholder", text: $pullImageReference)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 350)
            }
            .onChange(of: pullImageReference) {
                pullError = nil
            }

            if let error = pullError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(width: 350, alignment: .leading)
            }

            Button("images.pull.confirm") {
                Task {
                    await pullImage()
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(pullImageReference.isEmpty || isPulling)

            if isPulling {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(24)
    }

    @MainActor
    private func pullImage() async {
        guard !pullImageReference.isEmpty else { return }

        isPulling = true
        pullError = nil

        do {
            _ = try await ClientImage.pull(reference: pullImageReference)
            showingPullSheet = false
            pullImageReference = ""
            await loadImages()
        } catch {
            pullError = error.localizedDescription
        }

        isPulling = false
    }
}

#Preview {
    ImagesView()
}
