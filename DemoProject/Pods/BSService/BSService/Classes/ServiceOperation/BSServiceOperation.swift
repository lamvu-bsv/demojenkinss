//
//  BSServiceOperation.swift
//  Alamofire
//
//  Created by Hien Pham on 3/26/19.
//

import UIKit

public class BSServiceOperation: AsyncOperation {
    public var isSuccess: Bool = false
    public var data: Any? // For success case
    public var error: Error? // For error case
    
    public let service: BSService
    public init(service: BSService) {
        self.service = service
        super.init()
        self.insertCallbacksToService()
    }
    
    fileprivate func insertCallbacksToService() {
        let serviceSucess: ServiceSuccess? = self.service.success
        self.service.success = {(data: Any?) in
            self.isSuccess = true
            self.data = self
            serviceSucess?(data)
        }
        let serviceError: ServiceError? = self.service.error
        self.service.error = {(error: Error) in
            self.isSuccess = false
            self.error = error
            serviceError?(error)
        }
        let serviceFinish: ServiceFinish? = self.service.finish
        self.service.finish = {
            self.state = .isFinished
            serviceFinish?()
        }
    }
    
    public override func main() {
        self.service.execute()
    }
    
    public override func cancel() {
        super.cancel()
        self.service.cancel()
    }
}
