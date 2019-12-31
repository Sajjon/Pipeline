//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-29.
//

import Foundation

// MARK: SomeStep
public struct SomeStep<Input, Output>: Step {

    public let name: String
    public let cacheableResultTypeIfAny: CacheableResult.Type
    private let _perform: (_ input: Input) throws -> Output

    fileprivate init(
        name: String,
        cacheableResultType: CacheableResult.Type,
        perform: @escaping (Input) throws -> Output
    ) {
        self.name = name
        self.cacheableResultTypeIfAny = cacheableResultType
        self._perform = perform
    }
}

// MARK: Init
public extension SomeStep {
    init<S>(_ step: S)
        where
        S: Step,
        S.Input == Input,
        S.Output == Output
    {
        self.init(
            name: step.name,
            cacheableResultType: step.cacheableResultTypeIfAny
        ) { (input: S.Input) in
            try step.perform(input: input)
        }
    }
}

// MARK: Step
public extension SomeStep {
    func perform(input: Input) throws -> Output {
        try _perform(input)
    }
}
