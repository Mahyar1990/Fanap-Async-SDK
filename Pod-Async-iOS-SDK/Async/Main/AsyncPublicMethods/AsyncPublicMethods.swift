//
//  AsyncPublicMethods.swift
//  FanapPodAsyncSDK
//
//  Created by Mahyar Zhiani on 3/22/1398 AP.
//  Copyright © 1398 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyJSON
import Starscream

// Public methods:
extension Async {
    
    
    // MARK: - Create Socket Connection
    /*
     this function will open a soccket connection to the server
     */
    public func createSocket() {
        var request = URLRequest(url: URL(string: socketAddress)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        startTimers()
        socket?.connect()
    }
    
    
    // MARK: - Get Async Status
    /*
     this method will return Async State (the value inside 'asyncState' property)
     */
    public func asyncGetAsyncState() -> JSON {
        let state: JSON = ["socketState": socketState.intValue(), "idDeviceRegistered": isDeviceRegister, "isServerRegistered": isServerRegister, "peerId": peerId]
        return state
    }
    
    // MARK: - Get PeerId
    /*
     this method will return peerId (the value inside 'peerId' property)
     */
    public func asyncGetPeerId() -> Int {
        return peerId
    }
    
    // MARK: - Get ServerName
    /*
     this method will return ServerName (the value inside 'ServerName' property)
     */
    public func asyncGetServerName() -> String {
        return serverName
    }
    
    // MARK: - Set ServerName
    /*
     this method will set a new name to ServerName
     */
    public func asyncSetServerName(_ newServerName: String) {
        serverName = newServerName
    }
    
    // MARK: - Set DeviceId
    /*
     this method will set new DeviceId
     */
    public func asyncSetDeviceId (_ newDeviceId: String) {
        deviceId = newDeviceId
    }
    
    // MARK: - Send Async Ping
    /*
     this method will send ping message throught Async
     */
    @objc public func asyncSendPing() {
        sendData(type: 0, content: nil)
    }
    
    // MARK: - Send Async Message
    /*
     this method will get content and prepare the data inside that to send
     */
    public func asyncSend(type: Int, content: String, receivers: [Int], priority: Int, ttl: Int) {
        lastMessageId += 1
        let messageId = lastMessageId
        
        let msgJSON: JSON = ["content": content, "receivers": receivers, "priority": priority, "messageId": messageId, "ttl": messageTtl]
        let msgContentStr = "\(msgJSON)"
        pushSendData(type: type, content: msgContentStr)
    }
    
    // MARK: - Reconnect socket
    /*
     this method will try to connect to socket again with my last peerId
     */
    public func asyncReconnectSocket() {
        oldPeerId = peerId
        isDeviceRegister = false
        isSocketOpen = false
        
        registerServerTimer?.suspend()
//        if let _ = rsTimer {
//            rsTimer!.stop()
//        }
        
        socket?.connect()
    }
    
    
    // MARK: - Disconnect from socket
    /*
     this method will disconnect Async from socket
     */
    public func asyncClose() {
        isDeviceRegister = false
        isServerRegister = false
        socketState = SocketStateType.CLOSED
        delegate?.asyncStateChanged(socketState:        socketState,
                                    timeUntilReconnect: 0,
                                    deviceRegister:     isDeviceRegister,
                                    serverRegister:     isServerRegister,
                                    peerId:             peerId)
        socket?.disconnect()
    }
    
    // MARK: - Log Out
    /*
     this method will log out the user with this account and then will close the socket
     */
    public func asyncLogOut() {
        oldPeerId = peerId
        peerId = 0
        isServerRegister = false
        isDeviceRegister = false
        isSocketOpen = false
        pushSendDataArr = []
        
        registerServerTimer?.suspend()
//        if let _ = rsTimer {
//            rsTimer!.stop()
//        }
        
        socketState = SocketStateType.CLOSED
        delegate?.asyncStateChanged(socketState:        socketState,
                                    timeUntilReconnect: 0,
                                    deviceRegister:     isDeviceRegister,
                                    serverRegister:     isServerRegister,
                                    peerId:             peerId)
        reconnectOnClose = false
        asyncClose()
    }
    
    
    
    // MARK: - prepare data to Send Message
    /*
     data comes here to be preapare to send
     this functin will decide to send it right away or put in on a Queue to send it later (based on the state of the socket connection)
     */
    public func pushSendData(type: Int, content: String) {
        if (socketState == SocketStateType.CONNECTED) {
            sendData(type: type, content: content)
        } else {
            sendDataToQueue(type: type, content: content)
        }
    }
    
    
}
