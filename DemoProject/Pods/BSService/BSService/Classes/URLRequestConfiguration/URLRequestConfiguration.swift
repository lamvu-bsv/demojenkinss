//
//  URLRequestConfiguration.swift
//  Tavi
//
//  Created by Hien Pham on 11/29/17.
//  Copyright © 2017 Bravesoft VN. All rights reserved.
//

import UIKit
import Alamofire
public typealias HTTPMethodConvenience = HTTPMethod // Try to make HTTPMethod global, not having to import Alamofire each time create service

public class URLRequestConfiguration: NSObject {
    public var url: String?
    public var urlParams: Dictionary<String, String>?
    public var headerParams: Dictionary<String, String>?
    public var bodyParams: Dictionary<String, Any>?
    public var timeout: Double = 60.0 // Default is 10 seconds
    public var cachePolicy: NSURLRequest.CachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
    public func urlStringFilledWithParams() -> String {
        var url : String! = self.url != nil ? self.url : ""
        if (self.urlParams != nil && self.urlParams!.keys.count > 0) {
            for key in self.urlParams!.keys {
                url = url.replacingOccurrences(of: key, with: self.urlParams![key]!)
            }
        }
        return url
    }
    
    public override var description: String {
        var description : String = String(format: "URL %@", self.urlStringFilledWithParams())
        if self.headerParams != nil && self.headerParams!.keys.count > 0 {
            description += String(format: "\nHeaders: %@", self.headerParams!.bv_jsonString())
        }
        return description;
    }
    
    static func string(fromObject object : Any?) -> String {
        var str : String = ""
        if let unwrapped : Array<Any> = object as? Array {
            str = unwrapped.bv_jsonString()
        } else if let unwrapped : Dictionary<AnyHashable, Any> = object as? Dictionary {
            str = unwrapped.bv_jsonString()
        } else if let unwrapped: Any = object {
            str = String(describing: unwrapped)
        }
        return str
    }
}
