//
//  AppSettingsView.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import SwiftUI

public extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

public struct AppSettingsView: View {
    @State public var updateInterval: TimeInterval
    
    public var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea(.all)
            
            VStack {
                VStack {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 128, height: 128)
                    
                    Text("Frequency Stats (v\(Bundle.main.releaseVersionNumber ?? "?"))")
                        .font(.title2)
                    
                    Text(NSLocalizedString("appsettings.creditString", comment: ""))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Picker(selection: $updateInterval, content: {
                        Text("1 \(NSLocalizedString("appsettings.secondString", comment: ""))")
                            .tag(1.0)
                        Text("2 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                            .tag(2.0)
                        Text("3 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                            .tag(3.0)
                        Text("4 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                            .tag(4.0)
                        Text("6 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                            .tag(6.0)
                        Text("8 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                            .tag(8.0)
                        Text("10 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                            .tag(10.0)
                    }, label: {
                        Text(NSLocalizedString("appsettings.updateIntervalString", comment: ""))
                    })
                    .pickerStyle(.menu)
                    
                    //                Picker(selection: .constant(0), content: {
                    //
                    //                }, label: {
                    //                    Text("Graph Color")
                    //                })
                    //                .pickerStyle(.menu)
                }
                .frame(width: 220)
                
                Spacer()
                
                Button(NSLocalizedString("appsettings.quitAppString", comment: "")) {
                    NSApp.terminate(nil)
                }
                .padding(.bottom)
            }
            .frame(width: 300, height: 320)
            .padding(.top, 10)
            .onChange(of: updateInterval, perform: { value in
                AppSettings.shared.setUpdateInterval(to: value)
            })
        }
    }
}
