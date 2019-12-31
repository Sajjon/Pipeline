//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation
import Core

// MARK: Step
public protocol Step: PartialUnsafeStepInputSpecifying {
    associatedtype Output
    func perform(input: Input) throws -> Output
}

public extension Step where Output: CacheableResult {
    var cacheableResultTypeIfAny: CacheableResult.Type {
        return Output.self
    }
}

public extension Step {
    func partialUnsafePerform(input: Input) throws -> Any {
        return try perform(input: input)
    }
}

