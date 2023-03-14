//
//  ClusterItemView.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import SwiftUI

public struct ClusterItem: View {
    public let cluster: Cluster
    
    @State private var showCores: Bool = false
    private let roundedRectangle = RoundedRectangle(cornerRadius: 12, style: .continuous)
    
    public var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
            
            VStack(spacing: 0) {
                // header
                HStack(spacing: 4) {
                    if #available(macOS 12.0, *) {
                        Image(systemName: cluster.clusterImage)
                            .symbolRenderingMode(.monochrome)
                    } else {
                        Image(systemName: cluster.clusterImage)
                    }
                    Text(cluster.clusterType)
                    
                    Spacer()
                }
                .padding([.leading, .trailing, .top], 10)
                .foregroundColor(.secondary)
                .font(.headline)
                
                ClusterItemGraph(maxFrequency: cluster.dvfsStates.array.last?.nominalFrequency, frequencies: cluster.frequency)
                
                // cluster metrics
                HStack {
                    Text(NSLocalizedString("frequencyString", comment: ""))
                    Spacer()
                    
                    if let freq = cluster.frequency.last {
                        Text(String(format: "%.f MHz", freq))
                            .foregroundColor(Color("primary").opacity(0.7))
                    } else {
                        Text("... MHz")
                            .foregroundColor(Color("primary").opacity(0.7))
                    }
                }
                .padding(cluster.cores.isEmpty ?  [.leading, .trailing, .bottom] : [.leading, .trailing], 10)
                
                // core metrics
                if !cluster.cores.isEmpty {
                    Button(action: {
                        showCores.toggle()
                    }, label: {
                        HStack {
                            Text(NSLocalizedString("coreMetricsString", comment: ""))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.body.bold())
                                .foregroundColor(.secondary)
                                .popover(isPresented: $showCores, arrowEdge: .trailing, content: {
                                    coreListView
                                })
                        }
                        .padding(10)
                    })
                    .buttonStyle(ClusterItemButtonStyle())
                }
            }
        }
        .overlay(roundedRectangle.stroke(Color("primary").opacity(0.2), style: StrokeStyle(lineWidth: 1)))
        .clipShape(roundedRectangle)
        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
    }
    
    @ViewBuilder private var coreListView: some View {
        VStack(spacing: 10) {
            let cores = cluster.cores.sorted(by: { $0.coreKey < $1.coreKey })
            
            ForEach(cores.indices, id: \.self) { i in
                HStack {
                    Text("\(cluster.clusterPrefix)Core #\(i)")
                    Spacer()
                    Text(String(format: "%.f MHz", cores[i].frequency))
                        .foregroundColor(Color("primary").opacity(0.7))
                    
                    ClusterItemCoreMeter(maxFrequency: cluster.dvfsStates.array.last?.nominalFrequency, frequency: cores[i].frequency)
                }
            }
        }
        .frame(width: 200)
        .padding(12)
    }
}

public struct ClusterItemButtonStyle: ButtonStyle {
    @State private var isHovering: Bool = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .foregroundColor(isHovering && !configuration.isPressed ? Color("primary").opacity(0.125) : .clear)
                .padding(6)
        )
        .onHover { hover in
            withAnimation(.linear(duration: 0.05)) {
                isHovering = hover
            }
        }
    }
}
