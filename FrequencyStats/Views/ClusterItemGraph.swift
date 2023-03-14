//
//  GraphView.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/12/23.
//

import SwiftUI

public struct ClusterItemGraph: View {
    public let maxFrequency: UInt32?
    public var frequencies: [CGFloat]
    
    private let height: CGFloat = 45
    private let roundedRectangle = RoundedRectangle(cornerRadius: 4, style: .continuous)
    
    @State private var showMaxFrequency: Bool = false

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            roundedRectangle
                .foregroundColor(Color("primary").opacity(0.05))
                .padding(8)

            LinearGradient(colors: [.accentColor, .accentColor], startPoint: .top, endPoint: .bottom)
                .frame(height: height)
                .mask(graphView)
                .padding(12)

            if let maxFrequency = maxFrequency, showMaxFrequency {
                Text(String(format: "%u", maxFrequency))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(12)
            }
            
        }
        .clipShape(roundedRectangle)
        .onHover { hover in
            withAnimation(.linear(duration: 0.1)) {
                showMaxFrequency = hover
            }
        }
    }
    
    @ViewBuilder private var graphView: some View {
        Path { path in
            if let maxFrequency = maxFrequency {
                for i in frequencies.indices {
                    let frequency = frequencies[i]
                    let y: CGFloat = height - (frequency / CGFloat(maxFrequency) * height)
                    let x: CGFloat = CGFloat(i) * 3
                    
                    path.addLines([CGPoint(x: x, y: y),  CGPoint(x: x, y: height)])
                }
            }
        }
        .strokedPath(StrokeStyle(lineWidth: 2, lineCap: .round))
        .frame(height: height)
    }
}
