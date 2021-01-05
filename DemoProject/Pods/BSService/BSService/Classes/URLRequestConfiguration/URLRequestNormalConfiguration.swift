//
//  URLRequestNormalConfiguration.swift
//  BSService
//
//  Created by Hien Pham on 3/25/19.
//

import UIKit
import Alamofire

public class URLRequestNormalConfiguration : URLRequestConfiguration {
    public var method : HTTPMethodConvenience = .get
    public var encoding: ParameterEncoding = URLEncoding.default
    public override var description: String {
        var description : String = super.description
        description = String(format: "HTTPMethod %@ ", self.method.rawValue) + description
        if self.method != HTTPMethod.get {
            if self.bodyParams != nil && self.bodyParams!.keys.count > 0 {
                description += String(format: "\nBody Params: \n%@", self.bodyParams!.bv_jsonString())
            }
        }
        return description;
    }
    
    public override func urlStringFilledWithParams() -> String {
        var url = super.urlStringFilledWithParams()
        if self.method == HTTPMethod.get, let bodyParams: Dictionary<String, String> = self.bodyParams as? Dictionary<String, String>, var components: URLComponents = URLComponents(string: url) {
            var queryItems: Array<URLQueryItem> = components.queryItems ?? Array()
            for (key, value) in bodyParams {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            components.queryItems = queryItems
            url = components.string ?? ""
        }
        return url
    }
}
