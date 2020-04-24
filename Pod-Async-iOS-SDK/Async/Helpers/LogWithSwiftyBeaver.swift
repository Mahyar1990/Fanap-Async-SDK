//
//  LogConfigurations.swift
//  Async
//
//  Created by Mahyar Zhiani on 8/30/1397 AP.
//  Copyright © 1397 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyBeaver


open class LogWithSwiftyBeaver {
    
    public let log = SwiftyBeaver.self
    
    init() {
        configLogs()
    }
    
    // MARK: - config Logs
    public func configLogs() {
        // add log destinations. at least one is needed!
        
        // 1-------------------------------------------------------------
        // MARK: - log to Xcode Console:
        let console = ConsoleDestination()
        
        // setup format of loging to Xcode Console
        let consoleFormatString: String = """
\n
________________________________________________________________________________________________
||--------------------------------------------------------------------------------------------||
|| $C$L                                                                                  ||
||  _____________________________________________________________________                     ||
|| |     time     |  line  | class.function\t\t\t\t\t| thread
|| | $U |  $l  | $N.$F\t\t| $T
||  ---------------------------------------------------------------------                     ||
|| | Message:                                                                                 ||
|| | $M
|| |
||  ---------------------------------------------------------------------                     ||
|| | Additional information:                                                                  ||
|| | $X
||  ---------------------------------------------------------------------                     ||
||____________________________________________________________________________________________||
------------------------------------------------------------------------------------------------\n
"""
        console.format = consoleFormatString
        
        /*
         // set global minLevel (verbose, info, debug, warning, error)
         console.minLevel = .error
         */
//        console.minLevel = .verbose
        console.minLevel = .debug
        
        /*
         // set Path Filter to a certain class
         let filter1 = Filters.Path.contains("Chat", minLevel: .debug)
         console.addFilter(filter1)
         */
        
        /*
         // set Function Filter to a certain function of a certain class
         let filter1 = Filters.Path.contains("UnicornViewController", required: true)
         let filter2 = Filters.Function.contains("viewDidLoad", required: true)
         console.addFilter(filter1)
         console.addFilter(filter2)
         */
        
        /*
         // Silence File with Exclusion:
         console.addFilter(Filters.Path.excludes("Horse", required: true)
         */
        
        log.addDestination(console)
        
        
        // 2-------------------------------------------------------------
        // MARK: - log to default swiftybeaver.log file
        let file = FileDestination()
        /*
         // Log Certain Message to an own Destination
         file.logFileURL = URL(string: "file:///tmp/myNetworkLogs.log")
         file.addFilter(Filters.Message.contains("HTTP", caseSensitive: true, required: true))
         */
        log.addDestination(file)
        
        
        // 3-------------------------------------------------------------
        // MARK: -
        let platform = SBPlatformDestination(appID: "Z5RkJe", appSecret: "UDxfbvnmxyin4kydENQprhw5tths0bvo", encryptionKey: "t9ugl6wkcvp9w2yRvma0ykpfqy94TjzI")
        
        log.addDestination(platform)
    }
    
    
    
    
}

