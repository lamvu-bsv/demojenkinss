//
//  AsyncOperation.swift
//  BSService
//
//  Created by Hien Pham on 3/26/19.
//

import UIKit

public class AsyncOperation: Operation {
    public enum State: String {
        case isReady, isExecuting, isFinished
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    public var state = State.isReady {
        willSet {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }
    
    public override var isExecuting: Bool {
        return state == .isExecuting
    }
    
    public override var isFinished: Bool {
        return state == .isFinished
    }
    
    public override func start() {
        guard !self.isCancelled else {
            state = .isFinished
            return
        }
        
        state = .isExecuting
        main()
    }
}
