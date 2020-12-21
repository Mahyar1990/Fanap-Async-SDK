//
//  LogLevel.swift
//  FanapPodAsyncSDK
//
//  Created by MahyarZhiani on 9/24/1399 AP.
//  Copyright © 1399 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyBeaver


public enum LogLevel {
    case error
    case warning
    case debug
    case info
    case verbose
    
    func swiftyBeaverLevel() -> SwiftyBeaver.Level {
        switch self {
        case .error:    return SwiftyBeaver.Level.error
        case .warning:  return SwiftyBeaver.Level.warning
        case .debug:    return SwiftyBeaver.Level.debug
        case .info:     return SwiftyBeaver.Level.info
        case .verbose:  return SwiftyBeaver.Level.verbose
        }
    }
}
