//
//  File.swift
//  Async
//
//  Created by Mahyar Zhiani on 7/23/1397 AP.
//  Copyright © 1397 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyBeaver

public enum asyncMessageType: Int {
    case PING                       = 0
    case SERVER_REGISTER            = 1
    case DEVICE_REGISTER            = 2
    case MESSAGE                    = 3
    case MESSAGE_ACK_NEEDED         = 4
    case MESSAGE_SENDER_ACK_NEEDED  = 5
    case ACK                        = 6
    case GET_REGISTERED_PEERS       = 7
    case PEER_REMOVED               = -3
    case REGISTER_QUEUE             = -2
    case NOT_REGISTERED             = -1
    case ERROR_MESSAGE              = -99
}
