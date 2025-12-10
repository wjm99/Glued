//
//  GluedApp.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

@main
struct GluedApp: App {

    private let audioMonitor = AudioMonitor()
    private let fetcher = DeviceInfoFetcher()

    @State private var gluedDevice: GluedDevice? = GluedDevice.load()
    @State private var selectedAddress: String? = GluedDevice.load()?.address

    init() {
        audioMonitor.startMonitoring()

        let fetcher = self.fetcher
        Task { @MainActor in
            do {
                fetcher.deviceinfos = try await fetcher.getDeviceInfo()
            } catch {
                fetcher.error = error
                print("getDeviceInfo error: \(error)")
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(
                fetcher: fetcher,
                gluedDevice: $gluedDevice,
                selectedAddress: $selectedAddress
            )
        } label: {
            Label("Glued", systemImage: "airpods")
        }
        .menuBarExtraStyle(.menu)
    }
}

