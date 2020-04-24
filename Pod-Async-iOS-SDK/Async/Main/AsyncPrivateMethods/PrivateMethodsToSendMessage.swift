//
//  PrivateMethodsToSendMessage.swift
//  FanapPodAsyncSDK
//
//  Created by Mahyar Zhiani on 3/22/1398 AP.
//  Copyright © 1398 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyJSON


// MARK: - Prepare Message to Send through Async

extension Async {
    
    
    // MARK: - make Device Register Message
    /*
     this is the function that will make message to Register Device
     here, we have PeerId, and the next step is to Register Device
     */
    func registerDevice() {
        log.verbose("make Device Register Message", context: "Async")
        
        var content: JSON = []
        if (peerId == 0) {
            content = ["appId": appId, "deviceId": deviceId, "renew": true]
        } else {
            content = ["appId": appId, "deviceId": deviceId, "refresh": true]
        }
        let contentStr = "\(content)"
        pushSendData(type: asyncMessageType.DEVICE_REGISTER.rawValue, content: contentStr)
    }
    
    // MARK: - make Server Register Message
    /*
     this is the function that will make message to Register Server
     here, we have PeerId, and the Device Registered befor,
     and the next step is to Register Server
     */
    func registerServer() {
        log.verbose("make Server Register Message", context: "Async")
        
        let content: JSON = ["name": serverName]
        let contentStr = "\(content)"
        pushSendData(type: asyncMessageType.SERVER_REGISTER.rawValue, content: contentStr)
        
        registerServerTimer = nil
        registerServerTimer = RepeatingTimer(timeInterval: TimeInterval(connectionRetryInterval))
    }
    
    
    
    // MARK: - Send Message logically
    /*
     this method will send data through socket connection logically.
     first of all, set a timer to keep the socket connection alive;
     then if the socket connection state was "OPEN", send the data
     */
    func sendData(type: Int, content: String?) {
        DispatchQueue.main.async {
            self.lastSentMessageTimer = nil
            self.lastSentMessageTimer = RepeatingTimer(timeInterval: TimeInterval(self.connectionCheckTimeout))
        }
        
        if (socketState == SocketStateType.CONNECTED) {
            var message: JSON
            if let cont = content {
                message = ["type": type, "content": cont]
            } else {
                message = ["type": type]
            }
            let messageStr: String = "\(message)"
            delegate?.asyncSendMessage(params: message)
            
            // these 4 lines are to remove some characters (like: space, \n , \t) exept tho ones that are in the message text context
            //            let compressedStr = String(messageStr.filter { !" \n\t\r".contains($0) })
            //            let strWithReturn = compressedStr.replacingOccurrences(of: "Ⓝ", with: "\n")
            //            let strWithSpace = strWithReturn.replacingOccurrences(of: "Ⓢ", with: " ")
            //            let strWithTab = strWithSpace.replacingOccurrences(of: "Ⓣ", with: "\t")
            
            let finalMessage = MakeCustomTextToSend(message: messageStr).removeSpecificCharectersWithSpace()
            
            log.debug("this message sends through socket: \n \(finalMessage)", context: "Async")
            
            socket?.write(string: finalMessage)
        }
    }
    
    // MARK: - Hold Messages (that have to be send) on a queue
    /*
     this method will hold messages to send them later.
     (this will contain messges on a queue)
     */
    func sendDataToQueue(type: Int, content: String) {
        log.verbose("send data to queue", context: "Async")
        
        let obj = ["type": type, "content": content] as [String : Any]
        pushSendDataArr.append(obj)
    }
    
    // MARK: - send data from queue to Send function
    /*
     this method will get the messages from queue and pass them to SendData function to send them
     after that, it will remove that message the queue
     */
    func sendDataFromQueueToSocekt() {
        for (i, item) in pushSendDataArr.enumerated().reversed() {
            if socketState == SocketStateType.CONNECTED {
                let type: Int = item["type"] as! Int
                let content: String = item["content"] as! String
                sendData(type: type, content: content)
                pushSendDataArr.remove(at: i)
            }
        }
    }
    
    
    // MARK: - Retry Server Registeration
    /*
     this method will try to do the 'Server Register' functionality
     */
    @objc func retryToRegisterServer() {
        DispatchQueue.main.async {
            if (!self.isServerRegister) {
                self.registerServer()
            }
        }
    }
    
    
}
