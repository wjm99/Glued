//
//  DeviceInfoRow.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

struct DeviceInfoRow: View {
    let info : DeviceInfo
    
    var body: some View {
        Text(info.name)
            .font(.body)
    }
}

struct DeviceInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoRow(info: DeviceInfo(address: "00:00:00:00:00:00", connect_status: "connected", favorite_status: "favorite", paired_status: "paired", name: "小珏", recent_access_date: Date()))
    }
}
