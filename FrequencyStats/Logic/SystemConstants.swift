//
//  SystemConstants.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/11/23.
//

import Foundation

public extension Data {
    var uint32: UInt32 {
        let array = self.withUnsafeBytes { $0.load(as: UInt32.self) }
        return UInt32(bigEndian: array)
    }
}

public struct SystemConstants {
    public static let voltageStates: [String : CFString] = ["ECPU" : "voltage-states1-sram" as CFString,
                                                            "PCPU" : "voltage-states5-sram" as CFString,
                                                            "GPU" : "voltage-states9" as CFString]
    public var clusterKeys: [String] = []
    public var coreKeys: [String] = []
    public var clusterCoreCounts: [Int] = []
    public var dvfsStateDictionary: [String : [DvfsState]] = [:]
    
    public lazy var systemModel: String = {
        var size: Int = 0
        let ret = sysctlbyname("hw.model", nil, &size, nil, 0)
        
        guard ret == 0 else {
            return "Unknown SoC"
        }
    
        var string = [CChar](repeating: 0, count: Int(size))

        sysctlbyname("hw.model", &string, &size, nil, 0)
        
        let modelname = String(cString: string).lowercased()
        
        guard !modelname.contains("virtual") else {
            fatalError("This app cannot be run on a VM")
        }
        
        return modelname
    }()
    
    // MARK: - Lifecycle
    
    public init() {
        guard let service = IOServiceMatching("AppleARMIODevice") else {
            fatalError("Failed to access AppleARMIODevice")
        }
        
        var iterator: io_iterator_t = 0
        
        if #available(macOS 12.0, *) {
            guard IOServiceGetMatchingServices(kIOMainPortDefault, service, &iterator) == kIOReturnSuccess else {
                return
            }
        } else {
            guard IOServiceGetMatchingServices(kIOMasterPortDefault, service, &iterator) == kIOReturnSuccess else {
                return
            }
        }
        
        while case let entry = IOIteratorNext(iterator), entry != IO_OBJECT_NULL {
            guard self.clusterCoreCounts.isEmpty, self.dvfsStateDictionary.isEmpty else {
                break
            }
            
            var properties: Unmanaged<CFMutableDictionary>? = nil
            
            IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
            
            guard let array = properties?.takeUnretainedValue() as? [CFString: Any] else {
                break
            }
            
            for property in array {
                self.getCoreCounts(from: property)
                self.getDvfsStates(from: property)
            }
        }
    
        self.createKeys()
    }
    
    // MARK: - Mutating Funcs
    
    private mutating func createKeys() {
        var coreKeys: [String] = []
        var clusterKeys: [String] = []
        
        if self.systemModel.contains("pro") || self.systemModel.contains("max") {
            clusterKeys = ["ECPU","PCPU0","PCPU1","GPUPH"]
            
            coreKeys = ["ECPU0","PCPU0","PCPU1"]
        } else if self.systemModel.contains("ultra") {
            clusterKeys = ["DIE_0_ECPU","DIE_1_ECPU","DIE_0_PCPU","DIE_0_PCPU1","DIE_1_PCPU","DIE_1_PCPU1","GPUPH"]
            
            coreKeys = ["DIE_0_ECPU_CPU","DIE_1_ECPU_CPU","DIE_0_PCPU_CPU","DIE_0_PCPU1_CPU","DIE_1_PCPU_CPU","DIE_1_PCPU1_CPU"]
        } else {
            clusterKeys = ["ECPU","PCPU","GPUPH"]
            
            coreKeys = ["ECPU","PCPU"]
        }
        
        Logger.log("Got new cluster key array: \(clusterKeys)")
        Logger.log("Got new core key array: \(coreKeys)")
        
        self.coreKeys = coreKeys
        self.clusterKeys = clusterKeys
    }
    
    private mutating func getCoreCounts(from property: (key: CFString, value: Any)) {
        guard property.key as String == "clusters", let data = property.value as? Data else {
            return
        }
        
        var clusterCores: [Int] = []

        for i in stride(from: 0, to: data.count, by: 4) {
            clusterCores.append(Int(data[i]))
            
            if self.systemModel.contains("ultra") {
                clusterCores.append(Int(data[i]))
            }
        }
        
        Logger.log("Got new core count array: \(clusterCores)")
        
        self.clusterCoreCounts = clusterCores
    }
    
    private mutating func getDvfsStates(from property: (key: CFString, value: Any)) {
        guard
            let state = SystemConstants.voltageStates.first(where: { $0.value == property.key }),
            let data = property.value as? Data
        else {
            return
        }

        var dvfsStates: [DvfsState] = []

        for i in stride(from: 0, to: data.count, by: 8) {
            let bytes = [data[i+3], data[i+2], data[i+1], data[i]]
            let data = Data(bytes)

            let dvfsState = DvfsState(nominalFrequency: data.uint32 / 1_000_000, residency: 0)

            dvfsStates.append(dvfsState)
        }
        
        if state.key == "GPU" {
            dvfsStates.removeFirst() // doing this because the first GPU voltage state is 0
        }
        
        Logger.log("Got new dvfs stable: \(dvfsStates)")

        self.dvfsStateDictionary.updateValue(dvfsStates, forKey: state.key)
    }
}
