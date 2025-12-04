//
//  AudioMonitor.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import Foundation
import CoreAudio

/// 只负责监听当前输出设备有没有音频流，一旦检测到“开始有声音”
/// 就调用 `Switcher` 去切换到保存好的 Glued 设备。
final class AudioMonitor {
    
    // MARK: - Dependencies
    
    private let switcher: Switcher
    
    // MARK: - State
    
    /// 是否正在监控
    private(set) var isMonitoring = false
    
    /// 当前监听的输出设备 ID
    private var currentDeviceID = AudioDeviceID(0)
    
    /// 上一次的 “device is running” 状态
    private var wasRunning = false

    /// 为 DeviceIsRunningSomewhere 注册监听的设备 ID
    private var runningListenerDeviceID = AudioDeviceID(0)

    /// 保存用于监听 DeviceIsRunningSomewhere 的 block，方便后续移除
    private var runningStateListenerBlock: AudioObjectPropertyListenerBlock?
    
    /// 所有 CoreAudio 回调跑在这个队列上
    private let audioQueue = DispatchQueue(label: "glued.coreaudio.queue", qos: .background)
    
    // MARK: - Init
    
    init(switcher: Switcher = Switcher()) {
        self.switcher = switcher
    }
    
    // MARK: - Public API
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        print("🎧 AudioMonitor started (event-driven via CoreAudio)")
        
        // 1. 先获取当前默认输出设备
        updateCurrentOutputDevice()
        
        // 2. 监听默认输出设备变化
        registerDefaultDeviceChangeListener()
        
        // 3. 在当前输出设备上监听 “是否正在跑” 状态
        registerRunningStateListenerForCurrentDevice()
    }
    
    func stopMonitoring() {
        // 简单标记为 false，回调里会先检查这个标志位
        isMonitoring = false
        print("🛑 AudioMonitor stopped (listeners stay attached until app exit).")
    }
    
    // MARK: - CoreAudio: 获取设备名称 / 默认输出设备
    
    /// 从 AudioDeviceID 获取设备名称
    private func getDeviceName(for deviceID: AudioDeviceID) -> String? {
        guard deviceID != 0 else { return nil }
        
        var name: CFString? = nil
        var size = UInt32(MemoryLayout.size(ofValue: name))
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &name
        )
        
        if status != noErr {
            return nil
        }
        
        return name as String?
    }
    
    /// 刷新 currentDeviceID 到当前默认输出设备
    private func updateCurrentOutputDevice() {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout.size(ofValue: deviceID))
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        
        if status != noErr {
            print("❌ Failed to get default output device, status = \(status)")
            return
        }
        
        currentDeviceID = deviceID
        
        if let deviceName = getDeviceName(for: currentDeviceID) {
            print("🔊 Current default output device: \(deviceName) (ID: \(currentDeviceID))")
        } else {
            print("🔊 Current default output device ID: \(currentDeviceID) (name unavailable)")
        }
    }
    
    /// 监听 “默认输出设备” 的变化
    private func registerDefaultDeviceChangeListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            audioQueue
        ) { [weak self] _, _ in
            guard let self = self, self.isMonitoring else { return }
            self.handleDefaultDeviceChanged()
        }
        
        if status != noErr {
            print("❌ Failed to register default device change listener, status = \(status)")
        } else {
            print("✅ Registered listener for default output device changes")
        }
    }
    
    /// 默认输出设备变化时调用
    private func handleDefaultDeviceChanged() {
        print("🔁 Default output device changed, updating listeners...")
        updateCurrentOutputDevice()
        
        // 默认设备变了，要重新在新设备上监听 running 状态
        registerRunningStateListenerForCurrentDevice()
    }
    
    // MARK: - CoreAudio: 设备是否在工作
    
    /// 在 currentDeviceID 上监听 kAudioDevicePropertyDeviceIsRunningSomewhere
    private func registerRunningStateListenerForCurrentDevice() {
        guard currentDeviceID != 0 else {
            print("⚠️ currentDeviceID is 0, skip registering running listener")
            return
        }
        
        // 如果之前已经在某个设备上注册过监听，先移除旧的监听
        if runningListenerDeviceID != 0,
           let oldBlock = runningStateListenerBlock {
            
            var oldAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            let removeStatus = AudioObjectRemovePropertyListenerBlock(
                runningListenerDeviceID,
                &oldAddress,
                audioQueue,
                oldBlock
            )
            
            if removeStatus != noErr {
                print("⚠️ Failed to remove previous running-state listener from device \(runningListenerDeviceID), status = \(removeStatus)")
            } else {
                print("♻️ Removed previous running-state listener from device \(runningListenerDeviceID)")
            }
            
            runningListenerDeviceID = 0
            runningStateListenerBlock = nil
        }
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self = self, self.isMonitoring else { return }
            self.handleRunningStateChanged()
        }
        
        let status = AudioObjectAddPropertyListenerBlock(
            currentDeviceID,
            &address,
            audioQueue,
            block
        )
        
        if status != noErr {
            print("❌ Failed to register running-state listener, status = \(status)")
        } else {
            runningListenerDeviceID = currentDeviceID
            runningStateListenerBlock = block
            print("✅ Registered listener for DeviceIsRunningSomewhere on device \(currentDeviceID)")
        }
    }
    
    /// 查询当前设备是否在 “running somewhere”
    private func queryIsRunning() -> Bool {
        guard currentDeviceID != 0 else { return false }
        
        var isRunning: UInt32 = 0
        var size = UInt32(MemoryLayout.size(ofValue: isRunning))
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            currentDeviceID,
            &address,
            0,
            nil,
            &size,
            &isRunning
        )
        
        if status != noErr {
            print("❌ Failed to query DeviceIsRunningSomewhere, status = \(status)")
            return false
        }
        
        return isRunning != 0
    }
    
    /// 当设备 running 状态变化时调用
    private func handleRunningStateChanged() {
        let nowRunning = queryIsRunning()
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .medium
        )
        
        print("[\(timestamp)] DeviceIsRunningSomewhere = \(nowRunning) (prev: \(wasRunning))")
        
        // 从 false -> true：认为“开始有音频流过当前输出设备”
        if nowRunning && !wasRunning {
            print("[\(timestamp)] 🎵 Detected audio activity on output device. Will try switching to saved Glued device...")
            switcher.switchToSavedDevice()
        }
        
        wasRunning = nowRunning
    }
}
