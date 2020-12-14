//
//  MethodsOnSocketConnection.swift
//  FanapPodAsyncSDK
//
//  Created by Mahyar Zhiani on 3/22/1398 AP.
//  Copyright © 1398 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyJSON


// MARK: - Methods on socket connection
extension Async {
    
    // MARK: - Socket Oppend
    /*
     when socket is connected, this function will trigger
     */
    func handleOnOppendSocket() {
        log.verbose("Handle On Oppend Socket", context: "Async")
        
        DispatchQueue.global().async {
            self.checkIfSocketHasOpennedTimer?.suspend()
        }
        isSocketOpen = true
        delegate?.asyncConnect(newPeerID: peerId)
        retryStep = 1
        socketState = SocketStateType.CONNECTED
        delegate?.asyncStateChanged(socketState:        socketState,
                                    timeUntilReconnect: 0,
                                    deviceRegister:     isDeviceRegister,
                                    serverRegister:     isServerRegister,
                                    peerId:             peerId)
    }
    
    
    // MARK: - Socket Closed
    /*
     when socket is closed, this function will trigger
     this function will reset some variables such as: 'isSocketOpen', 'isDeviceRegister', 'socketState', but keep 'oldPeerId'
     then sends 'asyncStateChanged' delegate
     after that will try to connect to socket again (if 'reconnectOnClose' has set 'true' by the client)
     */
    func handleOnClosedSocket() {
        log.verbose("Handle On Closed Socket", context: "Async")
        
        isSocketOpen = false
        isDeviceRegister = false
        oldPeerId = peerId
        
        socketState = SocketStateType.CLOSED
        
        delegate?.asyncStateChanged(socketState:        socketState,
                                    timeUntilReconnect: 0,
                                    deviceRegister:     isDeviceRegister,
                                    serverRegister:     isServerRegister,
                                    peerId:             peerId)
        delegate?.asyncDisconnect()
        
        // here, we try to connect to the socket on specific period of time
        if (reconnectOnClose) {
            socketState = SocketStateType.CLOSED
            delegate?.asyncStateChanged(socketState:        socketState,
                                        timeUntilReconnect: Int(retryStep),
                                        deviceRegister:     isDeviceRegister,
                                        serverRegister:     isServerRegister,
                                        peerId:             peerId)
            
            retryToConnectToSocketTimer = nil
            retryToConnectToSocketTimer = RepeatingTimer(timeInterval: retryStep)
            
        } else {
            delegate?.asyncError(errorCode:     4005,
                                 errorMessage:  "Socket Closed!",
                                 errorEvent:    nil)
            delegate?.asyncStateChanged(socketState:        socketState,
                                        timeUntilReconnect: 0,
                                        deviceRegister:     isDeviceRegister,
                                        serverRegister:     isServerRegister,
                                        peerId:             peerId)
        }
        
    }
    
    // MARK: - Message Recieved
    /*
     when a message recieves from the socket connection, this function will trigger
     base on the type of the message, we do sth
     types:
     0: PING
     1: SERVER_REGISTER
     2: DEVICE_REGISTER
     3: MESSAGE
     4: MESSAGE_ACK_NEEDED
     5: ACK
     6: ERROR_MESSAGE
     */
    func handleOnRecieveMessage(messageRecieved: String) {
        log.debug("This Message Recieves from socket: \n\(messageRecieved)", context: "Async - RecieveFromSocket")
        
        lastReceivedMessageTime = Date()
        
        if let dataFromMsgString = messageRecieved.data(using: .utf8, allowLossyConversion: false) {
            do {
                let msg = try JSON(data: dataFromMsgString)
                
                switch msg["type"].intValue {
                case asyncMessageType.PING.rawValue:
                    handlePingMessage(message: msg)
                case asyncMessageType.SERVER_REGISTER.rawValue:
                    handleServerRegisterMessage(message: msg)
                    
                case asyncMessageType.DEVICE_REGISTER.rawValue:
                    handleDeviceRegisterMessage(message: msg)
                    
                case asyncMessageType.MESSAGE.rawValue:
                    delegate?.asyncReceiveMessage(params: msg)
                    
                case asyncMessageType.MESSAGE_ACK_NEEDED.rawValue, asyncMessageType.MESSAGE_SENDER_ACK_NEEDED.rawValue:
                    handleSendACK(messageContent: msg)
                    delegate?.asyncReceiveMessage(params: msg)
                    
                case asyncMessageType.ACK.rawValue:
                    delegate?.asyncReceiveMessage(params: msg)
                    
                case asyncMessageType.ERROR_MESSAGE.rawValue:
                    delegate?.asyncError(errorCode:     4002,
                                         errorMessage:  "Async Error!",
                                         errorEvent:    msg)
                    
                default:
                    return
                }
            } catch {
                log.error("can not convert incoming String Message to JSON", context: "Async")
            }
        } else {
            log.error("the message comming from server, is not on the correct format!!", context: "Async")
        }
        
        // set timer to check if needed to close the socket!
        handleIfNeedsToCloseTheSocket()
    }
    
    
    
    
    // Close Socket connection if needed
    func handleIfNeedsToCloseTheSocket() {
        lrmTimer.stop()
        lrmTimer.restart()
    }
    
    // MARK: - Sends Ping Message
    /*
     this is the function that sends Ping Message to the server
     */
    func handlePingMessage(message: JSON) {
        if (!isDeviceRegister) {
            if (message["id"].int != nil) {
                registerDevice()
            } else {
                delegate?.asyncError(errorCode:     4003,
                                     errorMessage:  "Device Id is not present!",
                                     errorEvent:    nil)
            }
        }
        
    }
    
    // MARK: - Register Device
    /*
     device registered message comes from server, and in its content, it has 'peerId' of the user
     we set 'isDeviceRegister' to 'true', and set 'peerId'
     and also send 'asyncStateChanged' to delegate
     */
    func handleDeviceRegisterMessage(message: JSON) {
        guard message != [] else { return }
        if (!isDeviceRegister) {
            isDeviceRegister = true
            peerId = message["content"].intValue
        }
        
        peerId = message["content"].intValue
        socketState = SocketStateType.CONNECTED
        
        delegate?.asyncStateChanged(socketState:        socketState,
                                    timeUntilReconnect: 0,
                                    deviceRegister:     isDeviceRegister,
                                    serverRegister:     isServerRegister,
                                    peerId:             peerId)
        if (isServerRegister == true && peerId == oldPeerId) {
            sendDataFromQueueToSocekt()
            delegate?.asyncReady()
        } else {
            
            log.info("Device has Registered successfully", context: "Async")
            registerServer()
        }
    }
    
    // MARK: - Register Server
    /*
     Server registered message comes from server
     we set 'isServerRegister' to 'true', and set 'socketState' to 'OPEN' state
     and then send 'asyncStateChanged' to delegate, and of course 'asyncReady'
     */
    func handleServerRegisterMessage(message: JSON) {
        guard message != [] else { return }
        if let senderName = message["senderName"].string {
            if (senderName == serverName) {
                isServerRegister = true
                // reset and stop registerServerTimeoutId
                socketState = SocketStateType.CONNECTED
                delegate?.asyncStateChanged(socketState:        socketState,
                                            timeUntilReconnect: 0,
                                            deviceRegister:     isDeviceRegister,
                                            serverRegister:     isServerRegister,
                                            peerId:             peerId)
                
                log.info("Server has Registered successfully", context: "Async")
                
                delegate?.asyncReady()
                sendDataFromQueueToSocekt()
            }
        } else {
            registerServer()
        }
        
    }
    
    // MARK: - Send ACK
    /*
     try to send ACk to server for the message that comes from server and it need ACK for this message
     */
    func handleSendACK(messageContent: JSON) {
        guard messageContent != [] else {
            log.warning("Message Content is empty", context: "Async")
            return
        }
        let msgId = messageContent["id"].int ?? -1
        let content: JSON = ["messageId": msgId]
        let msgIdStr = "\(content)"
        log.verbose("try to send Ack message with id: \(msgIdStr)", context: "Async")
        
        pushSendData(type: asyncMessageType.ACK.rawValue, content: msgIdStr)
    }
    
    
    
}
