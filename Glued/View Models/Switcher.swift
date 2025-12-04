//
//  Switcher.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import Foundation

/// 负责根据 `GluedDevice` 里保存的地址和名字，
/// 使用 blueutil + SwitchAudioSource 连接并切换到目标设备。
final class Switcher {
    
    // MARK: - Public API
    
    /// 从 UserDefaults 中读取 `GluedDevice`，并尝试连接 / 切换到该设备。
    func switchToSavedDevice() {
        guard let device = GluedDevice.load() else {
            print("⚠️ No saved GluedDevice found, skip switching.")
            return
        }
        
        let btMac = device.address
        let audioDeviceName = device.name
        
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .medium
        )
        
        print("[\(timestamp)] 🔄 Switching to Glued device: \(audioDeviceName) (\(btMac))")
        
        // 1. 连接蓝牙设备
        print("[\(timestamp)] Connecting to AirPods (\(btMac)) via blueutil...")
        _ = executeCommand("/opt/homebrew/bin/blueutil",
                           arguments: ["--connect", btMac])
        
        // 2. 切换默认输出设备
        print("[\(timestamp)] Switching audio output to \"\(audioDeviceName)\" via SwitchAudioSource...")
        _ = executeCommand("/opt/homebrew/bin/SwitchAudioSource",
                           arguments: ["-s", audioDeviceName])
        
        print("[\(timestamp)] ✅ Switcher operation completed.")
    }
    
    // MARK: - Shell helper
    
    @discardableResult
    private func executeCommand(_ command: String, arguments: [String] = []) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Error executing command: \(command) \(arguments) - \(error)")
            return nil
        }
    }
}
