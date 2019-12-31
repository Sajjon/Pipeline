//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-29.
//

import Foundation

// MARK: PartialStepInputSpecifying

/// A *partially* type-erased `step` specifying expected `Input`, but not `Output` type.
public struct PartialStepInputSpecifying<Input>: PartialUnsafeStepInputSpecifying {


    public let name: String
    public let cacheableResultTypeIfAny: CacheableResult.Type
    private let _perform: (_ input: Input) throws -> Any
    
    fileprivate init(
        name: String,
        cacheableResultType: CacheableResult.Type,
        perform: @escaping (Input) throws -> Any
    ) {
        self.name = name
        self.cacheableResultTypeIfAny = cacheableResultType
        self._perform = perform
    }

    public init(unsafeStep: UnsafeStep) {
        self.init(
            name: unsafeStep.name,
            cacheableResultType: unsafeStep.cacheableResultTypeIfAny
        ) {
            try unsafeStep.unsafePerform(anyInput: $0)
        }
    }
}

// MARK: PartialUnsafeStepInputSpecifying
public extension PartialStepInputSpecifying {
    func partialUnsafePerform(input: Input) throws -> Any {
        try _perform(input)
    }
}
