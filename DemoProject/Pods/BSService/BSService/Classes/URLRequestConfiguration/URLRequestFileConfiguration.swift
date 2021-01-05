//
//  URLRequestFileConfiguration.swift
//  BSService
//
//  Created by Hien Pham on 3/25/19.
//

import UIKit

public class URLRequestFileConfiguration: NSObject {
    public let file : Data
    public let name : String
    public let key : String
    public let mimeType : String
    
    public init(file: Data, name: String, key: String, mimeType: String) {
        self.file = file
        self.name = name
        self.key = key
        self.mimeType = mimeType
    }
    
    public override var description: String {
        var description : String = ""
        let fileSizeStr: String = String(self.file.count)
        let nameStr: String = self.name
        let keyStr: String = self.key
        let mimeTypeStr: String = self.mimeType
        description += String(format: "File size: %ld, name: %@, key: %@, mimetype: %@", fileSizeStr, nameStr, keyStr, mimeTypeStr)
        return description;
    }
}
