//
//  AppState.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/28.
//

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {

    let audioMonitor = AudioMonitor()
    let fetcher = DeviceInfoFetcher()

    @Published var gluedDevice: GluedDevice? = GluedDevice.load()
    @Published var selectedAddress: String? = GluedDevice.load()?.address

    init() {
        audioMonitor.startMonitoring()

        Task {
            do {
                fetcher.deviceinfos = try await fetcher.getDeviceInfo()
            } catch {
                fetcher.error = error
                print("getDeviceInfo error: \(error)")
            }
        }
    }
}
