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
    @State public var graphColor: String
    
    public var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                VStack {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 128, height: 128)
                    
                    Text("**Frequency Stats** v\(Bundle.main.releaseVersionNumber ?? "?")")
                        .font(.title2)
                        .padding(.bottom, 2)
                    
                    Text(NSLocalizedString("appsettings.creditString", comment: ""))
                        .foregroundColor(.secondary)
                    
                    if let url = URL(string: "https://github.com/BitesPotatoBacks/FrequencyStats") {
                        Link(NSLocalizedString("appsettings.githubVisitString", comment: ""), destination: url)
                    }
                }
                .padding(.bottom)
                
                Divider()
                
                VStack {
                    // sample interval setting
                    HStack {
                        Text(NSLocalizedString("appsettings.updateIntervalString", comment: ""))
                        Spacer()
                        
                        Picker(selection: $updateInterval, content: {
                            Text("0.5 \(NSLocalizedString("appsettings.pluralSecondString", comment: ""))")
                                .tag(0.5)
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
                        })
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    // graph color setting
                    HStack {
                        Text(NSLocalizedString("appsettings.graphColorString", comment: ""))
                        Spacer()
                        
                        Image(systemName: "circle.fill")
                            .foregroundColor(AppSettings.graphColorDictionary.first(where: { $0.name == graphColor })?.color ?? .gray)
                        
                        Picker(selection: $graphColor, content: {
                            ForEach(AppSettings.graphColorDictionary) { color in
                                Text(color.name).tag(color.name)
                            }
                        }, label: {
                        })
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
                .padding(20)
                
                Divider()
                
                Button(NSLocalizedString("appsettings.quitAppString", comment: "")) {
                    NSApp.terminate(nil)
                }
                .padding([.bottom, .top])
            }
            .frame(width: 300)
            .onChange(of: updateInterval, perform: { value in
                AppSettings.shared.setUpdateInterval(to: value)
            })
            .onChange(of: graphColor, perform: { value in
                AppSettings.shared.setGraphColor(to: value)
            })
        }
    }
}
