//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-29.
//

import Foundation

// MARK: AnyStep
public struct AnyStep: __built_in_UnsafeStep {

    public let name: String
    private let _unsafePerform: (Any) throws -> Any

     public let cacheableResultTypeIfAny: CacheableResult.Type
    
    private let _unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep: (_ otherNextStepHavingInputSameAsSelfOutput: __built_in_UnsafeStep) -> AnyStep

    public init<Input, Output>(name: String, cacheableResultType: CacheableResult.Type, perform: @escaping (Input) throws -> Output) {
        self.cacheableResultTypeIfAny = cacheableResultType
        self.name = name
        self._unsafePerform = { anyInput in
            guard let input = anyInput as? Input else {
                wrongType(expected: Input.self, butGot: anyInput)
            }
            return try perform(input)
        }
        self._unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep = { (otherNextStepHavingInputSameAsSelfOutput: __built_in_UnsafeStep) in
            let partialStep = PartialStep<Output>(unsafeStep: otherNextStepHavingInputSameAsSelfOutput)
            return AnyStep(partialStep)
        }
    }
}

// MARK: Public
public extension AnyStep {
    func bind(to unsafeNextStep: __built_in_UnsafeStep) -> AnyStep {
        _unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep(unsafeNextStep)
    }
}

// MARK: Init
public extension AnyStep {

    init<PS>(_ partial: PS) where PS: __built_in_InputSpecifyingStep {
        self.init(
            name: partial.name,
            cacheableResultType: partial.cacheableResultTypeIfAny
        ) { (input: PS.Input) in
            try partial.partialUnsafePerform(input: input)
        }
    }
}

// MARK: __built_in_UnsafeStep
public extension AnyStep {
    func unsafePerform(anyInput: Any) throws -> Any {
        try _unsafePerform(anyInput)
    }
}
