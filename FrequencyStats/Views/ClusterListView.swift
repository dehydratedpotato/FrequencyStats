//
//  ClusterListView.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import SwiftUI

public struct ClusterListView: View {
    @StateObject private var sampleManager: SampleManager
    
    init() {
        self._sampleManager = .init(wrappedValue: .shared)
    }
    
    public var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
            
            VStack(spacing: 10) {
                ForEach(sampleManager.sampledClusters, id:\.clusterKey) { cluster in
                    ClusterItem(cluster: cluster)
                }
                
                HStack {
                    Button(action: {
                        NSApp.terminate(nil)
                    }, label: {
                        
                        Image(systemName: "xmark.circle.fill")
                    })
                    .buttonStyle(.borderless)
                    
                    Spacer()
                    
                    Button(action: {
                        AppSettings.shared.showWindow()
                    }, label: {
                        
                        Image(systemName: "gearshape.fill")
                    })
                    .buttonStyle(.borderless)
                }
            }
            .padding(10)
            .frame(width: 258)
        }
    }
}
