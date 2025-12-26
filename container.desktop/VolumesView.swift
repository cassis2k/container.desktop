//
//  VolumesView.swift
//  container.desktop
//

import SwiftUI
import ContainerClient

struct VolumeRow: Identifiable {
    let id: String
    let name: String
    let sizeInBytes: UInt64?
    let labels: [String: String]
    let isAnonymous: Bool

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    init(from volume: Volume) {
        self.id = volume.id
        self.name = volume.name
        self.sizeInBytes = volume.sizeInBytes
        self.labels = volume.labels
        self.isAnonymous = volume.isAnonymous
    }

    var formattedSize: String {
        guard let size = sizeInBytes else { return "-" }
        return Self.byteFormatter.string(fromByteCount: Int64(size))
    }
}

struct VolumeCardView: View {
    let volume: VolumeRow
    let onDelete: () -> Void
    @State private var isHovered = false
    @State private var isDeleteHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.7), Color.yellow.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(.headline)
                        .lineLimit(1)

                    if volume.isAnonymous {
                        Text("volumes.anonymous")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .foregroundStyle(Color.secondary)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

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

            Divider()

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("volumes.size")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(volume.formattedSize)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !volume.labels.filter({ $0.key != Volume.anonymousLabel }).isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(volume.labels.filter { $0.key != Volume.anonymousLabel }.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        Text("\(key)=\(value)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.15))
                            .foregroundStyle(Color.purple)
                            .clipShape(Capsule())
                    }
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

struct VolumesView: View {
    @State private var volumes: [VolumeRow] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showingCreateSheet: Bool = false
    @State private var newVolumeName: String = ""
    @State private var newVolumeLabels: [(key: String, value: String)] = []
    @State private var isCreating: Bool = false
    @State private var createError: String?
    @State private var volumeToDelete: VolumeRow?

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
            } else if volumes.isEmpty {
                emptyStateView
            } else {
                volumeListView
            }
        }
        .task {
            await loadVolumes()
        }
        .sheet(isPresented: $showingCreateSheet) {
            createVolumeSheet
        }
        .alert("volumes.delete.title", isPresented: .init(
            get: { volumeToDelete != nil },
            set: { if !$0 { volumeToDelete = nil } }
        )) {
            Button("common.cancel", role: .cancel) {
                volumeToDelete = nil
            }
            Button("volumes.delete.confirm", role: .destructive) {
                if let volume = volumeToDelete {
                    Task {
                        await deleteVolume(volume)
                    }
                }
                volumeToDelete = nil
            }
        } message: {
            if let volume = volumeToDelete {
                Text("volumes.delete.message \(volume.name)")
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("volumes.empty.title", systemImage: "externaldrive.badge.questionmark")
        } description: {
            Text("volumes.empty.description")
        } actions: {
            Button(action: { showingCreateSheet = true }) {
                Text("volumes.empty.createButton")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var volumeListView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(volumes) { volume in
                    VolumeCardView(
                        volume: volume,
                        onDelete: {
                            volumeToDelete = volume
                        }
                    )
                }
            }
            .padding(20)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Label("volumes.create", systemImage: "plus")
                }
            }
        }
    }

    private var createVolumeSheet: some View {
        VStack(spacing: 16) {
            Text("volumes.create.title")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("volumes.create.name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("volumes.create.namePlaceholder", text: $newVolumeName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("volumes.create.labels")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            newVolumeLabels.append((key: "", value: ""))
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }

                    if newVolumeLabels.isEmpty {
                        Text("volumes.create.labels.empty")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(newVolumeLabels.indices, id: \.self) { index in
                            HStack(spacing: 8) {
                                TextField("volumes.create.labels.key", text: Binding(
                                    get: { newVolumeLabels[index].key },
                                    set: { newVolumeLabels[index].key = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)

                                Text("=")
                                    .foregroundStyle(.secondary)

                                TextField("volumes.create.labels.value", text: Binding(
                                    get: { newVolumeLabels[index].value },
                                    set: { newVolumeLabels[index].value = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)

                                Button {
                                    newVolumeLabels.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .frame(width: 350)
            .onChange(of: newVolumeName) {
                createError = nil
            }

            if let error = createError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(width: 350, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button("common.cancel") {
                    showingCreateSheet = false
                    newVolumeName = ""
                    newVolumeLabels = []
                    createError = nil
                }
                .keyboardShortcut(.cancelAction)

                Button("volumes.create.confirm") {
                    Task {
                        await createVolume()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newVolumeName.isEmpty || isCreating)
            }
        }
        .padding(24)
    }

    @MainActor
    private func loadVolumes() async {
        isLoading = true
        errorMessage = nil

        do {
            let clientVolumes = try await ClientVolume.list()
            volumes = clientVolumes.map { VolumeRow(from: $0) }
        } catch {
            errorMessage = error.localizedDescription
            volumes = []
        }

        isLoading = false
    }

    @MainActor
    private func createVolume() async {
        guard !newVolumeName.isEmpty else { return }

        isCreating = true
        createError = nil

        do {
            let labels = newVolumeLabels
                .filter { !$0.key.isEmpty }
                .reduce(into: [String: String]()) { $0[$1.key] = $1.value }
            _ = try await ClientVolume.create(name: newVolumeName, labels: labels)

            showingCreateSheet = false
            newVolumeName = ""
            newVolumeLabels = []
            await loadVolumes()
        } catch {
            createError = error.localizedDescription
        }

        isCreating = false
    }

    @MainActor
    private func deleteVolume(_ volume: VolumeRow) async {
        do {
            try await ClientVolume.delete(name: volume.name)
            volumes.removeAll { $0.id == volume.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    VolumesView()
}
