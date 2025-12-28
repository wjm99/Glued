//
//  ContentView.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var appState: AppState
    @State private var showDevices: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // Header
            Text("🎧 Glued to: \(appState.gluedDevice?.name ?? "No device")")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            Divider()

            if appState.fetcher.deviceinfos.isEmpty {
                Text("No Connected earphones found")
                    .font(.subheadline)
            } else {
                Text("Connected devices:")
                    .font(.subheadline)
                    .bold()

                ForEach(appState.fetcher.deviceinfos, id: \.address) { info in
                    Button {
                        toggleDevice(info)
                    } label: {
                        HStack {
                            Text(info.name)
                                .font(.body)

                            Spacer()

                            if appState.selectedAddress == info.address {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Quit button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 260)
    }

    // MARK: - Actions

    private func toggleDevice(_ info: DeviceInfo) {
        if appState.selectedAddress == info.address {
            appState.selectedAddress = nil
            GluedDevice.clear()
            appState.gluedDevice = nil
        } else {
            appState.selectedAddress = info.address
            GluedDevice.save(from: info)
            appState.gluedDevice = GluedDevice.load()
        }
    }
}
