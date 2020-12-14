//
//  Async.swift
//  Async
//
//  Created by Mahyar Zhiani on 5/9/1397 AP.
//  Copyright © 1397 Mahyar Zhiani. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON
import SwiftyBeaver
import Each
import Sentry


public var log = LogWithSwiftyBeaver(withLevel: nil).log

// this is the Async class that will handles Asynchronous messaging
public class Async {
    
    public weak var delegate: AsyncDelegates?
    
    var socketAddress:          String      // socket address
    var serverName:             String      // server to register on
    var deviceId:               String      // the user current device id
    
    var appId:                  String      //
    var peerId:                 Int         // pper id of the user on the server
    var messageTtl:             Int         //
    var reconnectOnClose:       Bool        // should i try to reconnet the socket whenever socket is close?
    var connectionRetryInterval:Int         // how many times to try to connet the socket
    var maxReconnectTimeInterval: Int
    
    // MARK: - Async initializer
    public init(socketAddress:          String,
                serverName:             String,
                deviceId:               String,
                appId:                  String?,
                peerId:                 Int?,
                messageTtl:             Int?,
                connectionRetryInterval:    Int?,
                maxReconnectTimeInterval:   Int?,
                reconnectOnClose:       Bool?,
                showDebuggingLogLevel:  LogLevel?) {
        
        if let logLevel = showDebuggingLogLevel {
            log = LogWithSwiftyBeaver(withLevel: logLevel).log
        }
        
        self.socketAddress = socketAddress
        self.serverName = serverName
        self.deviceId = deviceId
        
        if let theAppId = appId {
            self.appId = theAppId
        } else {
            self.appId = "POD-Chat"
        }
        if let thePeerId = peerId {
            self.peerId = thePeerId
        } else {
            self.peerId = 0
        }
        if let theMessageTtl = messageTtl {
            self.messageTtl = theMessageTtl
        } else {
            self.messageTtl = 5
        }
        if let theConnectionRetryInterval = connectionRetryInterval {
            self.connectionRetryInterval = theConnectionRetryInterval
        } else {
            self.connectionRetryInterval = 5
        }
        if let theReconnectOnClose = reconnectOnClose {
            self.reconnectOnClose = theReconnectOnClose
        } else {
            self.reconnectOnClose = true
        }
        
        if let maxReconnectTime = maxReconnectTimeInterval {
            self.maxReconnectTimeInterval = maxReconnectTime
        } else {
            self.maxReconnectTimeInterval = 60
        }
        
        startCrashAnalitics()
        startLastRecievedTimer()
    }
    
    
    var oldPeerId:          Int?
    var isSocketOpen        = false
    var isDeviceRegister    = false
    var isServerRegister    = false
    
    var socketState         = SocketStateType.CONNECTING
    
    var checkIfSocketHasOpennedTimeoutId:   Int = 0
    var socketReconnectRetryInterval:       Int = 0
    var socketReconnectCheck:               Int = 0
    
    var lastMessageId           = 0
    var retryStep:      Double  = 1
    
    var pushSendDataArr         = [[String: Any]]()
    
    var wsConnectionWaitTime:           Int = 5
    var connectionCheckTimeout:         Int = 8
    
    
    var socket: WebSocket?
    
    func startCrashAnalitics() {
        // Config for Sentry 4.3.1
        do {
            Client.shared = try Client(dsn: "https://28257522c08940c9bc43cf36c6c2610c:413a96b43f0242c4a23ad96a23aba86e@chatsentryweb.sakku.cloud/6")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
        }
        
        print("\n\n\n\n\n\nFirst Log on Async\n\n\n\n\n")
        
        let event = Event(level: SentrySeverity.error)
        event.message = "First Log on Async"
        Client.shared?.send(event: event, completion: { _ in })
        
    }
    
    var lrmTimer: Each!
    var lastReceivedMessageTime:    Date?
    func startLastRecievedTimer() {
        lrmTimer = Each((TimeInterval(self.connectionCheckTimeout) * 1.2)).seconds
        lrmTimer.perform {
            if let lastReceivedMessageTimeBanged = self.lastReceivedMessageTime {
                let elapsed = Date().timeIntervalSince(lastReceivedMessageTimeBanged)
                let elapsedInt = Int(elapsed)
                if (elapsedInt >= self.connectionCheckTimeout) {
                    DispatchQueue.main.async {
                        self.asyncSendPing()
                    }
                    self.lrmTimer.restart()
                }
            }
            // Do your operations
            // This closure has to return a NextStep value
            // Return .continue if you want to leave the timer active, otherwise
            // return .stop to invalidate it
            return .continue
        }
    }
    
    
    // MARK: Retry To Connect To Socket Timer
    var retryToConnectToSocketTimer: RepeatingTimer? {
        didSet {
            if (retryToConnectToSocketTimer != nil) {
                log.verbose("Async: retryToConnectToSocketTimer valueChanged: \n staus = \(self.retryToConnectToSocketTimer!.state) \n timeInterval = \(self.retryToConnectToSocketTimer!.timeInterval)", context: "Async")
                retryToConnectToSocketTimer?.eventHandler = {
                    if (self.retryStep < Double(self.maxReconnectTimeInterval)) {
                        self.retryStep = self.retryStep * 2
                    } else {
                        self.retryStep = Double(self.maxReconnectTimeInterval)
                    }
                    DispatchQueue.main.async {
                        self.socket?.connect()
                        self.retryToConnectToSocketTimer?.suspend()
                    }
                }
                retryToConnectToSocketTimer?.resume()
            } else {
                log.verbose("Async: retryToConnectToSocketTimer valueChanged to nil", context: "Async")
            }
        }
    }
    
    
    // MARK: Check Socket is Opened or not Timer
    // use to check if we can initial socket connection or not, at the start creation of Async (func startTimers)
    var checkIfSocketHasOpennedTimer:  RepeatingTimer? {
        didSet {
            if (checkIfSocketHasOpennedTimer != nil) {
                log.verbose("Async: checkIfSocketHasOpennedTimer valueChanged: \n staus = \(self.checkIfSocketHasOpennedTimer!.state) \n timeInterval = \(self.checkIfSocketHasOpennedTimer!.timeInterval)", context: "Async")
                checkIfSocketHasOpennedTimer?.eventHandler = {
                    self.checkIfSocketIsCloseOrNot()
                    self.checkIfSocketHasOpennedTimer?.suspend()
                }
                checkIfSocketHasOpennedTimer?.resume()
            } else {
                log.verbose("Async: checkIfSocketHasOpennedTimer valueChanged to nil", context: "Async")
            }
        }
    }
    
    
    // MARK: Register Server Timer
    var registerServerTimer: RepeatingTimer? {
        didSet {
            if (registerServerTimer != nil) {
                log.verbose("Async: registerServerTimer valueChanged: staus = \(self.registerServerTimer!.state) \n timeInterval = \(self.registerServerTimer!.timeInterval)", context: "Async")
                registerServerTimer?.eventHandler = {
                    self.self.retryToRegisterServer()
                    self.registerServerTimer?.suspend()
                }
                registerServerTimer?.resume()
            } else {
                log.verbose("Async: registerServerTimer valueChanged to nil.", context: "Async")
            }
        }
    }
    
}



