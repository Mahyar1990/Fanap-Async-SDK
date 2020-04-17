//
//  Protocol.swift
//  Async
//
//  Created by Mahyar Zhiani on 5/21/1397 AP.
//  Copyright © 1397 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyJSON


// AsyncDelegate that the Chat Module have to implement to use them
public protocol AsyncDelegates: class {
    func asyncSendMessage(params: Any)
    func asyncConnect(newPeerID: Int)
    func asyncDisconnect()
    func asyncReconnect(newPeerID: Int)
    func asyncReceiveMessage(params: JSON)
    func asyncReady()
    func asyncStateChanged(socketState: SocketStateType, timeUntilReconnect: Int, deviceRegister: Bool, serverRegister: Bool, peerId: Int)
    func asyncError(errorCode: Int, errorMessage: String, errorEvent: Any?)
}


