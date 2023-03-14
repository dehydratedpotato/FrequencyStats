//
//  AppSettings.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import SwiftUI

public final class AppSettings: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared = AppSettings()
    
    public var updateInterval: TimeInterval
    
    private var appSettingsWindow: NSWindow?
    private var windowIsVisible: Bool = false
//    @Published public var graphColor: Color = .accentColor
    
    // MARK: - Lifecycle
    
    override init() {
        let interval = UserDefaults.standard.integer(forKey: "UpdateInterval")
//        let color = UserDefaults.standard.integer(forKey: "GraphColor")
        
        if interval != 0 {
            self.updateInterval = TimeInterval(interval)
        } else {
            self.updateInterval = 1
        }
        
        let appSettingsView = NSHostingView(rootView: AppSettingsView(updateInterval: self.updateInterval))
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
