//
//  SettingsView.swift
//  container.desktop
//
//  Created by Claude on 14/12/2025.
//

import SwiftUI
import ContainerPersistence

struct EditableSettingRow: View {
    let title: LocalizedStringKey
    let titleKey: String
    let description: LocalizedStringKey
    let placeholder: String
    @Binding var value: String
    var onSave: (String) -> Void

    @State private var isEditing = false
    @State private var editedValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3)
                Spacer()
                Text(value.isEmpty ? String(localized: "settings.notDefined") : value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .italic(value.isEmpty)
            }
            .padding(.vertical, 10)

            Divider()

            HStack {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button("settings.edit") {
                    editedValue = value.isEmpty ? "" : value
                    isEditing = true
                }
                .font(.subheadline)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $isEditing) {
            VStack(spacing: 20) {
                Text("settings.edit.title \(String(localized: String.LocalizationValue(titleKey)))")
                    .font(.title2)

                TextField(placeholder, text: $editedValue)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .frame(minWidth: 350)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 350)

                HStack {
                    Button("common.cancel") {
                        isEditing = false
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("common.ok") {
                        value = editedValue
                        onSave(editedValue)
                        isEditing = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
        }
    }
}

struct SettingRow<Content: View>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let content: () -> Content

    init(title: LocalizedStringKey, description: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3)
                Spacer()
                content()
            }
            .padding(.vertical, 10)

            Divider()

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 10)
        }
    }
}

struct SettingsView: View {
    @State private var buildRosetta: Bool = true
    @State private var dnsDomain: String = ""
    @State private var imageBuilder: String = ""
    @State private var imageInit: String = ""
    @State private var kernelBinaryPath: String = ""
    @State private var kernelURL: String = ""
    @State private var registryDomain: String = ""

    @State private var appVersion: String = ""
    @State private var appDataRoot: String = ""
    @State private var appInstallRoot: String = ""
    @State private var latestVersion: String = ""
    @State private var updateAvailable: Bool = false

    var body: some View {
        Form {
            Section("settings.section.application") {
                SettingRow(
                    title: "settings.version",
                    description: updateAvailable
                        ? "settings.version.updateAvailable \(latestVersion)"
                        : "settings.version.description"
                ) {
                    HStack(spacing: 6) {
                        Text(appVersion)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                        if updateAvailable {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                SettingRow(
                    title: "settings.dataRoot",
                    description: "settings.dataRoot.description"
                ) {
                    Text(appDataRoot)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                SettingRow(
                    title: "settings.installRoot",
                    description: "settings.installRoot.description"
                ) {
                    Text(appInstallRoot)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Section("settings.section.build") {
                SettingRow(
                    title: "settings.rosetta",
                    description: "settings.rosetta.description"
                ) {
                    Toggle("", isOn: $buildRosetta)
                        .labelsHidden()
                        .onChange(of: buildRosetta) { _, newValue in
                            saveBoolProperty(key: .buildRosetta, value: newValue)
                        }
                }
            }

            Section("settings.section.registry") {
                EditableSettingRow(
                    title: "settings.registry.domain",
                    titleKey: "settings.registry.domain",
                    description: "settings.registry.domain.description",
                    placeholder: "docker.io",
                    value: $registryDomain
                ) { newValue in
                    saveProperty(key: .defaultRegistryDomain, value: newValue)
                }
            }

            Section("settings.section.dns") {
                EditableSettingRow(
                    title: "settings.dns.domain",
                    titleKey: "settings.dns.domain",
                    description: "settings.dns.domain.description",
                    placeholder: "local",
                    value: $dnsDomain
                ) { newValue in
                    saveProperty(key: .defaultDNSDomain, value: newValue)
                }
            }

            Section("settings.section.images") {
                EditableSettingRow(
                    title: "settings.images.builder",
                    titleKey: "settings.images.builder",
                    description: "settings.images.builder.description",
                    placeholder: "ghcr.io/apple/container/builder",
                    value: $imageBuilder
                ) { newValue in
                    saveProperty(key: .defaultBuilderImage, value: newValue)
                }

                EditableSettingRow(
                    title: "settings.images.init",
                    titleKey: "settings.images.init",
                    description: "settings.images.init.description",
                    placeholder: "ghcr.io/apple/container/init",
                    value: $imageInit
                ) { newValue in
                    saveProperty(key: .defaultInitImage, value: newValue)
                }
            }

            Section("settings.section.kernel") {
                EditableSettingRow(
                    title: "settings.kernel.url",
                    titleKey: "settings.kernel.url",
                    description: "settings.kernel.url.description",
                    placeholder: "https://...",
                    value: $kernelURL
                ) { newValue in
                    saveProperty(key: .defaultKernelURL, value: newValue)
                }

                EditableSettingRow(
                    title: "settings.kernel.binaryPath",
                    titleKey: "settings.kernel.binaryPath",
                    description: "settings.kernel.binaryPath.description",
                    placeholder: "vmlinux",
                    value: $kernelBinaryPath
                ) { newValue in
                    saveProperty(key: .defaultKernelBinaryPath, value: newValue)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 600)
        .task {
            await loadSettings()
        }
    }

    private func loadSettings() async {
        loadPropertyList()
        await loadSystemStatus()
        await checkForUpdates()
    }

    private func loadPropertyList() {
        buildRosetta = DefaultsStore.getBool(key: .buildRosetta) ?? true
        dnsDomain = DefaultsStore.getOptional(key: .defaultDNSDomain) ?? ""
        imageBuilder = DefaultsStore.get(key: .defaultBuilderImage)
        imageInit = DefaultsStore.get(key: .defaultInitImage)
        kernelBinaryPath = DefaultsStore.get(key: .defaultKernelBinaryPath)
        kernelURL = DefaultsStore.get(key: .defaultKernelURL)
        registryDomain = DefaultsStore.get(key: .defaultRegistryDomain)
    }

    private func loadSystemStatus() async {
        let status = await ContainerService.fetchSystemStatus()
        appVersion = status.version
        appDataRoot = status.dataRoot.isEmpty ? String(localized: "settings.unableToRetrieve") : status.dataRoot
        appInstallRoot = status.installRoot.isEmpty ? String(localized: "settings.unableToRetrieve") : status.installRoot
    }

    private func saveProperty(key: DefaultsStore.Keys, value: String) {
        if value.isEmpty {
            DefaultsStore.unset(key: key)
        } else {
            DefaultsStore.set(value: value, key: key)
        }
    }

    private func saveBoolProperty(key: DefaultsStore.Keys, value: Bool) {
        DefaultsStore.setBool(value: value, key: key)
    }

    private func checkForUpdates() async {
        let result = await ContainerService.checkForUpdates()

        switch result {
        case .success(let updateInfo):
            latestVersion = updateInfo.latestVersion
            updateAvailable = updateInfo.updateAvailable
        case .failure:
            // Version check failed silently - not critical for UX
            latestVersion = ""
            updateAvailable = false
        }
    }
}

#Preview {
    SettingsView()
}
