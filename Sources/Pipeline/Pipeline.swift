//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

// MARK: Pipeline
public struct Pipeline<Input, Output>: Step {
    private let anyStep: AnyStep<Input, Output>

    public init(step: AnyStep<Input, Output>) {
        self.anyStep = step
    }
}

// MARK: Step
public extension Pipeline {
    var name: String { anyStep.name }
    func perform(input: Input) throws -> Output {
        try anyStep.perform(input: input)
    }
}

// MARK: Init
public extension Pipeline {
    init(steps: String, _ perform: @escaping (Input) throws -> Output) {
        self.init(step: AnyStep(
            name: steps,
            perform: perform
        ))
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

        static func buildBlock<A, B>(
            _ a: A, _ b: B
        )
            -> Pipeline<A.Input, B.Output>
            where
            A: Step, B: Step,
            A.Output == B.Input
        {
            return Pipeline<A.Input, B.Output>(
                steps: names(of: [a, b])
            ) { inputA in
                return try inputA |> a |> b
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
