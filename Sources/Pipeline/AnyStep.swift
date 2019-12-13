//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

// MARK: AnyStep
public struct AnyStep<Input, Output>: Step {
    public let name: String
    private let _perform: (_ input: Input) throws -> Output

    public init(name: String, perform: @escaping (Input) throws -> Output) {
        self.name = name
        self._perform = perform
    }
}

// MARK: Init
public extension AnyStep {
    init<SomeStep>(_ step: SomeStep)
        where
        SomeStep: Step,
        SomeStep.Input == Input,
        SomeStep.Output == Output
    {
        self.init(name: step.name) { (input: SomeStep.Input) in
            try step.perform(input: input)
        }
    }
}

// MARK: Step
public extension AnyStep {
    func perform(input: Input) throws -> Output {
        try _perform(input)
    }
}
