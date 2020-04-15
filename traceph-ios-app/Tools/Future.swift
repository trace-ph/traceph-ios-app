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
    
    private func report(result: Result) {
        callbacks.forEach { $0(result) }
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
