//
//  ContentView.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var fetcher: DeviceInfoFetcher
    @Binding var gluedDevice: GluedDevice?
    @Binding var selectedAddress: String?

    @State private var showDevices: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            Text("🎧 Glued to: \(gluedDevice?.name ?? "No device")")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)

            Divider()

            if fetcher.deviceinfos.isEmpty {
                Text("No Connected earphones found")
                    .font(.subheadline)
            } else {
                Text("Connected devices:")
                    .font(.subheadline)
                    .bold()

                ForEach(fetcher.deviceinfos, id: \.address) { info in
                    Button(action: {
                        if selectedAddress == info.address {
                            selectedAddress = nil
                            GluedDevice.clear()
                            gluedDevice = nil
                        } else {
                            selectedAddress = info.address
                            GluedDevice.save(from: info)
                            gluedDevice = GluedDevice.load()
                        }
                    }) {
                        HStack {
                            Text(info.name)
                                .font(.body)

                            Spacer()

                            if selectedAddress == info.address {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }

            Divider()

            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fetcher: DeviceInfoFetcher(), gluedDevice: .constant(nil), selectedAddress: .constant(nil)).frame(width: 260)
    }
}
