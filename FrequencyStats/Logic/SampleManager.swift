//
//  SampleManager.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/11/23.
//

import Foundation
import AppKit

public final class SampleManager: ObservableObject {
    public static let shared = SampleManager()
    
    @Published public var sampledClusters: [Cluster]
    
    private let systemConstants: SystemConstants
    private var helperConnection: NSXPCConnection?
    private var helperProxy: FrequencyStatsHelperProtocol?
    
    private var sampleTimer: Timer?
    
    // MARK: - Lifecycle
    
    public init() {
        Logger.log("Initializing", class: SampleManager.self)
        
        let systemConstants = SystemConstants()

        // for every CPU and GPU cluster key, make a new cluster
        var clusters: [Cluster] = []
        
        for i in systemConstants.clusterKeys.indices {
            let key: String = systemConstants.clusterKeys[i]
            
            var dvfsStates: [DvfsState]?
            
            if key.contains("ECPU") {
                dvfsStates = systemConstants.dvfsStateDictionary["ECPU"]
            } else if key.contains("PCPU") {
                dvfsStates = systemConstants.dvfsStateDictionary["PCPU"]
            } else if key.contains("GPU") {
                dvfsStates = systemConstants.dvfsStateDictionary["GPU"]
            }
            
            guard let dvfsStates = dvfsStates else {
                fatalError("No Voltage States available")
            }
            
            var cores: [Core] = []
            
            // if the cluster is not a GPU, for every core in the corresponding index of our core counts, make a new core
            if key != "GPUPH" {
                for coreIndex in 0..<systemConstants.clusterCoreCounts[i] {
                    let core = Core(coreKey: "\(key)\(coreIndex)", dvfsStates: (dvfsStates, 0), frequency: 0)
                    cores.append(core)
                }
            }
            
            let cluster = Cluster(clusterKey: key, cores: cores, dvfsStates: (dvfsStates, 0), frequency: [])
            clusters.append(cluster)
        }
        
        self.systemConstants = systemConstants
        self.sampledClusters = clusters
    }
    
    // MARK: - Methods
    
    @objc private func terminateApp() {
        NSApp.terminate(nil)
    }
    
    public final func connectToHelper() {
        // IOReport access from a program with an App lifecycle doesn't work for some reason,
        // so instead we can just make the samples from an XPC service.
        
        let helperConnection = NSXPCConnection(serviceName: "com.bitespotatobacks.FrequencyStatsHelper")
        helperConnection.remoteObjectInterface = NSXPCInterface(with: FrequencyStatsHelperProtocol.self)
        
        self.helperConnection = helperConnection
        self.helperConnection?.resume()
        
        guard let proxy = self.helperConnection?.remoteObjectProxy as? FrequencyStatsHelperProtocol else {
            return
        }
        
        self.helperProxy = proxy
        
        // make a subcription to the IOReport on the XPC side
        self.helperProxy?.createSubscription()
        
        Logger.log("Subscribing to IOReport via Helper...")
    }
    
    
    public final func startSampleTimer() {
        self.sample()
        
        self.sampleTimer = Timer.scheduledTimer(withTimeInterval: AppSettings.shared.updateInterval, repeats: true, block: { _ in
            self.sample()
        })
    }
    
    public final func stopSampleTimer() {
        self.sampleTimer?.invalidate()
    }
    
    public final func sample() {
        guard let helperProxy = self.helperProxy else {
            return
        }
        
        Logger.log("Sampling", class: SampleManager.self)

        // make a sample (returns a dictionary of state values for our cores and clusters when enough samples are available for a delta)
        helperProxy.sample(clusterKeys: self.systemConstants.clusterKeys as NSArray, with: { dictionary in
            guard
                dictionary.count != 0,
                let mutableDictionary = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, dictionary.count, dictionary as CFDictionary),
                let samples = mutableDictionary as? [String : [UInt64]]
            else {
                Logger.log("Failed to sample", isError: true, class: SampleManager.self)
                return
            }
            
            var clusters = self.sampledClusters
            
            for (key, value) in samples {
                for clusterIndex in clusters.indices where key.contains(clusters[clusterIndex].clusterKey) {
                    
                    let clusterKey = clusters[clusterIndex].clusterKey
                    
                    clusters[clusterIndex].resetRawSums()
                    
                    if key == clusterKey { // if is cluster
                        for residenceIndex in value.indices where clusters[clusterIndex].dvfsStates.array.count - 1 >= residenceIndex {
                            let value = value[residenceIndex]
                            
                            clusters[clusterIndex].dvfsStates.array[residenceIndex].rawResidency = value // add to state residency
                            clusters[clusterIndex].dvfsStates.rawSums += value // increment rawSums
                        }
                        
                        var frequency: CGFloat = 0
                        
                        // format
                        for dvfmIndex in clusters[clusterIndex].dvfsStates.array.indices {
                            autoreleasepool {
                                let rawSums = clusters[clusterIndex].dvfsStates.rawSums
                                let nominalFrequency = clusters[clusterIndex].dvfsStates.array[dvfmIndex].nominalFrequency
                                let rawResidency = clusters[clusterIndex].dvfsStates.array[dvfmIndex].rawResidency
                                
                                let residency = CGFloat(rawResidency) / CGFloat(rawSums)
                                
                                clusters[clusterIndex].dvfsStates.array[dvfmIndex].residency = residency
                                
                                frequency += residency * CGFloat(nominalFrequency)
                            }
                        }
                        
                        clusters[clusterIndex].frequency.append(frequency)
                        
                        // handle frequency history
                        if clusters[clusterIndex].frequency.count > Cluster.maximumFrequencyCount {
                            clusters[clusterIndex].frequency.removeFirst()
                        }
                        
                    } else { // if is core
                        if let coreIndex = clusters[clusterIndex].cores.firstIndex(where: { $0.coreKey == key }) {
                            
                            for residenceIndex in value.indices where clusters[clusterIndex].cores[coreIndex].dvfsStates.array.count - 1 >= residenceIndex {
                                let value = value[residenceIndex]
                                
                                clusters[clusterIndex].cores[coreIndex].dvfsStates.array[residenceIndex].rawResidency = value
                                clusters[clusterIndex].cores[coreIndex].dvfsStates.rawSums += value
                            }
                            
                            clusters[clusterIndex].cores[coreIndex].frequency = 0
                            
                            // format
                            for dvfmIndex in clusters[clusterIndex].cores[coreIndex].dvfsStates.array.indices {
                                autoreleasepool {
                                    let rawSums = clusters[clusterIndex].cores[coreIndex].dvfsStates.rawSums
                                    let nominalFrequency = clusters[clusterIndex].cores[coreIndex].dvfsStates.array[dvfmIndex].nominalFrequency
                                    let rawResidency = clusters[clusterIndex].cores[coreIndex].dvfsStates.array[dvfmIndex].rawResidency
                                    
                                    let residency = CGFloat(rawResidency) / CGFloat(rawSums)
                                    
                                    clusters[clusterIndex].cores[coreIndex].dvfsStates.array[dvfmIndex].residency = residency
                                    
                                    clusters[clusterIndex].cores[coreIndex].frequency += residency * CGFloat(nominalFrequency)
                                }
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.sampledClusters = clusters
            }
            
            Logger.log("Added new metrics", class: SampleManager.self)
        })
    }
}
