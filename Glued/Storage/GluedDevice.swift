//
//  GluedDevice.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import Foundation

struct GluedDevice: Codable {
    let address: String
    let name: String

    private static let storageKey = "glued_device"

    static func save(from info: DeviceInfo) {
        let glued = GluedDevice(address: info.address, name: info.name)
        do {
            let data = try JSONEncoder().encode(glued)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode GluedDevice: \(error)")
        }
    }

    static func load() -> GluedDevice? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(GluedDevice.self, from: data)
        } catch {
            print("Failed to decode GluedDevice: \(error)")
            return nil
        }
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}