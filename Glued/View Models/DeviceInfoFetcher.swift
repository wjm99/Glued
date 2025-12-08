//  DeviceInfoFetcher.swift
//  Glued
//
//  Created by 韦津茗 on 2025/12/4.
//

import Foundation

class DeviceInfoFetcher: ObservableObject {
    
    // MARK: - Errors
    
    enum CommandError: Error {
        case invalidData
        case commandFailed(String)
        case emptyOutput
    }
    
    // MARK: - Published Properties
    
    @Published var deviceinfos: [DeviceInfo] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Public API
    
    func getDeviceInfo() async throws -> [DeviceInfo] {
        try await Task.detached(priority: .userInitiated) {
            // 直接调用我们封装好的 BlueUtil，而不是跑 /opt/homebrew/bin/blueutil
            let paired = BlueUtil.pairedDevices()

            let now = Date() // 没有 recentAccessDate 数据，就先用当前时间占位（你可以按需求改）

            let deviceInfos = paired.map { dev in
                DeviceInfo(
                    address: dev.address,
                    connect_status: dev.isConnected ? "connected" : "not connected",
                    favorite_status: "not favourite",          // IOBluetooth 没直接 favourite 概念，这里先固定
                    paired_status: dev.isPaired ? "paired" : "not paired",
                    name: dev.name,
                    recent_access_date: now
                )
            }

            return deviceInfos
        }.value
    }

    
    // MARK: - Command Execution
    
    /// Execute a command at a specific path with arguments and return trimmed output.
    private func executeCommand(_ command: String, arguments: [String] = []) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard var output = String(data: data, encoding: .utf8) else {
            throw CommandError.invalidData
        }
        
        output = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard process.terminationStatus == 0 else {
            throw CommandError.commandFailed(output)
        }
        
        guard !output.isEmpty else {
            throw CommandError.emptyOutput
        }
        
        return output
    }
    
    // MARK: - Parsing
    
    func parse(_ output: String) throws -> [DeviceInfo] {
        var result: [DeviceInfo] = []
        
        // Date formatter for: 2025-12-04 12:47:24 +0000
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        // Each non-empty line is one device
        let lines = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw CommandError.emptyOutput
        }
        
        for line in lines {
            let pattern = #"address: ([^,]+), (connected[^,]*(?:\([^)]+\))?|not connected), (not favourite|favourite), (paired|not paired), name: "([^"]+)", recent access date: (.+)"#
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
                  match.numberOfRanges == 7 else {
                continue
            }
            
            let address = String(line[Range(match.range(at: 1), in: line)!])
            let connectStatus = String(line[Range(match.range(at: 2), in: line)!])
            let favoriteStatus = String(line[Range(match.range(at: 3), in: line)!])
            let pairedStatus = String(line[Range(match.range(at: 4), in: line)!])
            let name = String(line[Range(match.range(at: 5), in: line)!])
            let dateString = String(line[Range(match.range(at: 6), in: line)!])
            
            guard let date = formatter.date(from: dateString) else {
                continue
            }
            
            let device = DeviceInfo(
                address: address,
                connect_status: connectStatus,
                favorite_status: favoriteStatus,
                paired_status: pairedStatus,
                name: name,
                recent_access_date: date
            )
            
            result.append(device)
        }
        
        return result
    }
}
