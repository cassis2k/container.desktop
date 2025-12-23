//
//  NetworkView.swift
//  container.desktop
//

import SwiftUI
import ContainerClient
internal import ContainerNetworkService

struct NetworkRow: Identifiable {
    let id: String
    let mode: String
    let subnet: String?
    let gateway: String?
    let state: String
    let createdAt: Date

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    init(from networkState: NetworkState) {
        self.id = networkState.id
        self.createdAt = networkState.creationDate
        self.state = networkState.state

        switch networkState {
        case .created(let config):
            self.mode = String(describing: config.mode)
            self.subnet = config.subnet
            self.gateway = nil
        case .running(let config, let status):
            self.mode = String(describing: config.mode)
            self.subnet = status.address
            self.gateway = status.gateway
        }
    }

    var formattedDate: String {
        Self.dateFormatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

struct NetworkCardView: View {
    let network: NetworkRow
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
                                colors: [Color.green.opacity(0.7), Color.teal.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "network")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(network.id)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(network.mode.uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(Color.blue)
                            .clipShape(Capsule())

                        Text(network.state)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(network.state == "running" ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundStyle(network.state == "running" ? Color.green : Color.orange)
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
                if let subnet = network.subnet {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("network.subnet")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(subnet)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                if let gateway = network.gateway {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("network.gateway")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(gateway)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("network.created")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(network.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

struct NetworkView: View {
    @State private var networks: [NetworkRow] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showingCreateSheet: Bool = false
    @State private var newNetworkName: String = ""
    @State private var isCreating: Bool = false

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
            } else if networks.isEmpty {
                emptyStateView
            } else {
                networkListView
            }
        }
        .task {
            await loadNetworks()
        }
        .sheet(isPresented: $showingCreateSheet) {
            createNetworkSheet
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("network.empty.title", systemImage: "wifi.slash")
        } description: {
            Text("network.empty.description")
        } actions: {
            Button(action: { showingCreateSheet = true }) {
                Text("network.empty.createButton")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var networkListView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(networks) { network in
                    NetworkCardView(
                        network: network,
                        onDelete: {
                            Task {
                                await deleteNetwork(network)
                            }
                        }
                    )
                }
            }
            .padding(20)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Label("network.create", systemImage: "plus")
                }
            }
        }
    }

    private var createNetworkSheet: some View {
        VStack(spacing: 20) {
            Text("network.create.title")
                .font(.headline)

            TextField("network.create.namePlaceholder", text: $newNetworkName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            HStack(spacing: 12) {
                Button("common.cancel") {
                    showingCreateSheet = false
                    newNetworkName = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("network.create.confirm") {
                    Task {
                        await createNetwork()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newNetworkName.isEmpty || isCreating)
            }
        }
        .padding(24)
    }

    private func loadNetworks() async {
        isLoading = true
        errorMessage = nil

        do {
            let clientNetworks = try await ClientNetwork.list()
            networks = clientNetworks.map { NetworkRow(from: $0) }
        } catch {
            errorMessage = error.localizedDescription
            networks = []
        }

        isLoading = false
    }

    private func createNetwork() async {
        guard !newNetworkName.isEmpty else { return }

        isCreating = true

        do {
            let config = try NetworkConfiguration(id: newNetworkName, mode: .nat)
            _ = try await ClientNetwork.create(configuration: config)

            showingCreateSheet = false
            newNetworkName = ""
            await loadNetworks()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }

    private func deleteNetwork(_ network: NetworkRow) async {
        do {
            try await ClientNetwork.delete(id: network.id)
            networks.removeAll { $0.id == network.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NetworkView()
}
