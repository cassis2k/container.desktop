//
//  NetworkView.swift
//  container.desktop
//

import SwiftUI
import ContainerClient
internal import ContainerNetworkService

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

struct NetworkRow: Identifiable {
    let id: String
    let mode: String
    let subnet: String?
    let gateway: String?
    let labels: [String: String]
    let state: String
    let isInUse: Bool

    init(from networkState: NetworkState) {
        self.id = networkState.id
        self.state = networkState.state

        switch networkState {
        case .created(let config):
            self.mode = String(describing: config.mode)
            self.subnet = config.subnet
            self.gateway = nil
            self.labels = config.labels
            self.isInUse = false
        case .running(let config, let status):
            self.mode = String(describing: config.mode)
            self.subnet = status.address
            self.gateway = status.gateway
            self.labels = config.labels
            self.isInUse = true
        }
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

                Text(network.isInUse ? "network.inUse" : "network.notInUse")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(network.isInUse ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    .foregroundStyle(network.isInUse ? Color.green : Color.secondary)
                    .clipShape(Capsule())
            }

            if !network.labels.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(network.labels.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
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

struct NetworkView: View {
    @State private var networks: [NetworkRow] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showingCreateSheet: Bool = false
    @State private var newNetworkName: String = ""
    @State private var newNetworkSubnet: String = ""
    @State private var newNetworkLabels: [(key: String, value: String)] = []
    @State private var isCreating: Bool = false
    @State private var createError: String?
    @State private var networkToDelete: NetworkRow?

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
        .alert("network.delete.title", isPresented: .init(
            get: { networkToDelete != nil },
            set: { if !$0 { networkToDelete = nil } }
        )) {
            Button("common.cancel", role: .cancel) {
                networkToDelete = nil
            }
            Button("network.delete.confirm", role: .destructive) {
                if let network = networkToDelete {
                    Task {
                        await deleteNetwork(network)
                    }
                }
                networkToDelete = nil
            }
        } message: {
            if let network = networkToDelete {
                Text("network.delete.message \(network.id)")
            }
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
                            networkToDelete = network
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
        VStack(spacing: 16) {
            HStack {
                Text("network.create.title")
                    .font(.headline)
                Spacer()
                Button {
                    showingCreateSheet = false
                    newNetworkName = ""
                    newNetworkSubnet = ""
                    newNetworkLabels = []
                    createError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .frame(width: 350)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("network.create.name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("network.create.namePlaceholder", text: $newNetworkName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("network.create.subnet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("network.create.subnetPlaceholder", text: $newNetworkSubnet)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("network.create.labels")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            newNetworkLabels.append((key: "", value: ""))
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }

                    if newNetworkLabels.isEmpty {
                        Text("network.create.labels.empty")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(newNetworkLabels.indices, id: \.self) { index in
                            HStack(spacing: 8) {
                                TextField("network.create.labels.key", text: Binding(
                                    get: { newNetworkLabels[index].key },
                                    set: { newNetworkLabels[index].key = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)

                                Text("=")
                                    .foregroundStyle(.secondary)

                                TextField("network.create.labels.value", text: Binding(
                                    get: { newNetworkLabels[index].value },
                                    set: { newNetworkLabels[index].value = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)

                                Button {
                                    newNetworkLabels.remove(at: index)
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
            .onChange(of: newNetworkName) {
                createError = nil
            }
            .onChange(of: newNetworkSubnet) {
                createError = nil
            }

            if let error = createError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(width: 350, alignment: .leading)
            }

            Button("network.create.confirm") {
                Task {
                    await createNetwork()
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(newNetworkName.isEmpty || isCreating)
        }
        .padding(24)
    }

    @MainActor
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

    @MainActor
    private func createNetwork() async {
        guard !newNetworkName.isEmpty else { return }

        isCreating = true
        createError = nil

        do {
            let subnet = newNetworkSubnet.isEmpty ? nil : newNetworkSubnet
            let labels = newNetworkLabels
                .filter { !$0.key.isEmpty }
                .reduce(into: [String: String]()) { $0[$1.key] = $1.value }
            let config = try NetworkConfiguration(id: newNetworkName, mode: .nat, subnet: subnet, labels: labels)
            _ = try await ClientNetwork.create(configuration: config)

            showingCreateSheet = false
            newNetworkName = ""
            newNetworkSubnet = ""
            newNetworkLabels = []
            await loadNetworks()
        } catch {
            createError = error.localizedDescription
        }

        isCreating = false
    }

    @MainActor
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
