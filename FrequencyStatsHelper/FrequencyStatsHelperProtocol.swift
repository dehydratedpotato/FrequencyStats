//
//  FrequencyStatsHelperProtocol.swift
//  FrequencyStatsHelper
//
//  Created by BitesPotatoBacks on 3/11/23.
//

import Foundation

@objc public protocol FrequencyStatsHelperProtocol {
    func createSubscription()
    func sample(clusterKeys: NSArray, with reply: @escaping (NSDictionary) -> Void)
}
