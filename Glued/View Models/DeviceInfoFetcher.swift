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
            let output = try self.executeCommand(
                "/opt/homebrew/bin/blueutil",
                arguments: ["--paired"]
            )
            
            let deviceinfo = try self.parse(output)
            return deviceinfo
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
            // Split fields by ", "
            let parts = line.components(separatedBy: ", ")
            guard parts.count >= 6 else { continue }
            
            // address
            guard parts[0].hasPrefix("address: ") else { continue }
            let address = String(parts[0].dropFirst("address: ".count))
            
            // name
            guard parts[4].hasPrefix("name: ") else { continue }
            var name = String(parts[4].dropFirst("name: ".count))
            // Trim surrounding quotes if present
            name = name.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            
            // recent access date
            guard parts[5].hasPrefix("recent access date: ") else { continue }
            let dateString = String(parts[5].dropFirst("recent access date: ".count))
            guard let date = formatter.date(from: dateString) else { continue }
            
            let device = DeviceInfo(
                address: address,
                connect_status: parts[1],
                favorite_status: parts[2],
                paired_status: parts[3],
                name: name,
                recent_access_date: date
            )
            
            result.append(device)
        }
        
        return result
    }
}