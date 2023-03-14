//
//  Logger.swift
//  FrequencyStats
//
//  Created by BitesPotatoBacks on 3/13/23.
//

import Foundation

public struct Logger {
    public static func log(_ message: String, isError: Bool = false, class className: AnyClass? = nil, function: String = #function, line: Int = #line) {
#if DEBUG
        let stringStub = isError ? " (ERROR) " : " "
        
        if let className = className {
            print("***\(stringStub)[\(line):\(NSStringFromClass(className)).\(function)] \(message) ***")
            return
        }
        
        print("***\(stringStub)[\(line):\(function)] \(message) ***")
        return
#endif
    }
}
