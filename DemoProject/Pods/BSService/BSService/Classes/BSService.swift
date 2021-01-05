//
//  BSService.swift
//  BSService
//
//  Created by Hien Pham on 11/29/17.
//  Copyright © 2017 Bravesoft VN. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD
import PureLayout
import os

public typealias ServiceSuccess = (_ data: Any?) -> Void

public typealias ServiceError = (_ error: Error) -> Void

public typealias ServiceFinish = () -> Void


open class BSService: NSObject {
    // MARK: Redeclaration
    
    /**
     Parser is the object which in charge of parsing raw data received from server into object
    */
    public var parser: BSServiceParser!
    
    /**
     Configuration for generating URLRequest object
    */
    public var configuration: URLRequestConfiguration!
    
    /**
     The container of progress hud, if nil then not show. Default is nil
     */
    public var progressHudContainer: UIView?
    
    /**
     Auto add an activity indicator to specify container and remove when finish service.
     */
    public var activityIndicatorContainer: UIView?
    
    /**
     Auto turn of refresh control, and also set isHidden to false when finish service.
    */
    public var scrollView: UIScrollView?
    
    /**
     The queue on which the service's callback will be called.
     */
    public var completionQueue: DispatchQueue = DispatchQueue.main
    
    /**
     Activity indicator which appear in activityIndicatorContainer.
    */
    public lazy var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    /**
     Handler for success case.
     */
    public var success: ServiceSuccess?
    
    /**
     Handler for error case, which could be network error or error return by server.
     */
    public var error: ServiceError?
    
    /**
     Handler before finishing a service. This will be called after either success and error.
     */
    public var finish: ServiceFinish?
    
    /**
     When ignoreCancelError is true and service encounter a cancel error. Function callEventConnectionError and error block will not be called.
     */
    public var ignoreCancelError: Bool = true
    
    /**
     When this flag is true. Executing the service will log debug infos into your logs.
     */
    public var debugMode: Bool = true
    
    /**
     debugMode for global scope. The affection scope will be local first, then check to global.
     */
    public static var debugMode: Bool = true
    
    fileprivate var isDebugModeEnabled: Bool {
        return self.debugMode == true || BSService.debugMode == true
    }
    
    // MARK: Description
    open override var description: String {
        let description : String = String(format: "%@: %@", self.uniqueId, self.configuration.description)
        return description
    }
    
    fileprivate var uniqueId: String {
        let className: String = String(describing: type(of: self))
        let address: String = String(format: "%p", self)
        let uniqueId: String = String(format: "%@ (%@)", className, address)
        return uniqueId
    }
    
    // MARK: Execute
    private var sessionManager : SessionManager? // Make session manager as property to prevent it from dealloc in the middle of requesting
    /**
     Executing request of the service. You can also override this function to add more behavior. Such as: add an access token for every services.
     */
    open func execute() {
        self.log("%@", self.description)
        self.handleUIWhenStartRequest()
        
        let configuration : URLSessionConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        configuration.timeoutIntervalForRequest = self.configuration.timeout
        configuration.requestCachePolicy = self.configuration.cachePolicy
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        self.sessionManager = SessionManager(configuration: configuration)
        
        if self.configuration is URLRequestPostFileConfiguration {
            let urlString: String = self.configuration.urlStringFilledWithParams()
            let postFileConfiguration : URLRequestPostFileConfiguration = self.configuration as! URLRequestPostFileConfiguration
            self.sessionManager?.upload(multipartFormData: { (multipartFormData : MultipartFormData) in
                if let bodyParams = self.configuration.bodyParams {
                    let keys : Array<String> = Array(bodyParams.keys)
                    for key in keys {
                        if let value = bodyParams[key] {
                            let string : String = URLRequestConfiguration.string(fromObject: value)
                            multipartFormData.append(string.data(using: String.Encoding.utf8)!, withName: key)
                        }
                    }
                }
                
                if let files = postFileConfiguration.files {
                    for file in files {
                        multipartFormData.append(file.file, withName: file.key, fileName: file.name, mimeType: file.mimeType)
                    }
                }
            }, to: urlString, method: postFileConfiguration.method, headers: self.configuration.headerParams, encodingCompletion: { (encodingResult : SessionManager.MultipartFormDataEncodingResult) in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.response(queue: self.completionQueue, completionHandler: { (defaultDataResponse : DefaultDataResponse) in
                        self.connectionComplete(defaultDataResponse: defaultDataResponse)
                    })
                case .failure(let encodingError):
                    if (self.configuration.url != nil) {
                        self.log("Encoding error. Reason: %@", encodingError.localizedDescription)
                    }
                    self.callEventConnectionError(error: encodingError)
                    self.callEventConnectionWillFinish()
                }
            })
        } else {
            let configuration = self.configuration as! URLRequestNormalConfiguration
            let urlString: String = self.configuration.url ?? ""
            let encoding : ParameterEncoding = configuration.method == .get ? URLEncoding.default : configuration.encoding
            self.sessionManager?.request(urlString, method: configuration.method, parameters: configuration.bodyParams, encoding: encoding, headers: configuration.headerParams).response(queue: self.completionQueue, completionHandler: { (defaultDataResponse : DefaultDataResponse) in
                self.connectionComplete(defaultDataResponse: defaultDataResponse)
            })
        }
    }
        
    private func connectionComplete(defaultDataResponse : DefaultDataResponse) {
        if let response: HTTPURLResponse = defaultDataResponse.response {
            self.log("Response service: %@\nStatus code: %d", self.configuration.urlStringFilledWithParams(), response.statusCode)
        }
        if let error = defaultDataResponse.error {
            if (self.configuration.url != nil) {
                self.log("Response service failed: %@.\nReason: %@", self.configuration.urlStringFilledWithParams(), error.localizedDescription)
            }
            var ignore: Bool = false
            if self.ignoreCancelError == true, let nsError: NSError = error as NSError?, nsError.code == NSURLErrorCancelled {
                ignore = true
            }
            if ignore == false {
                self.callEventConnectionError(error: error)
            }
        } else {
            if let data: Data = defaultDataResponse.data {
                self.log("Succeeded! %@ %lu bytes of data", self.uniqueId, data.count)
                self.log("Parser: %@", self.parser)
                
                var didLogReceivedData: Bool = false
                if self.isDebugModeEnabled == true {
                    // Print data as formatted json if possible
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                        let prettyJsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                        let prettyPrintedJson = String(data: prettyJsonData, encoding: String.Encoding.utf8) {
                        self.log("Succeeded! %@ data is: %@", self.uniqueId, prettyPrintedJson)
                        didLogReceivedData = true
                    }
                }
                
                if didLogReceivedData == false {
                    let dataString: String = String(data: data, encoding: .utf8) ?? "Null"
                    self.log("Succeeded! %@ data is : %@", self, dataString)
                }
            }
            
            self.connectionDidFinish(with: defaultDataResponse.response, data: defaultDataResponse.data)
        }
        self.callEventConnectionWillFinish()
    }

    // MARK: Where to customize network callbacks
    /**
     Network finish callback to redirect to suitable callback
     */
    open func connectionDidFinish(with response: URLResponse?, data: Data?) {
    }
    
    /**
     Override this function in order to custom UI configs
     */
    open func handleUIWhenStartRequest() {
        DispatchQueue.main.async {
            if (self.progressHudContainer != nil) {
                // Show progress hud on delegate's view
                if MBProgressHUD.allHUDs(for: self.progressHudContainer!).count <= 0 {
                    MBProgressHUD.showAdded(to: self.progressHudContainer!, animated: true)
                } else {
                    MBProgressHUD(view: self.progressHudContainer!)
                }
            }
            
            if (self.activityIndicatorContainer != nil) {
                let indicatorView : UIActivityIndicatorView = self.activityIndicator
                indicatorView.startAnimating()
                self.activityIndicatorContainer?.addSubview(indicatorView)
                indicatorView.autoCenterInSuperview()
                self.activityIndicator = indicatorView
            }
        }
    }
    
    fileprivate func log(_ format: String, _ arguments: CVarArg...) {
        if self.isDebugModeEnabled == true {
            var message: String = String(format: format, arguments: arguments).replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
            
            // Remove escape characters for easier viewing
            message = message.replacingOccurrences(of: "\\", with: "", options: NSString.CompareOptions.literal, range: nil)
            
            if #available(iOS 10.0, *) {
                os_log("%@", message)
            } else {
                // Fallback on earlier versions
                print(message)
            }
        }
    }
    
    /**
     Override this function in order to custom UI configs
     */
    open func handleUIWhenStopRequest() {
        DispatchQueue.main.async {
            if (self.progressHudContainer != nil) {
                MBProgressHUD.hideAllHUDs(for: self.progressHudContainer!, animated: true)
            }
            
            if (self.activityIndicatorContainer != nil) {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            }
            
            if (self.scrollView != nil) {
                if #available(iOS 10.0, *) {
                    self.scrollView?.refreshControl?.endRefreshing()
                } else {
                    // Fallback on earlier versions
                }
                self.scrollView?.isHidden = false
            }
        }
    }
    
    /**
     Override to custom call update state events, if not don't override.
     */
    open func callEventConnectionSuccess(withData: Any?) {
        self.success?(withData)
    }
    
    /**
     Override to custom call update state events, if not don't override.
     */
    open func callEventConnectionError(error: Error) {
        self.error?(error)
    }
    
    
    // Network finish callback to redirect to suitable callback
    /**
     Network finish callback to redirect to suitable callback.
     */
    open func callEventConnectionWillFinish() {
        self.handleUIWhenStopRequest()
        self.finish?()
    }
    
    /**
     Cancel execution of the service.
     */
    open func cancel() {
        sessionManager?.session.getTasksWithCompletionHandler {
            dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
            
        }
    }
}
