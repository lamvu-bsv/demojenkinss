//
//  ArrayUtils.swift
//  Tavi
//
//  Created by Hien Pham on 12/21/17.
//  Copyright © 2017 Bravesoft VN. All rights reserved.
//

import Foundation

// MARK: JSON generate
extension Array {
    public func bv_jsonString(prettyPrint : Bool = true) -> String {
        do {
            let jsonData : Data = try JSONSerialization.data(withJSONObject: self, options: (prettyPrint ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions.init(rawValue: 0)))
            let string : String = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
            return string
        } catch {
            NSLog("bv_jsonStringWithPrettyPrint: error: ", [error.localizedDescription])
            return ""
        }
    }
}
