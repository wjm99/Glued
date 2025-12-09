//
//  ContentView.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

struct ContentView: View {
    @StateObject var fetcher = DeviceInfoFetcher()

    @State private var selectedAddress: String? = nil
    @State private var gluedDevice: GluedDevice? = nil
    @State private var showDevices: Bool = false
    @State private var hovering: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                showDevices.toggle()
            }) {
                HStack {
                    Text("🎧 Glued to: \(gluedDevice?.name ?? "No device")")
                        .font(.system(.title3))
                        .bold()
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("›")
                        .font(.system(.title3))
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(hovering ? Color.blue.opacity(0.5) : Color.gray.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                hovering = isHovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Divider()

            if showDevices {
                if fetcher.deviceinfos.isEmpty {
                    // No devices found
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Glued earphones found")
                            .font(.system(.body))

                        Button("Rescan devices") {
                            Task {
                                do {
                                    fetcher.deviceinfos = try await fetcher.getDeviceInfo()
                                } catch {
                                    fetcher.error = error
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    // Connected devices list
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connected devices:")
                            .font(.system(.title3))
                            .bold()

                        List(fetcher.deviceinfos, id: \.address) { info in
                            HStack {
                                Text(info.name)
                                    .font(.title3)

                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                            .background(
                                Group {
                                    if selectedAddress == info.address {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue.opacity(0.2))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.1))
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedAddress == info.address {
                                    selectedAddress = nil
                                    GluedDevice.clear()
                                    gluedDevice = nil
                                } else {
                                    selectedAddress = info.address
                                    GluedDevice.save(from: info)
                                    gluedDevice = GluedDevice.load()
                                }
                            }
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        .frame(maxHeight: 150) 
                    }
                    .padding()
                }

                Divider()
            }

            // Quit button
            HStack {
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .keyboardShortcut("q", modifiers: [.command])
                .padding()
            }
        }
        .task {
            gluedDevice = GluedDevice.load()
            if let device = gluedDevice {
                selectedAddress = device.address
            }

            do {
                fetcher.deviceinfos = try await fetcher.getDeviceInfo()
            } catch {
                fetcher.error = error
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().frame(width: 260)
    }
}
