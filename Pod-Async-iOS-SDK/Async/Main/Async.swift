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


public let log = LogWithSwiftyBeaver().log

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
    public init(socketAddress:      String,
                serverName:         String,
                deviceId:           String,
                appId:              String?,
                peerId:             Int?,
                messageTtl:         Int?,
                connectionRetryInterval: Int?,
                maxReconnectTimeInterval: Int?,
                reconnectOnClose:   Bool?) {
        
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
    var connectionCheckTimeout:         Int = 10
    
    
    var socket: WebSocket?
    
    
    
    // MARK: Last Received Message Timer
    // used to close socket if needed (func handleIfNeedsToCloseTheSocket)
    var lastReceivedMessageTime:    Date?
    var lastReceivedMessageTimer:   RepeatingTimer? {
        didSet {
            if (lastReceivedMessageTimer != nil) {
                log.verbose("Async: lastReceivedMessageTimer valueChanged: \n staus = \(self.lastReceivedMessageTimer!.state) \n timeInterval = \(self.lastReceivedMessageTimer!.timeInterval) \n lastReceivedMessageTime = \(lastReceivedMessageTime ?? Date())", context: "Async")
                self.lastReceivedMessageTimer?.suspend()
                DispatchQueue.global().async {
                    self.lastReceivedMessageTimer?.eventHandler = {
                        if let lastReceivedMessageTimeBanged = self.lastReceivedMessageTime {
                            let elapsed = Date().timeIntervalSince(lastReceivedMessageTimeBanged)
                            let elapsedInt = Int(elapsed)
                            if (elapsedInt >= self.connectionCheckTimeout) {
                                DispatchQueue.main.async {
                                }
                                self.lastReceivedMessageTimer?.suspend()
                            }
                        }
                    }
                    self.lastReceivedMessageTimer?.resume()
                }
            } else {
                log.verbose("Async: lastReceivedMessageTimer valueChanged to nil, \n lastReceivedMessageTime = \(lastReceivedMessageTime ?? Date())", context: "Async")
            }
        }
    }
    
    
    // MARK: Last Sent Message Timer
    // used to live the socket connection (func sendData)
    var lastSentMessageTime:    Date?
    var lastSentMessageTimer:   RepeatingTimer? {
        didSet {
            if (lastSentMessageTimer != nil) {
                log.verbose("Async: lastSentMessageTimer valueChanged: \n staus = \(self.lastSentMessageTimer!.state) \n timeInterval = \(self.lastSentMessageTimer!.timeInterval) \n lastSentMessageTime = \(lastSentMessageTime ?? Date())", context: "Async")
                self.lastSentMessageTimer?.suspend()
                DispatchQueue.global().async {
                    self.lastSentMessageTime = Date()
                    self.lastSentMessageTimer?.eventHandler = {
                        if let lastSendMessageTimeBanged = self.lastSentMessageTime {
                            let elapsed = Date().timeIntervalSince(lastSendMessageTimeBanged)
                            let elapsedInt = Int(elapsed)
                            if (elapsedInt >= self.connectionCheckTimeout) {
                                DispatchQueue.main.async {
                                    self.asyncSendPing()
                                }
                                if let _ = self.lastSentMessageTimer {
                                    self.lastSentMessageTimer?.suspend()
                                }
                            }
                        }
                    }
                    self.lastSentMessageTimer?.resume()
                }
            } else {
                log.verbose("Async: lastSentMessageTimer valueChanged to nil, \n lastSentMessageTime = \(lastSentMessageTime ?? Date())", context: "Async")
            }
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



