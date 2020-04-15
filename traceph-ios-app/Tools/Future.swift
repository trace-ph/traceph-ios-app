//
//  Future.swift
//  traceph-ios-app
//
//  Created by Enzo on 15/04/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

// https://www.swiftbysundell.com/articles/under-the-hood-of-futures-and-promises-in-swift/
class Future<Value> {
    typealias Result = Swift.Result<Value, Error>
    
    fileprivate var result: Result? {
        // Observe whenever a result is assigned, and report it:
        didSet { result.map(report) }
    }
    private var callbacks = [(Result) -> Void]()
    private var successCallbacks = [(Value) -> Void]()
    private var failureCallbacks = [(Error) -> Void]()
    
    var value: Value? {
        guard case .success(let value) = result else {
            return nil
        }
        return value
    }
    
    func observe(using callback: @escaping (Result) -> Void) {
        // If a result has already been set, call the callback directly:
        if let result = result {
            return callback(result)
        }
        
        callbacks.append(callback)
    }
    
    func onSucceed(callback: @escaping (Value) -> Void) {
        if let result = result {
            if case .success(let value) = result {
                return callback(value)
            }
        } else {
            successCallbacks.append(callback)
        }
    }
    
    func onFail(callback: @escaping (Error) -> Void) {
        if let result = result {
            if case .failure(let error) = result {
                return callback(error)
            }
        } else {
            failureCallbacks.append(callback)
        }
    }
    
    private func report(result: Result) {
        callbacks.forEach { $0(result) }
        switch result {
        case .success(let value):
            successCallbacks.forEach { $0(value) }
        case .failure(let error):
            failureCallbacks.forEach { $0(error) }
        }
        failureCallbacks = []
        successCallbacks = []
        callbacks = []
    }
}

class Promise<Value>: Future<Value> {
    init(value: Value? = nil) {
        super.init()
        
        // If the value was already known at the time the promise
        // was constructed, we can report it directly:
        result = value.map(Result.success)
    }
    
    func resolve(with value: Value) {
        result = .success(value)
    }
    
    func reject(with error: Error) {
        result = .failure(error)
    }
}
