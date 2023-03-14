//
//  FrequencyStatsHelper.swift
//  FrequencyStatsHelper
//
//  Created by BitesPotatoBacks on 3/11/23.
//

import Foundation

public class FrequencyStatsHelper: NSObject, FrequencyStatsHelperProtocol {
    private var subscription: IOReportSubscriptionRef?
    private var subbedChannels: CFMutableDictionary?
    private var samples: [CFDictionary] = []
    
    @objc public func createSubscription() {
        var subbbedChannels: Unmanaged<CFMutableDictionary>?

        let cpuStatsChannel: Unmanaged<CFMutableDictionary> = IOReportCopyChannelsInGroup("CPU Stats", nil, 0, 0, 0)
        let gpuStatsChannel: Unmanaged<CFMutableDictionary> = IOReportCopyChannelsInGroup("GPU Stats", nil, 0, 0, 0)
        
        IOReportMergeChannels(cpuStatsChannel.takeUnretainedValue(), gpuStatsChannel.takeUnretainedValue(), nil)
        
        let subscription: IOReportSubscriptionRef = IOReportCreateSubscription(nil, cpuStatsChannel.takeUnretainedValue(), &subbbedChannels, 0, nil)
        
        self.subscription = subscription
        self.subbedChannels = subbbedChannels?.takeUnretainedValue()
        
        Logger.log("Succesfully created subscription reference: \(subscription)", class: FrequencyStatsHelper.self)
    }

    @objc public func sample(clusterKeys: NSArray, with reply: @escaping (NSDictionary) -> Void) {
        let sample = IOReportCreateSamples(self.subscription, self.subbedChannels, nil)
        
        guard let clusterKeys = clusterKeys as? [String], let cfsample = sample?.takeUnretainedValue() else {
            reply(NSDictionary())
            return
        }
        
        self.samples.append(cfsample)
        sample?.release()
        
        if self.samples.count == 2 {
            guard
                let firstSample = self.samples.first,
                let lastSample = self.samples.last,
                let sampleDelta = IOReportCreateSamplesDelta(firstSample, lastSample, nil)
            else {
                reply(NSDictionary())
                return
            }
            
            var dictionary: [String : [UInt64]] = [:]
            
            IOReportIterate(sampleDelta.takeUnretainedValue(), { sample in
                autoreleasepool {
                    let subGroup: String = IOReportChannelGetSubGroup(sample)
                    
                    // make sure we have the right subgroups
                    guard subGroup == "CPU Complex Performance States" ||
                            subGroup == "CPU Core Performance States" ||
                            subGroup == "GPU Performance States" else {
                        return Int32(kIOReportIterOk)
                    }
                    
                    let channelName: String = IOReportChannelGetChannelName(sample)
                    
                    
                    // make sure we have the right channels
                    guard clusterKeys.contains(where: { channelName.contains($0) }), channelName != "BSTGPUPH" else {
                        return Int32(kIOReportIterOk)
                    }
                    
                    var states: [UInt64] = []
                    
                    // loop through every state of the channel
                    for state in 0..<IOReportStateGetCount(sample) {
                        autoreleasepool {
                            let indexName: String = IOReportStateGetNameForIndex(sample, state)
                            let residency: UInt64 = IOReportStateGetResidency(sample, state)
                            
                            // make sure the index is for a p- or v-state before collecting data
                            if indexName.contains("P") || indexName.contains("V") {
                                // add the states to our array of states
                                states.append(residency)
                            }
                        }
                    }
                    
                    // add out array of states to a dictionary
                    dictionary.updateValue(states, forKey: channelName)
                    
                    return Int32(kIOReportIterOk)
                }
            })
            
            // reply with the dictionary so we may reformat it from the main app
            reply(dictionary as NSDictionary)
            
            self.samples.removeFirst()
            
            sampleDelta.release()
            
            return
        }
        
        reply(NSDictionary())
    }
}
