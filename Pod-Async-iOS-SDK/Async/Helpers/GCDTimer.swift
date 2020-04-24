//
//  GCDTimer.swift
//  Async
//
//  Created by Mahyar Zhiani on 5/17/1397 AP.
//  Copyright © 1397 Mahyar Zhiani. All rights reserved.
//G

import Foundation


// this is the timer class, that will handle the complexity of timer functionality
// it will uses many times on Async and also on Chat maybe
open class RepeatingTimer {
    
    public var timeInterval: TimeInterval
    
    public init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    public lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    
    public var eventHandler: (() -> Void)?
    
    public enum State {
        case suspended
        case resumed
    }
    
    public var state: State = .suspended
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        resume()
        guard let _ = eventHandler else { return }
        eventHandler = nil
    }
    
    public func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    public func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
