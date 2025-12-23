//
//  ContentView.swift
//  container.desktop
//
//  Created by Julien DUCHON on 17/11/2025.
//

import SwiftUI

enum NavigationSection: String, CaseIterable, Identifiable {
    case containers
    case images
    case volumes
    case network
    case logs
    case settings

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .containers: return "navigation.containers"
        case .images: return "navigation.images"
        case .volumes: return "navigation.volumes"
        case .network: return "navigation.network"
        case .logs: return "navigation.logs"
        case .settings: return "navigation.settings"
        }
    }

    var icon: String {
        switch self {
        case .containers: return "shippingbox"
        case .images: return "list.bullet.rectangle"
        case .volumes: return "square.stack.3d.up"
        case .network: return "link"
        case .logs: return "doc.text"
        case .settings: return "gearshape"
        }
    }

    var isMainSection: Bool {
        self != .settings
    }
}

struct ContentView: View {
    @State private var selection: NavigationSection? = .containers

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(NavigationSection.allCases.filter(\.isMainSection)) { section in
                    NavigationLink(value: section) {
                        Label(section.label, systemImage: section.icon)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 6)
                }

                Divider()
                    .padding(.vertical, 8)

                NavigationLink(value: NavigationSection.settings) {
                    Label(NavigationSection.settings.label, systemImage: NavigationSection.settings.icon)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.vertical, 6)
            }
            .navigationSplitViewColumnWidth(200)
            .navigationTitle(Text("navigation.sections"))
            .listStyle(.sidebar)
        } detail: {
            VStack(spacing: 0) {
                switch selection {
                case .containers:
                    ContainersView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .images:
                    ImagesView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .volumes:
                    VolumesView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .network:
                    NetworkView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .logs:
                    LogsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .settings:
                    SettingsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .none:
                    Text("navigation.selectItem")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Divider()

                StatusBarView()
            }
        }
    }
}

#Preview {
    ContentView()
}
