//
//  ObjectParser.swift
//  Tavi
//
//  Created by Hien Pham on 4/18/18.
//  Copyright © 2018 Bravesoft VN. All rights reserved.
//

import UIKit

open class ObjectParser: BSServiceParser {
    open override func parseJson(_ object: Any?) -> Any? {
        if let json : Dictionary<AnyHashable, Any> = object as? Dictionary<AnyHashable, Any> {
            let objectInfo = self.object(fromJson: json)
            return objectInfo
        } else if let array : Array<Dictionary<AnyHashable, Any>> = object as? Array<Dictionary<AnyHashable, Any>> {
            var objectInfos : Array<Any> = Array()
            for objectJson : Dictionary<AnyHashable, Any> in array {
                if let unwrapped = self.object(fromJson: objectJson) {
                    objectInfos.append(unwrapped)
                }
            }
            return objectInfos
        } else {
            return nil
        }
    }
    
    // Override this function to custom parse object from json
    open func object(fromJson json: Dictionary<AnyHashable, Any>?) -> Any? {
        return json
    }
}
