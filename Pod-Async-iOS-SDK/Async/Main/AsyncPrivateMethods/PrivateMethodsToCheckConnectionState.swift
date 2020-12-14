//
//  PrivateMethodsToCheckConnectionState.swift
//  FanapPodAsyncSDK
//
//  Created by Mahyar Zhiani on 3/22/1398 AP.
//  Copyright © 1398 Mahyar Zhiani. All rights reserved.
//

import Foundation


extension Async {
    
    
    // MARK: - Instantiate Timer
    func startTimers() {
        checkIfSocketHasOpennedTimer = nil
        checkIfSocketHasOpennedTimer = RepeatingTimer(timeInterval: 65)
    }
    
    
    // MARK: - Check socket connection if it's Closed or not
    /*
     this method will check the socket connection if it's Open or not,
     and then send the socket status to delegate
     */
    func checkIfSocketIsCloseOrNot() {
        DispatchQueue.main.async {
            if (!self.isSocketOpen) {
                let err: [String : Any] = ["errorCode": 4001, "errorMessage": "Can not open Socket!"]
                print("\(err)")
                log.error("\(err)", context: "Async")
                
                self.delegate?.asyncError(errorCode:    4001,
                                          errorMessage: "Can not open Socket!",
                                          errorEvent:   nil)
            } else {
                self.delegate?.asyncStateChanged(socketState:           self.socketState,
                                                 timeUntilReconnect:    0,
                                                 deviceRegister:        self.isDeviceRegister,
                                                 serverRegister:        self.isServerRegister,
                                                 peerId:                self.peerId)
            }
        }
    }
    
    // MARK: - Connect to Server
    /*
     this method will try to connect to the server, by oppening the socket connection
     */
    func connecntToSocket() {
        DispatchQueue.main.async {
            self.socket?.connect()
        }
    }
    
}
