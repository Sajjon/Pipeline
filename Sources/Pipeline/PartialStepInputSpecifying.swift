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
    private let _perform: (_ input: Input) throws -> Any

    public init(name: String, perform: @escaping (Input) throws -> Any) {
        self.name = name
        self._perform = perform
    }

    public init(unsafeStep: UnsafeStep) {
        self.init(
            name: unsafeStep.name
        ) {
            try unsafeStep.unsafePerform(anyInput: $0)
        }
    }
}

// MARK: Init
public extension PartialStepInputSpecifying {
    init<S>(_ step: S)
        where
        S: Step,
        S.Input == Input
        //        S.Output == Output
    {
        self.init(name: step.name) { (input: S.Input) in
            try step.perform(input: input)
        }
    }
}

// MARK: PartialUnsafeStepInputSpecifying
public extension PartialStepInputSpecifying {
    func partialUnsafePerform(input: Input) throws -> Any {
        try _perform(input)
    }

    func loadCached(from cacher: Cacher, fileName: String) -> Any? {
        fatalError()
    }

    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws {
        fatalError()
    }
}
