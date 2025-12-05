//
//  ContentView.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import SwiftUI

struct ContentView: View {
    
    
    @StateObject var fetcher = DeviceInfoFetcher()

    @State private var selectedAddress: String? = nil
    @State private var gluedDevice: GluedDevice? = nil

    var body: some View {
    VStack(alignment: .leading) {
        Text("Glued to: \(gluedDevice?.name ?? "None")")
            .font(.system(.title2, design: .monospaced))
            .bold()
        
        GroupBox {
            List(fetcher.deviceinfos, id: \.address) { info in
                DeviceInfoRow(info: info)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(
                        Group {
                            if selectedAddress == info.address {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.2))
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedAddress == info.address {
                            selectedAddress = nil
                            GluedDevice.clear()
                            gluedDevice = nil
                        } else {
                            selectedAddress = info.address
                            GluedDevice.save(from: info)
                            gluedDevice = GluedDevice.load()
                        }
                    }
                
            }
            .frame(maxHeight: 400)
        }
    }
    .padding()
    .fixedSize(horizontal: false, vertical: true)
    .task {
        gluedDevice = GluedDevice.load()
        if let device = gluedDevice {
            selectedAddress = device.address
        }
        
        do {
            fetcher.deviceinfos = try await fetcher.getDeviceInfo()
        } catch {
            fetcher.error = error
        }
    }
}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().frame(width: 300)
    }
}
