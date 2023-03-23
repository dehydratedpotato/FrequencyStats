//
//  AppSettings.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import SwiftUI

public final class AppSettings: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared: AppSettings = AppSettings()
    
    public struct GraphColor: Identifiable {
        public let id = UUID()
        
        public let name: String
        public let color: Color
    }
    
    public static let graphColorDictionary: [GraphColor] = [
        .init(name: "Accent Color", color: .accentColor),
        .init(name: "Red", color: .red),
        .init(name: "Orange", color: .orange),
        .init(name: "Yellow", color: .yellow),
        .init(name: "Green", color: .green),
        .init(name: "Blue", color: .blue),
        .init(name: "Purple", color: .purple),
        .init(name: "Pink", color: .pink),
        .init(name: "Solid", color: Color("primary"))
    ]
    
    public var updateInterval: TimeInterval
    public var graphColor: GraphColor
    
//    public var showGraphics: Bool = true
    
    private var appSettingsWindow: NSWindow?
    private var windowIsVisible: Bool = false
    
    // MARK: - Lifecycle
    
    override init() {
        let interval = UserDefaults.standard.float(forKey: "UpdateInterval")
        let colorString = UserDefaults.standard.string(forKey: "GraphColor")
        
        if interval != 0 {
            self.updateInterval = TimeInterval(interval)
        } else {
            self.updateInterval = 1
        }
        
        if let colorString = colorString {
            self.graphColor = AppSettings.graphColorDictionary.first(where: { $0.name == colorString }) ??  AppSettings.graphColorDictionary[0]
        } else {
            self.graphColor = AppSettings.graphColorDictionary[0]
        }
        
        let appSettingsView = NSHostingView(rootView: AppSettingsView(updateInterval: self.updateInterval, graphColor: colorString ?? "Accent Color"))
        let appSettingsWindow = NSWindow()
        
        appSettingsWindow.titlebarAppearsTransparent = true
        appSettingsWindow.styleMask = [.closable, .miniaturizable, .titled, .fullSizeContentView]
        appSettingsWindow.contentView = appSettingsView
        appSettingsWindow.isReleasedWhenClosed = false

        
        self.appSettingsWindow = appSettingsWindow
        
        super.init()
        
        self.appSettingsWindow?.delegate = self
    }
    
    // MARK: - Methods
    
    public final func setUpdateInterval(to interval: TimeInterval) {
        SampleManager.shared.stopSampleTimer()
        
        self.updateInterval = interval
        
        UserDefaults.standard.set(interval, forKey: "UpdateInterval")
        
        SampleManager.shared.startSampleTimer()
    }
    
    public final func setGraphColor(to colorString: String) {
        SampleManager.shared.stopSampleTimer()
        
        if let color = AppSettings.graphColorDictionary.first(where: { $0.name == colorString }) {
            self.graphColor = color
            
            UserDefaults.standard.set(colorString, forKey: "GraphColor")
        } else {
            self.graphColor = AppSettings.graphColorDictionary[0]
            
            UserDefaults.standard.set("Accent Color", forKey: "GraphColor")
        }
        
        SampleManager.shared.startSampleTimer()
    }
    
    public final func showWindow() {
        self.appSettingsWindow?.makeKeyAndOrderFront(self)
        
        if !self.windowIsVisible {
            self.appSettingsWindow?.center()
        }
        
        self.windowIsVisible = true
    }
    
    public func windowWillClose(_ notification: Notification) {
        self.windowIsVisible = false
    }
}
