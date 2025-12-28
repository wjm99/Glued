//
//  GluedApp.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/28.
//

import Foundation
import SwiftUI

@main
struct GluedApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
