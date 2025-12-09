//
//  GluedApp.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

@main
struct GluedApp: App {
    
    /// 保持整个应用生命周期内都存在的监控器
    private let audioMonitor = AudioMonitor()
    
    init() {
        audioMonitor.startMonitoring()
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .frame(width: 260)
                .fixedSize(horizontal: true, vertical: false)
        } label: {
            Label("Glued", systemImage: "airpods")
        }
        .menuBarExtraStyle(.window)
    }
}
