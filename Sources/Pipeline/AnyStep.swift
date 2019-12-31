//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-29.
//

import Foundation

// MARK: AnyStep
public struct AnyStep: UnsafeStep {

    public let name: String
    private let _unsafePerform: (Any) throws -> Any

     public let cacheableResultTypeIfAny: CacheableResult.Type
    
    private let _unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep: (_ otherNextStepHavingInputSameAsSelfOutput: UnsafeStep) -> AnyStep

    fileprivate init<Input, Output>(name: String, cacheableResultType: CacheableResult.Type, perform: @escaping (Input) throws -> Output) {
        self.cacheableResultTypeIfAny = cacheableResultType
        self.name = name
        self._unsafePerform = { anyInput in
            guard let input = anyInput as? Input else {
                wrongType(expected: Input.self, butGot: anyInput)
            }
            return try perform(input)
        }
        self._unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep = { (otherNextStepHavingInputSameAsSelfOutput: UnsafeStep) in
            let partialStep = PartialStepInputSpecifying<Output>(unsafeStep: otherNextStepHavingInputSameAsSelfOutput)
            return AnyStep(partialStep)
        }
    }
}

// MARK: Public
public extension AnyStep {
    func bind(to unsafeNextStep: UnsafeStep) -> AnyStep {
        _unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep(unsafeNextStep)
    }
}

// MARK: Init
public extension AnyStep {
    init<S>(_ step: S) where S: Step {
        self.init(
            name: step.name,
            cacheableResultType: step.cacheableResultTypeIfAny
        ) { (input: S.Input) in
            try step.perform(input: input)
        }
    }

    init<PS>(_ partial: PS) where PS: PartialUnsafeStepInputSpecifying {
        self.init(
            name: partial.name,
            cacheableResultType: partial.cacheableResultTypeIfAny
        ) { (input: PS.Input) in
            try partial.partialUnsafePerform(input: input)
        }
    }
}

// MARK: UnsafeStep
public extension AnyStep {
    func unsafePerform(anyInput: Any) throws -> Any {
        try _unsafePerform(anyInput)
    }
}
