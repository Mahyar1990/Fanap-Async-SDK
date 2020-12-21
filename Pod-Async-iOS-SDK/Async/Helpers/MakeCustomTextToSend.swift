//
//  MakeCustomTextToSend.swift
//  FanapPodAsyncSDK
//
//  Created by Mahyar Zhiani on 3/22/1398 AP.
//  Copyright © 1398 Mahyar Zhiani. All rights reserved.
//

import Foundation
import SwiftyJSON


open class MakeCustomTextToSend {
    
    let textMessage: String
    
    public init(message: String) {
        self.textMessage = message
    }
    
    /*
     it's all about this 3 characters: 'space' , '\n', '\t'
     this function will put some freak characters instead of these 3 characters (inside the Message text content)
     because later on, the Async will eliminate from all these kind of characters to reduce size of the message that goes through socket,
     on there, we will replace them with the original one;
     so now we don't miss any of these 3 characters on the Test Message, but also can eliminate all extra characters...
     */
    public func replaceSpaceEnterWithSpecificCharecters() -> String {
        var returnStr = ""
        for c in textMessage {
            if (c == " ") {
                returnStr.append("Ⓢ")
            } else {
                returnStr.append(c)
            }
        }
        return returnStr
    }
    
    
    
    
    public func removeSpecificCharectersWithSpace() -> String {
        let compressedStr = String(textMessage.filter { !" ".contains($0) })
        let strWithSpace = compressedStr.replacingOccurrences(of: "Ⓢ", with: " ")
        
        return strWithSpace
    }
    
    
}



extension JSON {
    public func toString() -> String? {
        return self.rawString()?.replacingOccurrences(of: "\\s", with: "", options: String.CompareOptions.regularExpression, range: nil)
    }
}



