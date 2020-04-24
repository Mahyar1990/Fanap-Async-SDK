//
//  WebSocketImplementation.swift
//  Async
//
//  Created by Mahyar Zhiani on 7/23/1397 AP.
//  Copyright © 1397 Mahyar Zhiani. All rights reserved.
//

import Foundation
import Starscream
import SwiftyBeaver


// implement websocket delegate methods
extension Async: WebSocketDelegate {
    
    public func websocketDidConnect(socket: WebSocketClient) {
        handleOnOppendSocket()
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        handleOnClosedSocket()
        
        if let myError = error {
            log.error("socket closed error = \(myError)", context: "Async")
        } else {
            log.error("socket closed error", context: "Async")
        }
        
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        handleOnRecieveMessage(messageRecieved: text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
    
}



