//
//  ClusterItemCoreMeter.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import SwiftUI

public struct ClusterItemCoreMeter: View {
    public let maxFrequency: UInt32?
    public var frequency: CGFloat
    
    private let width: CGFloat = 40
    private let capsule = Capsule(style: .continuous)
    
    public var body: some View {
        ZStack(alignment: .leading) {
            capsule
                .foregroundColor(Color("primary").opacity(0.1))
            
            if let maxFrequency = maxFrequency {
                capsule
                    .frame(width: frequency / CGFloat(maxFrequency) * width)
                    .foregroundColor(AppSettings.shared.graphColor.color)
            }
        }
        .frame(width: width, height: 4)
    }
}
