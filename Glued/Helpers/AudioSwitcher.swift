//
//  AudioSwitcher.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/8.
//

import Foundation
import CoreAudio
import AudioToolbox

public enum AudioSwitchError: Error, CustomStringConvertible {
    case deviceNotFound(String)
    case coreAudioError(OSStatus, String)

    public var description: String {
        switch self {
        case .deviceNotFound(let name):
            return "Audio device not found: \(name)"
        case .coreAudioError(let status, let message):
            return "CoreAudio error \(status): \(message)"
        }
    }
}

/// 只实现你需要的：按名字切换默认输出设备（等价于 SwitchAudioSource -s）
public enum SystemAudioSwitcher {

    /// 等价：`SwitchAudioSource -s deviceName`
    public static func setOutputDevice(named deviceName: String) throws {
        // 1. 找到名字匹配的输出设备 ID
        guard let deviceID = try findOutputDeviceID(named: deviceName) else {
            throw AudioSwitchError.deviceNotFound(deviceName)
        }

        // 2. 将其设为默认输出设备和系统输出设备（SwitchAudioSource 默认也会一起改）
        try setDefaultDevice(deviceID, type: .output)
        try setDefaultDevice(deviceID, type: .systemOutput)
    }

    // MARK: - 内部辅助类型

    private enum DeviceType {
        case output
        case systemOutput
    }

    // MARK: - 列举输出设备并按名字查找

    private static func findOutputDeviceID(named name: String) throws -> AudioDeviceID? {
        let deviceIDs = try allDeviceIDs()

        for id in deviceIDs {
            guard isOutputDevice(id) else { continue }

            if let deviceName = getDeviceName(id), deviceName == name {
                return id
            }
        }

        return nil
    }

    private static func allDeviceIDs() throws -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        )
        if status != noErr {
            throw AudioSwitchError.coreAudioError(status, "Failed to get devices data size")
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        deviceIDs.withUnsafeMutableBytes { buffer in
            if let base = buffer.baseAddress {
                status = AudioObjectGetPropertyData(
                    AudioObjectID(kAudioObjectSystemObject),
                    &address,
                    0,
                    nil,
                    &dataSize,
                    base
                )
            }
        }

        if status != noErr {
            throw AudioSwitchError.coreAudioError(status, "Failed to get devices list")
        }

        return deviceIDs
    }

    private static func isOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )

        return (status == noErr && dataSize > 0)
    }

    private static func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var cfName: CFString? = nil
        var dataSize = UInt32(MemoryLayout<CFString?>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            &cfName
        )

        if status != noErr || cfName == nil {
            return nil
        }

        return cfName! as String
    }

    // MARK: - 设置默认输出 / 系统输出设备

    private static func setDefaultDevice(_ deviceID: AudioDeviceID, type: DeviceType) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        switch type {
        case .output:
            address.mSelector = kAudioHardwarePropertyDefaultOutputDevice
        case .systemOutput:
            address.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice
        }

        var newID = deviceID
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            dataSize,
            &newID
        )

        if status != noErr {
            throw AudioSwitchError.coreAudioError(status, "Failed to set default device")
        }
    }
}
