//
//  AppDelegate.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/11/23.
//

import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var dropwdownWindow: NSWindow?
    private var statusBarItem: NSStatusItem!
    
    private var eventMonitor: Any?
    private var dropdownVisible: Bool = false
    
    override init() {
        super.init()
        
        SampleManager.shared.connectToHelper()
        SampleManager.shared.startSampleTimer()
    }
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let dropdownView = NSHostingView(rootView: ClusterListView())
        dropdownView.wantsLayer = true
        dropdownView.layer?.masksToBounds = true
        dropdownView.layer?.cornerCurve = .continuous
        dropdownView.layer?.cornerRadius = 20
        
        let dropdownWindow = NSWindow()
        dropdownWindow.titleVisibility = .hidden
        dropdownWindow.styleMask.remove(.titled)
        dropdownWindow.backgroundColor = .clear
        dropdownWindow.contentView = dropdownView
        dropdownWindow.hasShadow = true
        dropdownWindow.isReleasedWhenClosed = false
        dropdownWindow.level = .statusBar
        
        let statusBarItem = NSStatusBar.system.statusItem(withLength: 24)
        statusBarItem.behavior = [.terminationOnRemoval, .removalAllowed]

        if let statusBarButton = statusBarItem.button {
            statusBarButton.image = NSImage(named: "ItemIcon")
            
            statusBarButton.action = #selector(toggleDropdown(sender:))
            statusBarButton.target = self
        }
        
        let eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown], handler: { event in
            if self.dropdownVisible {
                self.dropwdownWindow?.close()
                
                self.dropdownVisible = false
            }
        })
        
        self.dropwdownWindow = dropdownWindow
        self.statusBarItem = statusBarItem
        self.eventMonitor = eventMonitor
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if self.eventMonitor != nil {
            NSEvent.removeMonitor(self.eventMonitor!)
            self.eventMonitor = nil
        }
    }
    
    @objc private func toggleDropdown(sender: Any?) {
        if !self.dropdownVisible {
            guard let itemFrame = NSApp.currentEvent?.window?.frame, let windowFrame = self.dropwdownWindow?.frame else {
                return
            }
            
            let itemOrigin = itemFrame.origin
            let itemSize = itemFrame.size
            
            let windowSize = windowFrame.size
            let windowTopLeftPos = NSPoint(x: itemOrigin.x + itemSize.width / 2 - windowSize.width / 2, y: itemOrigin.y - 1)
            
            self.dropwdownWindow?.setFrameTopLeftPoint(windowTopLeftPos)
            self.dropwdownWindow?.makeKeyAndOrderFront(self)
            
            self.dropdownVisible = true
        } else {
            self.dropwdownWindow?.close()
            
            self.dropdownVisible = false
        }
    }
}
