//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

// MARK: Pipeline
public struct Pipeline<Input, Output>: CustomStringConvertible where Input: Codable, Output: Codable {

    public let description: String
    private let someStep: SomeStep<Input, Output>

    fileprivate init(description: String, perform: @escaping (Input) throws -> Output) {
        self.description = description
        self.someStep = SomeStep(name: description, perform: perform)
    }

    /// Assumes that the steps are indeed pipeable, that is, that the input of step
    /// `s_0` is of type `Self.Input`, and its output equals `Input` of `s_1`... and that the
    /// `Output` type of `s_n` equals `Self.Output`
    fileprivate init(
        cacher: Cacher = Cacher(onDisc: .temporary()),
        description: String,
        steps: [UnsafeStep]
    ) {

        let workFlow = CacheableWorkFlow<Input, Output>(cacher: cacher)

        self.init(description: description) {
            return try workFlow.startWorkFlow(
                named: description,
                input: $0,
                steps: steps
            )
        }
    }
}

public extension Pipeline {
    func perform(input: Input) throws -> Output {
        try someStep.perform(input: input)
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
        ) -> Pipeline<StepA.Input, StepB.Output> where
            StepA: Step,
            StepB: Step,
            StepB.Input == StepA.Output
        {
//            Pipeline<StepA.Input, StepB.Output>(
//                description: names(of: [stepA, stepB])
//            ) { (inputStepA: StepA.Input) in
//                return try inputStepA |> stepA |> stepB
//            }

            var anySteps = [AnyStep]()

            let a = AnyStep(stepA)

            anySteps.append(a)

            let b = a.bind(to: stepB)
            anySteps.append(b)

            return Pipeline<StepA.Input, StepB.Output>(
                description: names(of: anySteps),
                steps: anySteps
            )
        }

        static func buildBlock<StepA, StepB, StepC>(
            _ a: StepA,
            _ b: StepB,
            _ c: StepC
        ) -> Pipeline<StepA.Input, StepC.Output> where
            StepA: Step,
            StepB: Step,
            StepC: Step,
            StepC.Input == StepB.Output,
            StepB.Input == StepA.Output
        {
            let anySteps: [AnyStep] = [
                AnyStep(a),
                a ~> b, // b
                b ~> c // c
            ]

            return Pipeline<StepA.Input, StepC.Output>(
                description: names(of: anySteps),
                steps: anySteps
            )
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

infix operator ~>: Pipe

//func |> <Input, S>(input: Input, step: S) throws -> SomeStep<Input, S.Output>
//    where
//    S: Step,
//S.Input == Input
//{
//    SomeStep<S.Input, S.Output>(name: step.name, perform: step.perform(input:))
//}

func |> <LastStep, NextStep>(lastStep: LastStep, nextStep: NextStep) throws -> SomeStep<LastStep.Input, NextStep.Output>
    where
    LastStep: Step,
    NextStep: Step,
    NextStep.Input == LastStep.Output
{
    SomeStep<LastStep.Input, NextStep.Output>(
        name: names(of: [lastStep, nextStep])
    ) { (inputForLastStep: LastStep.Input) throws -> NextStep.Output in
        let inputForNext = try lastStep.perform(input: inputForLastStep)
        return try nextStep.perform(input: inputForNext)
    }
}

func ~> <LastStep, NextStep>(lastStep: LastStep, nextStep: NextStep) -> AnyStep
    where
    LastStep: Step,
    NextStep: Step,
    NextStep.Input == LastStep.Output
{
    AnyStep(lastStep).bind(to: nextStep)
}


func names(of nameOwners: [Named], separator: String = " -> ") -> String {
    nameOwners.map { $0.name }.joined(separator: separator)
}
