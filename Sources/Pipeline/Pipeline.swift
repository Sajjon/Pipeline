//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation
import Core

// MARK: Pipeline
public struct Pipeline<Input, Output>: CustomStringConvertible {

    public let description: String
    private let _perform: (Input) throws -> Output

    fileprivate init(description: String, perform: @escaping (Input) throws -> Output) {
        self.description = description
        self._perform = perform
    }
}

// MARK: Init
private extension Pipeline {
    /// Assumes that the steps are indeed pipeable, that is, that the input of step
    /// `s_0` is of type `Self.Input`, and its output equals `Input` of `s_1`... and that the
    /// `Output` type of `s_n` equals `Self.Output`
    init(
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
    
    init(
        cacher: Cacher = Cacher(onDisc: .temporary()),
        _ stepLinker: StepLinker
    ) {
        
        let anySteps = stepLinker.steps
        
        self.init(
            cacher: cacher,
            description: names(of: anySteps),
            steps: anySteps
        )
    }
}

public extension Pipeline {
    func perform(input: Input) throws -> Output {
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
            _ a: StepA,
            _ b: StepB
        ) -> Pipeline<StepA.Input, StepB.Output> where
            StepA: Step,
            StepB: Step,
            StepB.Input == StepA.Output
        {
            Pipeline<StepA.Input, StepB.Output>(
                StepLinker {
                    a
                    b
                }
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
            Pipeline<StepA.Input, StepC.Output>(
                StepLinker {
                    a
                    b
                    c
                }
            )
        }
    }
}

func names(of steps: [UnsafeStep], separator: String = " -> ") -> String {
    steps.map { $0.name }.joined(separator: separator)
}
