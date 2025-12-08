//
//  BlueUtil.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/8.
//

import Foundation
import IOBluetooth

/// 对应 blueutil --paired 的设备信息
public struct BluetoothDeviceInfo {
    public let name: String
    public let address: String
    public let isConnected: Bool
    public let isPaired: Bool
}

/// 对应 blueutil 的错误
public enum BlueUtilError: Error {
    case bluetoothUnavailable
    case deviceNotFound(String)
    case connectFailed(String, IOReturn)
}

public final class BlueUtil {

    // MARK: - public API

    /// 相当于 blueutil --paired
    public static func pairedDevices() -> [BluetoothDeviceInfo] {
        guard let anyDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return []
        }

        return anyDevices.map { dev in
            BluetoothDeviceInfo(
                name: dev.name ?? "(unknown)",
                address: dev.addressString ?? "",
                isConnected: dev.isConnected(),
                isPaired: dev.isPaired()
            )
        }
    }

    /// 相当于 blueutil --connect ID
    /// - Parameter id: 可以是 MAC 地址（`xx:xx:xx:xx:xx:xx` / `xx-xx-...` / `xxxxxxxxxxxx`）或精确设备名
    public static func connect(id: String) throws {
        // 可选：检查蓝牙是否可用（不是必需，但更友好）
        guard bluetoothAvailable() else {
            throw BlueUtilError.bluetoothUnavailable
        }

        guard let device = findDevice(id: id) else {
            throw BlueUtilError.deviceNotFound(id)
        }

        let result = device.openConnection()   // IOBluetoothDevice API:contentReference[oaicite:2]{index=2}
        if result != kIOReturnSuccess {
            throw BlueUtilError.connectFailed(id, result)
        }
    }

    // MARK: - helpers

    /// 蓝牙是否可用（简单判断）
    private static func bluetoothAvailable() -> Bool {
        // IOBluetooth 本身没有一个“全局开关”的简单方法；
        // 常见做法就是尝试访问设备列表 / host controller，
        // 这里做个最小判断：如果能拿到 pairedDevices 就认为可用。
        return IOBluetoothDevice.pairedDevices() != nil
    }

    /// 按 ID 查找设备：
    /// - ID 是地址：用 address 直接查
    /// - 否则：在已配对 + 最近设备里按名字精确匹配
    private static func findDevice(id: String) -> IOBluetoothDevice? {
        if isAddress(id) {
            // 尝试不同格式的地址
            if let dev = IOBluetoothDevice(addressString: id) {
                return dev
            }
            // 去掉分隔符再试一次
            let cleaned = id.replacingOccurrences(of: ":", with: "")
                            .replacingOccurrences(of: "-", with: "")
            if cleaned.count == 12,
               let dev = IOBluetoothDevice(addressString: cleaned) {
                return dev
            }
            return nil
        } else {
            // 名称查找：在已配对 + 最近设备里搜索
            let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
            let recent = (IOBluetoothDevice.recentDevices(0) as? [IOBluetoothDevice]) ?? []
            let all = paired + recent
            return all.first { $0.name == id }
        }
    }

    /// 判断字符串是否可能是蓝牙地址（和 blueutil 的正则逻辑类似）
    private static func isAddress(_ s: String) -> Bool {
        let pattern = #"^[0-9A-Fa-f]{2}([0-9A-Fa-f]{10}|(-[0-9A-Fa-f]{2}){5}|(:[0-9A-Fa-f]{2}){5})$"#
        return (try? NSRegularExpression(pattern: pattern))?
            .firstMatch(in: s, range: NSRange(location: 0, length: s.utf16.count)) != nil
    }
}

