//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

// MARK: Pipeline
public struct Pipeline<Output>: CustomStringConvertible {
    public typealias SomeInput = Any
    public let description: String
    private let _perform: (SomeInput) throws -> Output

    init<Input>(description: String, perform: @escaping (Input) throws -> Output) {
        self.description = description
        self._perform = {
            guard let input = $0 as? Input else {
                fatalError("\n\n⚠️Wrong input type, got value: `\($0)` of type: '\(Mirror.init(reflecting: $0).subjectType)', but expected type: '\(Input.self)'\n\n")
            }
            return try perform(input)
        }
    }
}

public extension Pipeline {
    func perform(input: SomeInput) throws -> Output {
        try _perform(input)
    }
}

public extension Pipeline {
    init(@Builder makePipeline: () -> Self) {
        self = makePipeline()
    }
}

// MARK: Builder
public extension Pipeline {
    @_functionBuilder
    struct Builder {

        static func buildBlock<StepA, StepB>(
            _ stepA: StepA,
            _ stepB: StepB
        ) -> Pipeline<StepB.Output> where
            StepA: Step,
            StepB: Step,
            StepB.Input == StepA.Output
        {
            Pipeline<StepB.Output>(
                description: names(of: [stepA, stepB])
            ) { (inputStepA: StepA.Input) in
                return try inputStepA |> stepA |> stepB
            }
        }

        static func buildBlock<StepA, StepB, StepC>(
            _ stepA: StepA,
            _ stepB: StepB,
            _ stepC: StepC
        ) -> Pipeline<StepC.Output> where
            StepA: Step,
            StepB: Step,
            StepC: Step,
            StepC.Input == StepB.Output,
            StepB.Input == StepA.Output
        {
            Pipeline<StepC.Output>(
                description: names(of: [stepA, stepB, stepC])
            ) { (inputStepA: StepA.Input) in
                return try inputStepA |> stepA |> stepB |> stepC
            }
        }
    }
}
// MARK: Operator
precedencegroup Pipe {
    higherThan: NilCoalescingPrecedence
    associativity: left
    assignment: true
}

infix operator |>: Pipe

private func |> <SomeStep>(input: SomeStep.Input, step: SomeStep)
    throws -> SomeStep.Output
    where
    SomeStep: Step
{
    try step.perform(input: input)
}

private func names(of nameOwners: [Named], separator: String = " -> ") -> String {
    nameOwners.map { $0.name }.joined(separator: separator)
}
