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

    var body: some View {
        VStack(alignment: .leading) {
            Text("Glue to: ").font(.title2).bold()
            
            GroupBox {
                List(fetcher.deviceinfos, id: \.address) { info in
                    DeviceInfoRow(info: info)
                    .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedAddress == info.address ? Color.green : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAddress = info.address
                            GluedDevice.save(from: info)
                        }
                    
                }
            }
        }
        .padding()
        .task {
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
