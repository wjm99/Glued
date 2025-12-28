//
//  AppDelegate.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/28.
//

import Foundation
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var appState: AppState!

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {

        // ✅ 在 MainActor / 主线程上创建
        appState = AppState()

        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "link.badge.plus",
                accessibilityDescription: "Glued"
            )
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(appState)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
        }
    }
}
