//
//  GluedApp.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

@main
struct GluedApp: App {
    var body: some Scene {
        MenuBarExtra{
            ContentView()
        } label: {
            Label("Glued", systemImage: "airpods")
        }.menuBarExtraStyle(.window)
    }
}
