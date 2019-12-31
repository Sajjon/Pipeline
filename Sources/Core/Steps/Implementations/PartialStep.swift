//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-29.
//

import Foundation

// MARK: PartialStep

/// A *partially* type-erased `step` specifying expected `Input`, but not `Output` type.
public struct PartialStep<Input>: __built_in_InputSpecifyingStep {


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

    public init(unsafeStep: __built_in_UnsafeStep) {
        self.init(
            name: unsafeStep.name,
            cacheableResultType: unsafeStep.cacheableResultTypeIfAny
        ) {
            try unsafeStep.unsafePerform(anyInput: $0)
        }
    }
}

// MARK: __built_in_InputSpecifyingStep
public extension PartialStep {
    func partialUnsafePerform(input: Input) throws -> Any {
        try _perform(input)
    }
}
