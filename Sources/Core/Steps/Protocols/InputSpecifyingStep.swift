//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation

public protocol __built_in_InputSpecifyingStep: __built_in_UnsafeStep {
    associatedtype Input
    func partialUnsafePerform(input: Input) throws -> Any
}

public extension __built_in_InputSpecifyingStep {
    func unsafePerform(anyInput: Any) throws -> Any {
        guard let input = anyInput as? Input else {
            throw UnsafeStepError.cannotPerform(
                step: self.name,
                withInput: anyInput,
                ofType: typeName(of: anyInput),
                expectedInputType: typeName(of: Input.self)
            )
        }
        return try partialUnsafePerform(input: input)
    }
}
