//
//  Cluster.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/11/23.
//

import SwiftUI

public struct DvfsState {
    public let nominalFrequency: UInt32
    public var residency: CGFloat
    
    public var rawResidency: UInt64 = 0
}

public struct Core {
    public let coreKey: String
    
    public var dvfsStates: (array: [DvfsState], rawSums: UInt64)
    
    public var frequency: CGFloat
}

public struct Cluster {
    public static let maximumFrequencyCount = 72
    public static let maximumCoreFrequencyCount = 20
    
    public let clusterKey: String
    
    public var cores: [Core]
    public var dvfsStates: (array: [DvfsState], rawSums: UInt64)
    
    public var frequency: [CGFloat]
    
    public mutating func resetRawSums() {
        self.dvfsStates.rawSums = 0
        
        for i in self.cores.indices {
            self.cores[i].dvfsStates.rawSums = 0
        }
    }
    
    public var clusterType: String {
        if self.clusterKey.contains("ECPU") {
            return NSLocalizedString("efficiencyString", comment: "")
        } else if self.clusterKey.contains("PCPU") {
            return NSLocalizedString("performanceString", comment: "")
        } else if self.clusterKey.contains("GPU") {
            return NSLocalizedString("graphicsString", comment: "")
        }
        
        return NSLocalizedString("unknownString", comment: "")
    }
    
    public var clusterPrefix: String {
        if self.clusterKey.contains("ECPU") {
            return "E-"
        } else if self.clusterKey.contains("PCPU") {
            return "P-"
        }
        
        return ""
    }
    
    public var clusterImage: String {
        if self.clusterKey.contains("ECPU") {
            return "snowflake"
        } else if self.clusterKey.contains("PCPU") {
            return "flame"
        } else if self.clusterKey.contains("GPU") {
            return "display"
        }
        
        return "cpu"
    }
}
