//
//  URLRequestPostFileConfiguration.swift
//  BSService
//
//  Created by Hien Pham on 3/25/19.
//

import UIKit

public class URLRequestPostFileConfiguration : URLRequestConfiguration {
    public var method : HTTPMethodConvenience = .post
    public var files : Array<URLRequestFileConfiguration>?
    
    public override var description: String {
        var description : String = super.description
        description = String(format: "%@ to", self.method.rawValue) + description
        if self.bodyParams != nil && self.bodyParams!.keys.count > 0 {
            description += String(format: "\nBody Params: %@", self.bodyParams!.bv_jsonString())
        }
        if let files = self.files {
            for file in files {
                description += "\n" + file.description
            }
        }
        return description;
    }
}
