//
//  ConvenientServiceParser.swift
//  Tavi
//
//  Created by Hien Pham on 4/18/18.
//  Copyright © 2018 Bravesoft VN. All rights reserved.
//

import UIKit

public typealias RequiredDataRetriever = ((_ responseData: Any?) -> Any?)

open class ConvenientServiceParser: BSServiceParser {
    public var objectParser : ObjectParser?
    public var dataNeedToParse : RequiredDataRetriever?
    
    public init(objectParser : ObjectParser?, dataNeedToParse : RequiredDataRetriever? = nil) {
        self.objectParser = objectParser
        self.dataNeedToParse = dataNeedToParse
    }
    
    open override func parseJson(_ object: Any?) -> Any? {
        var dataNeedToParse : Any?
        if self.dataNeedToParse != nil {
            dataNeedToParse = self.dataNeedToParse!(object)
        } else {
            dataNeedToParse = object
        }
        return self.objectParser?.parseJson(dataNeedToParse)
    }
}
