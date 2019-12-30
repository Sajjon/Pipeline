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

    private let _unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep: (_ otherNextStepHavingInputSameAsSelfOutput: UnsafeStep) -> AnyStep

//    private let _loadCached: (Cacher, _ fileName: String) -> Any?
//    private let _cache: (_ modelToSave: Any, Cacher, _ fileName: String) throws -> Void
    public let decoding: AnyJSONDecoding
    public let encoding: AnyJSONEncoding

    public init<Input, Output>(name: String, perform: @escaping (Input) throws -> Output) where Output: Codable {
        self.name = name
        self._unsafePerform = { anyInput in
            guard let input = anyInput as? Input else {
                wrongType(expected: Input.self, butGot: anyInput)
            }
            return try perform(input)
        }

        self._unsafeNonTypeCheckedLetOutputOfSelfBeInputForOtherNextStep = { (otherNextStepHavingInputSameAsSelfOutput: UnsafeStep) in
            let partialStep = PartialStepInputSpecifying<Output>(unsafeStep: otherNextStepHavingInputSameAsSelfOutput)
            return AnyStep.init(name: name, perform: { (anInput: Output) in try  partialStep.partialUnsafePerform(input: anInput) })
        }

//        self._loadCached = {  try? $0.load(modelType: Output.self, fileName: $1) }
//        self._cache = {
//            let toCache: Output = castOrKill($0)
//            try $1.save(model: toCache, fileName: $2)
//        }
        self.encoding = AnyJSONEncoding(type: Output.self)
        self.decoding = AnyJSONDecoding(type: Output.self)
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
        self.init(name: step.name) { (input: S.Input) in
            try step.perform(input: input)
        }
    }

//    init<PS>(_ partial: PS) where PS: PartialUnsafeStepInputSpecifying {
//        self.init(name: partial.name) { (input: PS.Input) in
//            try partial.partialUnsafePerform(input: input)
//        }
//    }
}

// MARK: UnsafeStep
public extension AnyStep {
    func unsafePerform(anyInput: Any) throws -> Any {
        try _unsafePerform(anyInput)
    }

//    func loadCached(from cacher: Cacher, fileName: String) -> Any? {
//        _loadCached(cacher, fileName)
//    }
//
//    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws {
//        try _cache(any, cacher, fileName)
//    }
}
